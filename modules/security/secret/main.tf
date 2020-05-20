###
# purpose of the security module
# - generate random secret string for webhook
# - retrieve secretString values from secrets manager (see outputs.tf)
###
data "aws_secretsmanager_secret" "this" {
  name = var.name
}

data "aws_secretsmanager_secret_version" "this" {
  secret_id = data.aws_secretsmanager_secret.this.id
}

resource "random_id" "webhook" {
  byte_length = "64"
}
