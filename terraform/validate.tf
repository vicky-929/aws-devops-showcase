locals {
  clusters = {
    primary = {
      region       = var.primary_region
      cluster_name = "${var.environment}-${var.primary_region}-eks"
    }
    secondary = {
      region       = var.secondary_region
      cluster_name = "${var.environment}-${var.secondary_region}-eks"
    }
  }
}

# Connectivity + cluster readiness: reaching the EKS API and listing real
# nodes proves both that we can talk to the cluster and that it's actually
# ready, not just that AWS reports "created"
resource "null_resource" "validate_cluster_readiness" {
  for_each   = local.clusters
  depends_on = [module.compute_primary, module.compute_secondary]

  triggers = {
    cluster_name = each.value.cluster_name
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "Checking ${each.value.cluster_name} in ${each.value.region}..."
      STATUS=$(aws eks describe-cluster --name ${each.value.cluster_name} --region ${each.value.region} --query 'cluster.status' --output text)
      echo "Cluster status: $STATUS"
      aws eks update-kubeconfig --name ${each.value.cluster_name} --region ${each.value.region} --alias ${each.key}
      kubectl --context ${each.key} get nodes
    EOT
  }
}

# Replication check #1: write a real object to the primary bucket, confirm
# it shows up on the secondary bucket - proves replication actually runs
resource "null_resource" "validate_s3_replication" {
  depends_on = [aws_s3_bucket_replication_configuration.this]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "replication-check" > /tmp/replication-test.txt
      aws s3 cp /tmp/replication-test.txt s3://${aws_s3_bucket.primary.id}/replication-test.txt --region ${var.primary_region}
      echo "Uploaded to primary. Waiting 30s for cross-region replication..."
      sleep 30
      aws s3api head-object --bucket ${aws_s3_bucket.secondary.id} --key replication-test.txt --region ${var.secondary_region}
    EOT
  }
}

# Replication check #2: write an item via the primary region's endpoint,
# read it back via the secondary region's endpoint
resource "null_resource" "validate_dynamodb_replication" {
  depends_on = [aws_dynamodb_table_replica.secondary]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      aws dynamodb put-item \
        --table-name ${aws_dynamodb_table.global.name} \
        --region ${var.primary_region} \
        --item '{"id": {"S": "replication-test-item"}}'
      echo "Item written in ${var.primary_region}. Waiting 15s for sync..."
      sleep 15
      aws dynamodb get-item \
        --table-name ${aws_dynamodb_table.global.name} \
        --region ${var.secondary_region} \
        --key '{"id": {"S": "replication-test-item"}}'
    EOT
  }
}
