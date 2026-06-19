# Launches a real EC2 instance from the golden AMI we just built, proving
# it's not just "registered" but actually bootable and usable
resource "aws_instance" "golden_ami_demo" {
  ami                    = "ami-00f611aef719d0540" # today's build, ap-south-1
  instance_type          = "t3.medium"             # Windows needs more than t3.micro
  subnet_id              = module.network_primary.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_sg_rdp.id]

  tags = {
    Name = "${var.environment}-golden-ami-demo"
  }
}

resource "aws_security_group" "ec2_sg_rdp" {
  name   = "${var.environment}-golden-ami-demo-sg"
  vpc_id = module.network_primary.vpc_id

  ingress {
    description = "RDP - demo only, lock to your IP in real use"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP - confirm IIS is actually running"
    from_port   = 80
    to_port     = 80
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
