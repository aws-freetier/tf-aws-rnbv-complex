###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "eu-west-2/live/prod/webserver-cluster/terraform.tfstate"
    region = "eu-west-2"

    dynamodb_table = "tf-locks-eu-west-2-rnbv"
    encrypt        = true
  }
}

// for demo purpose
/*
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

data "aws_subnet" "default" {
  availability_zone = "eu-west-2a"
}

resource "aws_instance" "secondserver" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "updated by atlantis"
  }
  subnet_id = data.aws_subnet.default.id
}
*/
