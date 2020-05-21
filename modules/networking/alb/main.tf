###
# purpose of the alb module
# - provide public domain name for github webhook
# - balance requests to atlantis (forward http requests from port 443 on alb to port 4141 on atlantis running on ec2)
###
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
    region = var.region
  }
}

resource "aws_lb" "this" {
  name = "${var.cluster_name}-alb"

  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.atlantis.id]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
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

resource "aws_security_group" "atlantis" {
  name        = "${var.cluster_name}-alb"
  description = "Set of rules for atlantis cluster"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "Allow traffic to atlantis"
    from_port        = 443
    to_port          = 4141
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    description      = "Allow all connection from"
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb_target_group" "atlantis" {
  name = "${var.cluster_name}-atlantis"

  port     = 4141
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

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
  listener_arn = aws_lb_listener.https.arn
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
