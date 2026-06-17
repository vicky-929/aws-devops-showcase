variable "vpc_cidr"            {
    type = string 
    }
variable "az_count"            {
    type = number
    default = 2
    }

variable "environment"         { 
    type = string 
    }
variable "region_name"         { 
    type = string 
    }
variable "create_eks_subnets"  { 
    type = bool
    default = true 
    }
variable "ingress_ports"       { 
    type = list(number)
    default = [80, 443] 
    }
