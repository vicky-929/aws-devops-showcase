module "network_primary" {
  source             = "./modules/network"
  providers          = { aws = aws } # default provider = primary region
  vpc_cidr           = var.regions["primary"].cidr_block
  az_count           = var.regions["primary"].az_count
  environment        = var.environment
  ingress_ports      = var.ingress_ports
  region_name        = var.primary_region
  create_eks_subnets = var.regions["primary"].create_eks
}

module "network_secondary" {
  source             = "./modules/network"
  providers          = { aws = aws.secondary } # aliased provider = secondary region
  vpc_cidr           = var.regions["secondary"].cidr_block
  az_count           = var.regions["secondary"].az_count
  environment        = var.environment
  ingress_ports      = var.ingress_ports
  region_name        = var.secondary_region
  create_eks_subnets = var.regions["secondary"].create_eks
}
