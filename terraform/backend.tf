terraform {
  backend "s3" {
    bucket  = "dev-terraform-state-700800570325"
    key     = "terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}
