###
# purpose of the asg module
# - setup autoscaling group for atlantis to listen github webhook
# - apply infrastructure changes using terraform
# - open inbound ports: 22(ssh), 4141(atlantis)
###
provider "aws" {
  version                 = "~> 2.0"
  region                  = "eu-west-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "eu-west-2"
  }
}

resource "aws_launch_configuration" "this" {
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.dmz.id]
  key_name               = var.key_name
  user_data              = var.user_data
  iam_instance_profile   = var.iam_instance_profile

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  launch_configuration = aws_launch_configuration.this.id
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  target_group_arns = [var.target_group_atlantis_arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "tf-atlantis"
  }
}

resource "aws_security_group" "dmz" {
  name = "${var.cluster_name}-dmz"
}

resource "aws_security_group_rule" "allow_ssh" {
  type              = "ingress"
  security_group_id = aws_security_group.dmz.id

  from_port   = 22
  to_port     = 22
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_atlantis" {
  type              = "ingress"
  security_group_id = aws_security_group.dmz.id

  from_port   = 4141
  to_port     = 4141
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_out" {
  type              = "egress"
  security_group_id = aws_security_group.dmz.id

  from_port        = 0
  to_port          = 0
  protocol         = -1
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
}
