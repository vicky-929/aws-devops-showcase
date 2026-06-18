resource "aws_dynamodb_table" "global" {
  name             = "${var.environment}-global-table"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }

  # We manage the replica via the separate resource below, not an inline
  # replica{} block. Without this, AWS reports back a replica that isn't
  # in this resource's own config, and Terraform shows a false diff forever.
  lifecycle {
    ignore_changes = [replica]
  }
}

resource "aws_dynamodb_table_replica" "secondary" {
  provider         = aws.secondary
  global_table_arn = aws_dynamodb_table.global.arn
}
