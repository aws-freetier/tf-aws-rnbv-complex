###
# purpose of the github module
# using github provider
# - create webhook on github for given repo and given atlantis domain name
# - webhook scope: "issue_comment", "pull_request", "pull_request_review", "pull_request_review_comment"
###
provider "github" {
  token        = var.github_token
  individual   = false
  organization = var.organization_name
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = var.region
  }
}

resource "github_repository_webhook" "this" {
  count = var.create_github_repository_webhook ? length(var.atlantis_allowed_repo_names) : 0

  repository = var.atlantis_allowed_repo_names[count.index]

  configuration {
    url          = var.webhook_url
    content_type = "application/json"
    insecure_ssl = false
    secret       = var.webhook_secret
  }

  events = [
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
  ]
}
