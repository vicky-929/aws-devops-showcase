resource "aws_kms_key" "golden_ami" {
  description             = "Encrypts the Windows golden AMI"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "golden_ami" {
  name          = "alias/${var.environment}-golden-ami-key"
  target_key_id = aws_kms_key.golden_ami.key_id
}

resource "aws_kms_key" "golden_ami_secondary" {
  provider                = aws.secondary
  description             = "Encrypts the Windows golden AMI in the secondary region"
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "golden_ami_secondary" {
  provider      = aws.secondary
  name          = "alias/${var.environment}-golden-ami-key-secondary"
  target_key_id = aws_kms_key.golden_ami_secondary.key_id
}
