###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "eu-west-2/mgmt/networking/vpc/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "instance_sg" {
  name        = "vpc-instance-sg"
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

  tags = {
    Env       = "global"
    Module    = "mgmt"
    Submodule = "vpc"
    Name      = "instance-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "vpc-alb-sg"
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

  tags = {
    Env       = "global"
    Module    = "mgmt"
    Submodule = "vpc"
    Name      = "alb-sg"
  }
}
