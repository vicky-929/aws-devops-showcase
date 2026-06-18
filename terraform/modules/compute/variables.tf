variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "region_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "create_eks" {
  type    = bool
  default = true
}

variable "eks_node_instance_type" {
  type    = string
  default = "t3.medium"
}
