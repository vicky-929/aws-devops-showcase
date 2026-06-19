resource "aws_db_subnet_group" "x" {
  name       = "${var.environment}-accountx-db-subnet-group"
  subnet_ids = [aws_subnet.x_private_db.id, aws_subnet.x_private_db_b.id]
  # RDS requires 2+ subnets in 2+ AZs minimum, even though only one is "the DB subnet"
}

resource "aws_db_instance" "mysql" {
  identifier             = "${var.environment}-accountx-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "appdb"
  username               = "admin"
  password               = "ChangeMe123!" # demo only - use Secrets Manager in real use, you already know this service
  db_subnet_group_name   = aws_db_subnet_group.x.name
  availability_zone      = "ap-south-1a"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}
