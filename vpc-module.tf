# Create VPC 
resource "aws_vpc" "myvpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${terraform.workspace}-${var.vpc_cidr}"
    Environment = "${terraform.workspace}"
  }
}

# Create IGW and attach it to our VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = { 
    Name = "${terraform.workspace}-My IG"
    Environment = "${terraform.workspace}"
  }

  depends_on = [aws_vpc.myvpc]
}

# ---------------------------- PUBLIC --------------------------
# Create Public Subnets 
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnet_map
  vpc_id = aws_vpc.myvpc.id
  cidr_block = each.value.cidr
  availability_zone = each.value.zone
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${terraform.workspace}-${each.value.cidr} - ${each.value.zone}"
    Environment = "${terraform.workspace}"
  }

  depends_on = [aws_vpc.myvpc]
}

# Create route table and attach IG to it
resource "aws_route_table" "internet_route" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = var.open_cidr
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${terraform.workspace}-Terraform-Public-RouteTable"
    Environment = "${terraform.workspace}"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Associate ALL public subnets to route table 
resource "aws_route_table_association" "public_route_table_association1" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.internet_route.id

  depends_on = [aws_route_table.internet_route, aws_subnet.public_subnets ]
}

# -------------------- Security Groups --------------
# Create SG for allowing TCP/80 & TCP/22
resource "aws_security_group" "public_sg" {
  name        = "${terraform.workspace}-public-sg"
  description = "Allow TCP/80 & TCP/22"
  vpc_id      = aws_vpc.myvpc.id
  ingress {
    description = "Allow SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.open_cidr]
  }
  ingress {
    description = "allow traffic from TCP/80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.open_cidr]
  }
  ingress {
    description = "allow traffic from TCP/8080"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.open_cidr]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${terraform.workspace}-Public-Sec-Group"
    Environment = "${terraform.workspace}"
  }

  depends_on = [aws_vpc.myvpc , aws_route_table.internet_route, aws_subnet.public_subnets ]
}