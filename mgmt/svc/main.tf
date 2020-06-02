###
# purpose of the github module
# using github provider
# - create webhook on github for given repo and given atlantis domain name
# - webhook scope: "issue_comment", "pull_request", "pull_request_review", "pull_request_review_comment"
###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

provider "github" {
  version      = "~> 2.8"
  token        = module.secret.secret_json["token"]
  individual   = false
  organization = var.github_organization_name
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "eu-west-2/mgmt/svc/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"

  config = {
    bucket = var.alb_remote_state_bucket
    key    = var.alb_remote_state_key
    region = var.region
  }
}

module "secret" {
  source = "../../modules/security/secret"

  region      = var.region
  secret_name = var.secretmanager_key
}

resource "github_repository_webhook" "this" {
  count = var.create_github_repository_webhook ? length(var.github_repos) : 0

  repository = var.github_repos[count.index]

  configuration {
    url          = "http://${data.terraform_remote_state.alb.outputs.alb_dns_name}/events"
    content_type = "application/json"
    insecure_ssl = false
    secret       = module.secret.webhook_secret
  }

  events = [
    "issue_comment",
    "pull_request",
    "pull_request_review",
    "pull_request_review_comment",
  ]
}


