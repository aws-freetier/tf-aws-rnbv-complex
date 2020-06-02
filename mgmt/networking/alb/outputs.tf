###
output "alb_dns_name" {
  description = "The alb's domain name"
  value       = aws_lb.this.dns_name
}

output "target_group_atlantis_arn" {
  description = "The alb's domain name"
  value       = aws_lb_target_group.atlantis.arn
}
