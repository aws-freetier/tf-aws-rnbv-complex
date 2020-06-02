###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "eu-west-2/mgmt/atlantis-cluster/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key    = var.vpc_remote_state_key
    region = var.region
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key    = var.alb_remote_state_key
    region = var.region
  }
}

data "terraform_remote_state" "svc" {
  backend = "s3"

  config = {
    bucket = var.remote_state_bucket
    key    = var.svc_remote_state_key
    region = var.region
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

module "secret" {
  source = "../../modules/security/secret"

  region      = var.region
  secret_name = var.secretmanager_key
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data.sh")

  vars = {
    url            = "http://${data.terraform_remote_state.alb.outputs.alb_dns_name}/events"
    webhook_secret = data.terraform_remote_state.svc.outputs.webhook_secret
    username       = data.terraform_remote_state.svc.outputs.github_organization_name
    token          = module.secret.secret_json["token"]
    repo_whitelist = "github.com/${data.terraform_remote_state.svc.outputs.github_organization_name}/${var.github_repo}"
  }
}

// retrieve permissions for ec2 instances
data "aws_iam_instance_profile" "ora2postgres_atlantis" {
  name = "ora2postgres_atlantis"
}

resource "aws_key_pair" "deployer" {
  key_name   = "atlantis"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfObcpiUJAYEGXnJ0FOcyTM6pFvs1tTFKhpuNWfE/sssk7oGnM2Kw3zdktg7Ykq/LV+tOlxl9VtBa9FN6BQmxMi/bW96c47rGYL8VMPCQ3e7Qa7mKjbx1coBcQg9gxaLpWA73oD41O2cHYit084SlS8BTiRl1f4Lc9nPKM9RKyOzC6zajyIBFLDjOcRgVkEVoEW8QYroAFLJwKuKqu9oI9HAuov0c1o99J4ASqKmC/rm/76d1Fhs83dXNhLldmme7aN7M7XKX+8NM7hPeJtG3LGuxOtVMmMOhPkqG7FbtFWhKuXvD5CdU/S7QkxGo3lkZE+cwrUqKWQmEB6t4lKkxB"
}

// setup autoscaling group
module "asg" {
  source = "../../modules/cluster/asg"

  subnet_ids   = data.terraform_remote_state.vpc.outputs.default_subnet_ids
  cluster_name = "atlantis-cluster"
  min_size     = 2
  max_size     = 3

  image_id             = data.aws_ami.ami2.id
  instance_type        = local.instance_type
  security_groups      = [data.terraform_remote_state.vpc.outputs.vpc_instance_sg_id]
  key_name             = aws_key_pair.deployer.key_name
  user_data            = data.template_file.user_data.rendered
  iam_instance_profile = data.aws_iam_instance_profile.ora2postgres_atlantis.name

  target_group_atlantis_arn = data.terraform_remote_state.alb.outputs.target_group_atlantis_arn
}
