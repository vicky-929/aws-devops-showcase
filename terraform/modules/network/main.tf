data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.environment}-${var.region_name}-vpc" }
}

resource "aws_subnet" "public" {
  for_each = toset(slice(data.aws_availability_zones.available.names, 0, var.az_count))

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, index(data.aws_availability_zones.available.names, each.value))
  availability_zone       = each.value
  map_public_ip_on_launch = true

  tags = merge(
    { Name = "${var.environment}-${var.region_name}-public-${each.value}" },
    var.create_eks_subnets ? { "kubernetes.io/role/elb" = "1" } : {}
  )
}

resource "aws_subnet" "private" {
  for_each = toset(slice(data.aws_availability_zones.available.names, 0, var.az_count))

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, index(data.aws_availability_zones.available.names, each.value) + 10)
  availability_zone = each.value

  tags = merge(
    { Name = "${var.environment}-${var.region_name}-private-${each.value}" },
    var.create_eks_subnets ? { "kubernetes.io/role/internal-elb" = "1" } : {}
  )
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.environment}-${var.region_name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.environment}-${var.region_name}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "shared" {
  name   = "${var.environment}-${var.region_name}-shared-sg"
  vpc_id = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      description = "Allow port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.environment}-${var.region_name}-shared-sg" }
}
