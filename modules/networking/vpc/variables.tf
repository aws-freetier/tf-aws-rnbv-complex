locals {
  public_subnets_vpc1      = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets_vpc2      = ["10.1.10.0/28"]
  private_subnets_app_vpc1 = ["10.0.11.0/24", "10.0.12.0/24"]
  private_subnets_app_vpc2 = ["10.1.10.16/28", "10.1.10.32/28"]
  private_subnets_db_vpc1  = ["10.0.21.0/24", "10.0.22.0/24"]
  subnet_sfx               = ["a", "b"]
}

variable "region" {
  description = "Region in which to create dev environment."
  type        = string
}

variable "cidr_block_vpc1" {
  type = string
}

variable "cidr_block_vpc2" {
  type = string
}

/*
variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}
*/
