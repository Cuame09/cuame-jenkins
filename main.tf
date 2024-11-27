# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}




resource "aws_vpc" "cuame" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "cuame"
    Env  = "Production"
  }
}

# 2 Public subnets

resource "aws_subnet" "cuame-pub-sub1" {
  vpc_id            = aws_vpc.cuame.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "TERRA"
  }
}

resource "aws_subnet" "cuame-pub-sub2" {
  vpc_id                  = aws_vpc.cuame.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "cuame"
  }
}

# 2 Private subnets

resource "aws_subnet" "cuame-priv-sub1" {
  vpc_id     = aws_vpc.cuame.id
  cidr_block = "10.0.3.0/24"


  tags = {
    Name = "cuame"
  }
}

resource "aws_subnet" "cuame-priv-sub2" {
  vpc_id     = aws_vpc.cuame.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "cuame"
  }
}

# CREATING INTERNET GATEWAY

resource "aws_internet_gateway" "cuame-igw" {
  vpc_id = aws_vpc.cuame.id

  tags = {
    Name = "cuame"
  }
}

# CREATING EIPs 

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.cuame-igw]
}

#CREATING NAT GATEWAY

resource "aws_nat_gateway" "cuame-ngw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.cuame-pub-sub1.id

  tags = {
    Name = "cuame-ngw"
  }

}

# TWO ROUTE TABLES FOR THE NETWORK

resource "aws_route_table" "cuame-pub-rt" {
  vpc_id = aws_vpc.cuame.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cuame-igw.id
  }

  tags = {
    Name = "cuame-pub-rt"
  }
}

resource "aws_route_table" "cuame-priv-rt" {
  vpc_id = aws_vpc.cuame.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.cuame-ngw.id
  }

  tags = {
    Name = "cuame-priv-rt"
  }
}

# ROUTE TABLE ASSOCIATION

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.cuame-pub-sub1.id
  route_table_id = aws_route_table.cuame-pub-rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.cuame-pub-sub2.id
  route_table_id = aws_route_table.cuame-pub-rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.cuame-priv-sub1.id
  route_table_id = aws_route_table.cuame-priv-rt.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.cuame-priv-sub2.id
  route_table_id = aws_route_table.cuame-priv-rt.id
}

resource "aws_security_group" "cuame-vpc" {
  name        = "Project-vpc-sg"
  description = "Project-vpc-sg"
  vpc_id      = aws_vpc.cuame.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "cuame-sg"
  }
}

# creating ec2

resource "aws_instance" "cuame-ec2" {
  ami               = "ami-0a2202cf4c36161a1"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-1b"
  subnet_id         = aws_subnet.cuame-pub-sub2.id
  security_groups   = [aws_security_group.cuame-vpc.id]

  tags = {
    Name = "cuame-ec2"
  }
}

