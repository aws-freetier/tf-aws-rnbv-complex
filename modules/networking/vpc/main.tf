###
provider "aws" {
  version                 = "~> 2.0"
  region                  = "eu-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "ora2postgres"
}
