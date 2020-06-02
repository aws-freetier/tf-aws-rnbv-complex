###
variable "region" {
  description = "Region in which to create the cluster and run Atlantis."
  type        = string
  default     = "eu-west-2"
}

variable "vpc_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
  default     = "tf-state-eu-west-2-rnbv"
}

variable "vpc_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
  default     = "eu-west-2/mgmt/networking/vpc/terraform.tfstate"
}

