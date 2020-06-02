###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "eu-west-2/mgmt/networking/alb/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.vpc_remote_state_bucket
    key    = var.vpc_remote_state_key
    region = var.region
  }
}

resource "aws_lb" "this" {
  name = "atlantis-alb"

  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.vpc.outputs.default_subnet_ids
  security_groups    = [data.terraform_remote_state.vpc.outputs.vpc_alb_sg_id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_target_group" "atlantis" {
  name = "atlantis-alb-tg"

  port     = 4141
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.default_vpc_id

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 60
    timeout             = 59
    healthy_threshold   = 5
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener_rule" "atlantis_events" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/events"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.atlantis.arn
  }
}

