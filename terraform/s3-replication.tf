resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Source bucket - primary region (default provider)
resource "aws_s3_bucket" "primary" {
  bucket = "${var.environment}-primary-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled" # replication requires versioning on BOTH buckets
  }
}

# Destination bucket - secondary region (aliased provider)
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket   = "${var.environment}-secondary-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Role S3 assumes on your behalf to copy objects across regions
resource "aws_iam_role" "replication" {
  name = "${var.environment}-s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "${var.environment}-s3-replication-policy"
  role = aws_iam_role.replication.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = [aws_s3_bucket.primary.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl"]
        Resource = ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete"]
        Resource = ["${aws_s3_bucket.secondary.arn}/*"]
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "this" {
  depends_on = [aws_s3_bucket_versioning.primary, aws_s3_bucket_versioning.secondary]
  bucket     = aws_s3_bucket.primary.id
  role       = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }
  }
}
