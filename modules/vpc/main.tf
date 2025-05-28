# Create VPC
resource "aws_vpc" "micro_service_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

# Create public subnets
resource "aws_subnet" "micro_service_project_public_subnet" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.micro_service_vpc.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = {
    Name = "micro-service-proj-public-subnet-${count.index + 1}"
  }
}

# Create private subnets
resource "aws_subnet" "micro_service_project_private_subnet" {
  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.micro_service_vpc.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
    Name = "micro-service-proj-private-subnet-${count.index + 1}"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "micro_service_project_internet_gateway" {
  vpc_id = aws_vpc.micro_service_vpc.id

  tags = {
    Name = "micro-service-proj-internet-gateway"
  }
}

# Create Elastic IPs for NAT gateways (2)
resource "aws_eip" "nat_eip" {
  count  = 2
  domain = "vpc"
}

# Create 2 NAT gateways in public subnets
resource "aws_nat_gateway" "nat_gateway" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.micro_service_project_public_subnet[count.index].id

  tags = {
    Name = "micro-service-nat-${count.index + 1}"
  }

  depends_on = [aws_internet_gateway.micro_service_project_internet_gateway]
}

# Create public route table
resource "aws_route_table" "micro_service_project_public_route_table" {
  vpc_id = aws_vpc.micro_service_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.micro_service_project_internet_gateway.id
  }

  tags = {
    Name = "micro-service-proj-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "micro_service_project_public_rt_subnet_association" {
  count          = length(aws_subnet.micro_service_project_public_subnet)
  subnet_id      = aws_subnet.micro_service_project_public_subnet[count.index].id
  route_table_id = aws_route_table.micro_service_project_public_route_table.id
}

# Create private route tables WITH NAT for specific subnets only
resource "aws_route_table" "private_route_table_with_nat" {
  for_each = {
    for idx, cidr in var.cidr_private_subnet : idx => cidr
    if cidr == "12.0.3.0/24" || cidr == "12.0.4.0/24"
  }

  vpc_id = aws_vpc.micro_service_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[tonumber(each.key)].id
  }

  tags = {
    Name = "private-rt-with-nat-${each.key}"
  }
}

resource "aws_route_table_association" "private_subnet_association_with_nat" {
  for_each = aws_route_table.private_route_table_with_nat

  subnet_id      = aws_subnet.micro_service_project_private_subnet[tonumber(each.key)].id
  route_table_id = each.value.id
}

# Create private route tables WITHOUT NAT for remaining subnets
resource "aws_route_table" "private_route_table_no_nat" {
  for_each = {
    for idx, cidr in var.cidr_private_subnet : idx => cidr
    if cidr != "12.0.3.0/24" && cidr != "12.0.4.0/24"
  }

  vpc_id = aws_vpc.micro_service_vpc.id

  tags = {
    Name = "private-rt-no-nat-${each.key}"
  }
}

resource "aws_route_table_association" "private_subnet_association_no_nat" {
  for_each = aws_route_table.private_route_table_no_nat

  subnet_id      = aws_subnet.micro_service_project_private_subnet[tonumber(each.key)].id
  route_table_id = each.value.id
}
