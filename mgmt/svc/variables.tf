###
variable "region" {
  description = "Region in which to create the cluster and run Atlantis."
  type        = string
  default     = "eu-west-2"
}

variable "secretmanager_key" {
  description = "The name of secret's key in secrets manager"
  type        = string
  default     = "dev/atlantis/github"
}

variable "github_organization_name" {
  description = "The name of organization"
  type        = string
  default     = "aws-freetier"
}

variable "github_repos" {
  description = "The name of github repo"
  type        = list(string)
  default     = ["tf-aws-rnbv-complex"]
}

variable "create_github_repository_webhook" {
  description = "Whether to create Github repository webhook for Atlantis"
  type        = bool
  default     = true
}

variable "alb_remote_state_bucket" {
  description = "The name of the S3 bucket for the alb's remote state"
  type        = string
  default     = "tf-state-eu-west-2-rnbv"
}

variable "alb_remote_state_key" {
  description = "The path for the alb's remote state in S3"
  type        = string
  default     = "eu-west-2/mgmt/networking/alb/terraform.tfstate"
}
