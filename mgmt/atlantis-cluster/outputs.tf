output "alb_dns_name" {
  value       = data.terraform_remote_state.alb.outputs.alb_dns_name
  description = "The domain name of the load balancer"
}
