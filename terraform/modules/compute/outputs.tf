
output "ec2_instance_id" { value = aws_instance.demo.id }
output "eks_cluster_arn" {
  value = var.create_eks ? aws_eks_cluster.this[0].arn : null
}
output "eks_cluster_endpoint" {
  value = var.create_eks ? aws_eks_cluster.this[0].endpoint : null
}
