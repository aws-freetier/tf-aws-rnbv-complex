###
output "webhook_secret" {
  description = "The generated webhook's secret string"
  value       = random_id.webhook.hex
}

output "github_token" {
  description = "The github token retrieved from secretmanager"
  value       = jsondecode(data.aws_secretsmanager_secret_version.this.secret_string)["token"]
}
