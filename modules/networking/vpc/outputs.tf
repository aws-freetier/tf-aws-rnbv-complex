###
output "public_subnets_vpc1_id" {
  value = element(aws_subnet.public_vpc1.*.id, 0)
}

output "public_subnets_vpc2_id" {
  value = element(aws_subnet.public_vpc2.*.id, 0)
}

output "private_subnets_app_vpc1_id" {
  value = element(aws_subnet.private_app_vpc1.*.id, 0)
}

output "private_subnets_app_vpc2_id" {
  value = element(aws_subnet.private_app_vpc2.*.id, 0)
}

output "private_subnets_db_vpc1_id" {
  value = element(aws_subnet.private_db_vpc1.*.id, 0)
}

output "subnet_sfx" {
  value = local.subnet_sfx
}

output "vpc1_id" {
  value = aws_vpc.vpc1.id
}

output "vpc2_id" {
  value = aws_vpc.vpc2.id
}
