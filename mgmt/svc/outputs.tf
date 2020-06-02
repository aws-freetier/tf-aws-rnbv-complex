###
output "webhook_secret" {
  description = "The webhook secret string"
  value       = module.secret.webhook_secret
  sensitive   = true
}

output "github_organization_name" {
  description = "The name of organization"
  value       = var.github_organization_name
}

output "github_repos" {
  description = "The name of github repo"
  value       = var.github_repos
}
