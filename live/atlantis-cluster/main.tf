###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "live/atlantis-cluster/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "aws_ami" "ami2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-*-gp2"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    url            = local.atlantis_url
    webhook_secret = local.webhook_secret
    username       = local.github_username
    token          = local.github_token
    repo_whitelist = local.github_repo_url
  }
}

// retrieve permissions for ec2 instances
data "aws_iam_instance_profile" "ora2postgres_atlantis" {
  name = "ora2postgres_atlantis"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_key_pair" "deployer" {
  key_name   = "atlantis"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfObcpiUJAYEGXnJ0FOcyTM6pFvs1tTFKhpuNWfE/sssk7oGnM2Kw3zdktg7Ykq/LV+tOlxl9VtBa9FN6BQmxMi/bW96c47rGYL8VMPCQ3e7Qa7mKjbx1coBcQg9gxaLpWA73oD41O2cHYit084SlS8BTiRl1f4Lc9nPKM9RKyOzC6zajyIBFLDjOcRgVkEVoEW8QYroAFLJwKuKqu9oI9HAuov0c1o99J4ASqKmC/rm/76d1Fhs83dXNhLldmme7aN7M7XKX+8NM7hPeJtG3LGuxOtVMmMOhPkqG7FbtFWhKuXvD5CdU/S7QkxGo3lkZE+cwrUqKWQmEB6t4lKkxB"
}

resource "aws_security_group" "instance_sg" {
  name        = "${local.cluster_name}-instance-sg"
  description = "Set of rules for atlantis instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Atlantis service"
    from_port   = 4141
    to_port     = 4141
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
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

// setup autoscaling group
module "asg" {
  source = "../../modules/cluster/asg"

  region                 = var.region
  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
  db_remote_state_key    = "live/atlantis-cluster/terraform.tfstate"

  subnet_ids   = data.aws_subnet_ids.default.ids
  cluster_name = local.cluster_name
  min_size     = 1
  max_size     = 3

  image_id             = data.aws_ami.ami2.id
  instance_type        = local.instance_type
  security_groups      = [aws_security_group.instance_sg.id]
  key_name             = aws_key_pair.deployer.key_name
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = data.aws_iam_instance_profile.ora2postgres_atlantis.name

  target_group_atlantis_arn = module.alb.target_group_atlantis_arn
}

resource "aws_security_group" "alb_sg" {
  name        = "${local.cluster_name}-alb-sg"
  description = "Set of rules for atlantis cluster"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "Allow traffic to atlantis"
    from_port        = 80
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

// setup loadbalancer
module "alb" {
  source = "../../modules/networking/alb"

  region                 = var.region
  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
  db_remote_state_key    = "live/atlantis-cluster/terraform.tfstate"

  vpc_id          = data.aws_vpc.default.id
  subnet_ids      = data.aws_subnet_ids.default.ids
  cluster_name    = local.cluster_name
  security_groups = [aws_security_group.alb_sg.id]
}

// retrieve sensitive data from secrets manager
module "security" {
  source = "../../modules/security/secret"

  region                 = var.region
  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
  db_remote_state_key    = "live/atlantis-cluster/terraform.tfstate"

  name = local.secretmanager_key
}

// create webhook on github repo
module "github" {
  source = "../../modules/common/github"

  region                 = var.region
  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
  db_remote_state_key    = "live/atlantis-cluster/terraform.tfstate"

  webhook_url                 = local.atlantis_url
  webhook_secret              = local.webhook_secret
  github_token                = local.github_token
  organization_name           = local.github_username
  atlantis_allowed_repo_names = [local.github_repo]
}
