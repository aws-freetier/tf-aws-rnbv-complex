locals {
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets_app = ["10.0.11.0/24", "10.0.12.0/24"]
  private_subnets_db  = ["10.0.21.0/24", "10.0.22.0/24"]
  subnet_sfx          = ["a", "b"]
}

/*
variable "region" {
  description = "Region in which to create dev environment."
  type        = string
}*/
