###
output "default_vpc_id" {
  description = "The id of default vpc"
  value       = data.aws_vpc.default.id
}

output "default_subnet_ids" {
  description = "The ids of default subnets"
  value       = data.aws_subnet_ids.default.ids
}

output "vpc_instance_sg_id" {
  description = "The id's instance security group"
  value       = aws_security_group.instance_sg.id
}

output "vpc_alb_sg_id" {
  description = "The id's alb security group"
  value       = aws_security_group.alb_sg.id
}
