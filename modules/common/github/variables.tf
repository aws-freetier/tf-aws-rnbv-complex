variable "create_github_repository_webhook" {
  description = "Whether to create Github repository webhook for Atlantis"
  type        = bool
  default     = true
}

variable "github_token" {
  description = "Github token to use when creating webhook"
  type        = string
  default     = ""
}

variable "atlantis_allowed_repo_names" {
  description = "List of names of repositories which belong to the organization specified in `github_organization`"
  type        = list(string)
}

variable "webhook_url" {
  description = "Webhook URL"
  type        = string
  default     = ""
}

variable "webhook_secret" {
  description = "Webhook secret"
  type        = string
  default     = ""
}

variable "organization_name" {
  description = "The organization name"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region in which to create the cluster and run Atlantis."
  type        = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database's remote state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database's remote state in S3"
  type        = string
}
