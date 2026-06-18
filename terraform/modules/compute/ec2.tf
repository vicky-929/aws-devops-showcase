data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name   = "${var.environment}-${var.region_name}-ec2-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH - lock this to your own IP in real use"
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

resource "aws_instance" "demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id               = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  tags = { Name = "${var.environment}-${var.region_name}-demo-ec2" }
}
