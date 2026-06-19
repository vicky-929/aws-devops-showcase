# --- VpcX: simulates "AccountX" - hosts RDS ---
resource "aws_vpc" "account_x" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.environment}-accountx-vpc" }
}

resource "aws_subnet" "x_private_db" {
  vpc_id            = aws_vpc.account_x.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "${var.primary_region}a"
  tags              = { Name = "${var.environment}-accountx-private-db" }
}

# A second, unrelated subnet in VpcX - this is what proves "isolation from
# other subnets" later, since it will NOT get a route to VpcY
resource "aws_subnet" "x_private_other" {
  vpc_id            = aws_vpc.account_x.id
  cidr_block        = "10.2.2.0/24"
  availability_zone = "${var.primary_region}b"
  tags              = { Name = "${var.environment}-accountx-private-other" }
}

# --- VpcY: simulates "AccountY" - hosts the EC2 app ---
resource "aws_vpc" "account_y" {
  cidr_block           = "10.3.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${var.environment}-accounty-vpc" }
}

resource "aws_subnet" "y_public_app" {
  vpc_id                  = aws_vpc.account_y.id
  cidr_block              = "10.3.1.0/24"
  availability_zone       = "${var.primary_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.environment}-accounty-public-app" }
}

resource "aws_internet_gateway" "y" {
  vpc_id = aws_vpc.account_y.id
}

resource "aws_route_table" "y_public" {
  vpc_id = aws_vpc.account_y.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.y.id
  }
  route {
    cidr_block                = aws_vpc.account_x.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.x_to_y.id
  }
}

resource "aws_route_table_association" "y_public" {
  subnet_id      = aws_subnet.y_public_app.id
  route_table_id = aws_route_table.y_public.id
}

# --- Peering connection ---
resource "aws_vpc_peering_connection" "x_to_y" {
  vpc_id      = aws_vpc.account_x.id
  peer_vpc_id = aws_vpc.account_y.id
  auto_accept = true # same-account simulation; real cross-account needs an explicit accepter resource on the peer's side
  tags        = { Name = "${var.environment}-accountx-accounty-peering" }
}

# Route table for ONLY the DB subnet - this gets the peering route
resource "aws_route_table" "x_db" {
  vpc_id = aws_vpc.account_x.id
  route {
    cidr_block                = aws_vpc.account_y.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.x_to_y.id
  }
  tags = { Name = "${var.environment}-accountx-db-rt" }
}

resource "aws_route_table_association" "x_db" {
  subnet_id      = aws_subnet.x_private_db.id
  route_table_id = aws_route_table.x_db.id
}

# Route table for the OTHER subnet - deliberately has NO peering route,
# proving isolation
resource "aws_route_table" "x_other" {
  vpc_id = aws_vpc.account_x.id
  tags   = { Name = "${var.environment}-accountx-other-rt" }
}

resource "aws_route_table_association" "x_other" {
  subnet_id      = aws_subnet.x_private_other.id
  route_table_id = aws_route_table.x_other.id
}


# --- Security Groups ---
# RDS SG: ONLY port 3306, ONLY from VpcY's CIDR - nothing else allowed in
resource "aws_security_group" "rds_sg" {
  name   = "${var.environment}-accountx-rds-sg"
  vpc_id = aws_vpc.account_x.id

  ingress {
    description = "MySQL from AccountY app subnet only"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.account_y.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name   = "${var.environment}-accounty-app-sg"
  vpc_id = aws_vpc.account_y.id

  ingress {
    description = "SSH for demo access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Second DB-capable subnet, different AZ, ALSO gets the peering route -
# satisfies RDS's 2-AZ requirement without compromising isolation
resource "aws_subnet" "x_private_db_b" {
  vpc_id            = aws_vpc.account_x.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "${var.primary_region}b"
  tags              = { Name = "${var.environment}-accountx-private-db-b" }
}

resource "aws_route_table_association" "x_db_b" {
  subnet_id      = aws_subnet.x_private_db_b.id
  route_table_id = aws_route_table.x_db.id
}
