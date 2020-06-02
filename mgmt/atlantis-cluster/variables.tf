locals {
  instance_type = "t2.micro"
  /*
  cluster_name      = "atlantis"
  secretmanager_key = "dev/atlantis/github"
  atlantis_url      = "http://${module.alb.alb_dns_name}/events"
  webhook_secret    = module.security.webhook_secret
  github_username   = "aws-freetier"
  github_token      = module.security.github_token
  github_repo       = "tf-aws-rnbv-complex"
  github_repo_url   = "github.com/${local.github_username}/${local.github_repo}"
*/
}

variable "region" {
  description = "Region in which to create the cluster and run Atlantis."
  type        = string
  default     = "eu-west-2"
}

variable "remote_state_bucket" {
  description = "The name of the S3 bucket for the vpc's remote state"
  type        = string
  default     = "tf-state-eu-west-2-rnbv"
}

variable "vpc_remote_state_key" {
  description = "The path for the vpc's remote state in S3"
  type        = string
  default     = "eu-west-2/mgmt/networking/vpc/terraform.tfstate"
}

variable "alb_remote_state_key" {
  description = "The path for the alb's remote state in S3"
  type        = string
  default     = "eu-west-2/mgmt/networking/alb/terraform.tfstate"
}

variable "svc_remote_state_key" {
  description = "The path for the svc's remote state in S3"
  type        = string
  default     = "eu-west-2/mgmt/svc/terraform.tfstate"
}

variable "secretmanager_key" {
  description = "The name of secret's key in secrets manager"
  type        = string
  default     = "dev/atlantis/github"
}

variable "github_repo" {
  description = "The name of github repo"
  type        = string
  default     = "tf-aws-rnbv-complex"
}
