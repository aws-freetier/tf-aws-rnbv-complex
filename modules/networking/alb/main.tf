###
# purpose of the alb module
# - provide public domain name for github webhook
# - balance requests to atlantis (forward http requests from port 80 on alb to port 4141 on atlantis running on ec2)
###
data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = var.region
  }
}

resource "aws_lb" "this" {
  name = "${var.cluster_name}-alb"

  load_balancer_type = "application"
  subnets            = var.subnet_ids
  security_groups    = var.security_groups
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
  name = "${var.cluster_name}-alb-tg"

  port     = 4141
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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

resource "aws_lb_listener_rule" "atlantis" {
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
