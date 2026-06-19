# Demo EC2 in VpcY's app subnet - used as the "client" to prove connectivity
resource "aws_instance" "y_app_demo" {
  ami                    = data.aws_ami.y_amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.y_public_app.id
  iam_instance_profile   = aws_iam_instance_profile.y_app_ssm.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  tags                   = { Name = "${var.environment}-accounty-app-demo" }
}

data "aws_ami" "y_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Connectivity proof: from VpcY, confirm port 3306 on the RDS endpoint is
# reachable. Uses SSM Run Command instead of SSH - no key pair needed.
resource "null_resource" "validate_db_connectivity" {
  depends_on = [aws_instance.y_app_demo, aws_db_instance.mysql]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Waiting for SSM agent to register..."
      sleep 60
      aws ssm send-command \
        --instance-ids ${aws_instance.y_app_demo.id} \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["timeout 5 bash -c \"echo > /dev/tcp/${aws_db_instance.mysql.address}/3306\" && echo CONNECTED || echo FAILED"]' \
        --region ${var.primary_region} \
        --output text \
        --query "Command.CommandId" > /tmp/cmd_id.txt
      sleep 10
      aws ssm get-command-invocation \
        --command-id $(cat /tmp/cmd_id.txt) \
        --instance-id ${aws_instance.y_app_demo.id} \
        --region ${var.primary_region} \
        --query 'StandardOutputContent' \
        --output text
    EOT
  }
}
