output "primary_vpc_id" { value = module.network_primary.vpc_id }
output "secondary_vpc_id" { value = module.network_secondary.vpc_id }

output "primary_eks_endpoint" { value = module.compute_primary.eks_cluster_endpoint }
output "secondary_eks_endpoint" { value = module.compute_secondary.eks_cluster_endpoint }
