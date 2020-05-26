###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

terraform {
  required_version = "~> v0.12"

  backend "s3" {
    bucket = "tf-state-eu-west-2-rnbv"
    key    = "live/dev/webserver-cluster/terraform.tfstate"
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

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ami2.id
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.key_name
  security_groups             = [aws_security_group.sg_bastion.id]
  subnet_id                   = module.vpn.public_subnets_vpc1_id

  tags = {
    Name = "bastion"
  }
}

resource "aws_instance" "app_a" {
  ami                         = data.aws_ami.ami2.id
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.key_name
  security_groups             = [aws_security_group.sg_app.id]
  subnet_id                   = module.vpn.private_subnets_app_vpc1_id

  tags = {
    Name = "app-a"
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "atlantis"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfObcpiUJAYEGXnJ0FOcyTM6pFvs1tTFKhpuNWfE/sssk7oGnM2Kw3zdktg7Ykq/LV+tOlxl9VtBa9FN6BQmxMi/bW96c47rGYL8VMPCQ3e7Qa7mKjbx1coBcQg9gxaLpWA73oD41O2cHYit084SlS8BTiRl1f4Lc9nPKM9RKyOzC6zajyIBFLDjOcRgVkEVoEW8QYroAFLJwKuKqu9oI9HAuov0c1o99J4ASqKmC/rm/76d1Fhs83dXNhLldmme7aN7M7XKX+8NM7hPeJtG3LGuxOtVMmMOhPkqG7FbtFWhKuXvD5CdU/S7QkxGo3lkZE+cwrUqKWQmEB6t4lKkxB"
}

resource "aws_security_group" "sg_bastion" {
  name   = "sg_bastion"
  vpc_id = module.vpn.vpc1_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
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

resource "aws_security_group" "sg_app" {
  name   = "sg_app"
  vpc_id = module.vpn.vpc1_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    security_groups = [aws_security_group.sg_bastion.id]
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

resource "aws_instance" "app_a_vpc_2" {
  ami                         = data.aws_ami.ami2.id
  associate_public_ip_address = false
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.key_name
  security_groups             = [aws_security_group.sg_app_vpc_2.id]
  subnet_id                   = module.vpn.private_subnets_app_vpc2_id

  tags = {
    Name = "app-a-vpc-2"
  }
}

resource "aws_security_group" "sg_app_vpc_2" {
  name   = "sg_app_vpc_2"
  vpc_id = module.vpn.vpc2_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "TCP"
    security_groups = [aws_security_group.sg_bastion.id]
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

module "vpn" {
  source = "../../../modules/networking/vpc"

//  db_remote_state_bucket = "tf-state-eu-west-2-rnbv"
//  db_remote_state_key    = "live/dev/webserver-cluster/terraform.tfstate"
  region                 = var.region

  cidr_block_vpc1 = "10.0.0.0/16"
  cidr_block_vpc2 = "10.1.10.0/24"
}

// for demo purpose
/*data "aws_ami" "ubuntu" {
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
}*/
