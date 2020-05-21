###
variable "region" {
  description = "Region in which to create the cluster and run Atlantis."
  type        = string
}

variable "vpc_id" {
  description = "The VPC id"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type        = string
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the launch configuration"
  type        = list(string)
  default     = []
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}
