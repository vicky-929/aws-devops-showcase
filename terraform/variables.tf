# variables.tf
variable "primary_region" { default = "ap-south-1" }
variable "secondary_region" { default = "us-east-1" }
variable "environment" { default = "dev" }

# One map drives both regions — this is what lets us "loop" per region/env
variable "regions" {
  type = map(object({
    cidr_block = string
    az_count   = number
    create_eks = bool
  }))
  default = {
    primary = {
      cidr_block = "10.0.0.0/16"
      az_count   = 2
      create_eks = true
    }
    secondary = {
      cidr_block = "10.1.0.0/16"
      az_count   = 2
      create_eks = true
    }
  }
}

variable "ingress_ports" {
  type    = list(number)
  default = [80, 443]
}

