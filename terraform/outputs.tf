
output "primary_bucket_name" { value = aws_s3_bucket.primary.id }
output "secondary_bucket_name" { value = aws_s3_bucket.secondary.id }

output "dynamodb_table_name" { value = aws_dynamodb_table.global.name }
output "dynamodb_table_arn" { value = aws_dynamodb_table.global.arn }

# Aggregates every ARN/endpoint into one structured collection per region,
# instead of one hand-written output per resource per region
locals {
  region_outputs = {
    primary = {
      region          = var.primary_region
      vpc_id          = module.network_primary.vpc_id
      eks_cluster_arn = module.compute_primary.eks_cluster_arn
      eks_endpoint    = module.compute_primary.eks_cluster_endpoint
      s3_bucket_arn   = aws_s3_bucket.primary.arn
    }
    secondary = {
      region          = var.secondary_region
      vpc_id          = module.network_secondary.vpc_id
      eks_cluster_arn = module.compute_secondary.eks_cluster_arn
      eks_endpoint    = module.compute_secondary.eks_cluster_endpoint
      s3_bucket_arn   = aws_s3_bucket.secondary.arn
    }
  }
}

output "infrastructure_summary" {
  description = "Every key ARN/endpoint, grouped per region"
  value       = local.region_outputs
}

# LOOP: flattens every ARN across both regions into one list, generated
# rather than typed out one by one
output "all_arns" {
  description = "Flat list of every ARN created across all regions"
  value = flatten([
    for key, r in local.region_outputs : [r.eks_cluster_arn, r.s3_bucket_arn]
  ])
}

output "dynamodb_global_table_arn" {
  value = aws_dynamodb_table.global.arn
}
