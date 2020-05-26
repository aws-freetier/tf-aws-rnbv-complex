###
provider "aws" {
  version = "~> 2.0"
  region  = var.region
}

/*data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = var.region
  }
}*/

data "aws_availability_zones" "all" {
  all_availability_zones = true
}

### vpc1
resource "aws_vpc" "vpc1" {
  cidr_block           = var.cidr_block_vpc1
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_1"
  }
}

resource "aws_subnet" "public_vpc1" {
  count = length(local.public_subnets_vpc1) > 0 ? length(local.public_subnets_vpc1) : 0

  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = local.public_subnets_vpc1[count.index]
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "sn-public-${local.subnet_sfx[count.index]}"
  }
}

resource "aws_subnet" "private_app_vpc1" {
  count = length(local.private_subnets_app_vpc1) > 0 ? length(local.private_subnets_app_vpc1) : 0

  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = local.private_subnets_app_vpc1[count.index]
  availability_zone = data.aws_availability_zones.all.names[count.index]

  tags = {
    Name = "sn-app-${local.subnet_sfx[count.index]}"
  }
}

resource "aws_subnet" "private_db_vpc1" {
  count = length(local.private_subnets_db_vpc1) > 0 ? length(local.private_subnets_db_vpc1) : 0

  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = local.private_subnets_db_vpc1[count.index]
  availability_zone = data.aws_availability_zones.all.names[count.index]

  tags = {
    Name = "sn-db-${local.subnet_sfx[count.index]}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "igw-vpcdemo"
  }
}

### route from public to world
resource "aws_route_table" "public_vpc1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "rt-public"
  }
}

resource "aws_route" "world" {
  route_table_id         = aws_route_table.public_vpc1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(local.public_subnets_vpc1) > 0 ? length(local.public_subnets_vpc1) : 0

  subnet_id      = element(aws_subnet.public_vpc1.*.id, count.index)
  route_table_id = aws_route_table.public_vpc1.id
}

### route from private-a to world via nat
resource "aws_eip" "nat_a" {
  vpc = true
}

resource "aws_nat_gateway" "sn_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = element(aws_subnet.public_vpc1.*.id, 0)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.vpc1.id

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
  subnet_id      = element(aws_subnet.private_app_vpc1.*.id, 0)
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_a_db" {
  subnet_id      = element(aws_subnet.private_db_vpc1.*.id, 0)
  route_table_id = aws_route_table.private_a.id
}

### route from private-b to world via nat
resource "aws_eip" "nat_b" {
  vpc = true
}

resource "aws_nat_gateway" "sn_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = element(aws_subnet.public_vpc1.*.id, 1)

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.vpc1.id

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
  subnet_id      = element(aws_subnet.private_app_vpc1.*.id, 1)
  route_table_id = aws_route_table.private_b.id
}

resource "aws_route_table_association" "private_b_db" {
  subnet_id      = element(aws_subnet.private_db_vpc1.*.id, 1)
  route_table_id = aws_route_table.private_b.id
}

### vpc2
resource "aws_vpc" "vpc2" {
  cidr_block           = var.cidr_block_vpc2
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_2"
  }
}

resource "aws_subnet" "public_vpc2" {
  count = length(local.public_subnets_vpc2) > 0 ? length(local.public_subnets_vpc2) : 0

  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = local.public_subnets_vpc2[count.index]
  availability_zone       = data.aws_availability_zones.all.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "sn-public-${local.subnet_sfx[count.index]}-vpc-2"
  }
}

resource "aws_subnet" "private_app_vpc2" {
  count = length(local.private_subnets_app_vpc2) > 0 ? length(local.private_subnets_app_vpc2) : 0

  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = local.private_subnets_app_vpc2[count.index]
  availability_zone = data.aws_availability_zones.all.names[count.index]

  tags = {
    Name = "sn-app-${local.subnet_sfx[count.index]}-vpc-2"
  }
}

### peering between vpc1-vpc2
resource "aws_vpc_peering_connection" "vpc1_vpc2" {
  peer_vpc_id = aws_vpc.vpc2.id
  vpc_id      = aws_vpc.vpc1.id
  auto_accept = true

  tags = {
    Name = "vpc_1-vpc_2"
  }
}

resource "aws_route" "from_public_vpc1_to_vpc2" {
  route_table_id            = aws_route_table.public_vpc1.id
  destination_cidr_block    = aws_vpc.vpc2.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
}

resource "aws_route_table_association" "public_vpc1_vpc2" {
  subnet_id      = element(aws_subnet.public_vpc1.*.id, 0)
  route_table_id = aws_route_table.public_vpc1.id
}

data "aws_route_table" "vpc2_default" {
  vpc_id = aws_vpc.vpc2.id
}

resource "aws_route" "from_vpc2_to_vpc1" {
  route_table_id            = data.aws_route_table.vpc2_default.id
  destination_cidr_block    = aws_vpc.vpc1.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_vpc2.id
}

resource "aws_route_table_association" "vpc2_public_vpc1" {
  subnet_id      = element(aws_subnet.private_app_vpc2.*.id, 0)
  route_table_id = data.aws_route_table.vpc2_default.id
}
