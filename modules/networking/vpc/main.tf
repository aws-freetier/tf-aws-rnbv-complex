###
provider "aws" {
  version = "~> 2.0"
  //  region                  = "eu-west-2"
}

resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "vpcdemo"
  }
}

data "aws_availability_zones" "all" {
  all_availability_zones = true
}

resource "aws_subnet" "public" {
  count = length(local.public_subnets) > 0 ? length(local.public_subnets) : 0

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "sn-public-${local.subnet_sfx[count.index]}"
  }
}

resource "aws_subnet" "app" {
  count = length(local.private_subnets_app) > 0 ? length(local.private_subnets_app) : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets_app[count.index]
  availability_zone = data.aws_availability_zones.all.names[count.index]

  tags = {
    Name = "sn-app-${local.subnet_sfx[count.index]}"
  }
}

resource "aws_subnet" "db" {
  count = length(local.private_subnets_db) > 0 ? length(local.private_subnets_db) : 0

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnets_db[count.index]
  availability_zone = data.aws_availability_zones.all.names[count.index]

  tags = {
    Name = "sn-db-${local.subnet_sfx[count.index]}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "igw-vpcdemo"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-public"
  }
}

resource "aws_route" "world" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(local.public_subnets) > 0 ? length(local.public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-private-a"
  }
}

resource "aws_route" "private_a" {
  route_table_id         = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.sn_a.id
}

resource "aws_route_table_association" "private_a_app" {
  subnet_id      = element(aws_subnet.app.*.id, 0)
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_a_db" {
  subnet_id      = element(aws_subnet.db.*.id, 0)
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "rt-private-b"
  }
}

resource "aws_route" "private_b" {
  route_table_id         = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.sn_b.id
}

resource "aws_route_table_association" "private_b_app" {
  subnet_id      = element(aws_subnet.app.*.id, 1)
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table_association" "private_b_db" {
  subnet_id      = element(aws_subnet.db.*.id, 1)
  route_table_id = aws_route_table.private_b.id
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
  subnet_id                   = element(aws_subnet.public.*.id, 0)

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
  subnet_id                   = element(aws_subnet.app.*.id, 0)

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
  vpc_id = aws_vpc.this.id

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
  vpc_id = aws_vpc.this.id

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

resource "aws_eip" "nat-a" {
  vpc = true
}

resource "aws_nat_gateway" "sn_a" {
  allocation_id = aws_eip.nat-a.id
  subnet_id     = element(aws_subnet.public.*.id, 0)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "nat-b" {
  vpc = true
}

resource "aws_nat_gateway" "sn_b" {
  allocation_id = aws_eip.nat-b.id
  subnet_id     = element(aws_subnet.public.*.id, 1)

  depends_on = [aws_internet_gateway.this]
}
