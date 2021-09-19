resource "aws_vpc" "eks-vpc-demo" {
    instance_tenancy = "default"
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = tomap({
        "Name"                                      = "terraform-eks",
        "kubernetes.io/cluster/${var.cluster-name}" = "shared",
    })
} 

resource "aws_subnet" "eks-public-1a-subnet" {
    vpc_id = aws_vpc.eks-vpc-demo.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-east-1a"
    map_public_ip_on_launch = true

    tags = tomap({
        "Name"                                      = "terraform-eks",
        "kubernetes.io/cluster/${var.cluster-name}" = "shared",
        "kubernetes.io/role/elb"                    = 1
    })
}

resource "aws_subnet" "eks-public-1b-subnet" {
    vpc_id = aws_vpc.eks-vpc-demo.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-east-1b"
    map_public_ip_on_launch = true

    tags = tomap({
        "Name"                                      = "terraform-eks",
        "kubernetes.io/cluster/${var.cluster-name}" = "shared",
        "kubernetes.io/role/elb"                    = 1
    })
}

resource "aws_subnet" "eks-private-1a-subnet" {
    vpc_id = aws_vpc.eks-vpc-demo.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-east-1a"
    map_public_ip_on_launch = false

    tags = tomap({
        "kubernetes.io/role/internal-elb" = 1,
    })
}

resource "aws_subnet" "eks-private-1b-subnet" {
    vpc_id = aws_vpc.eks-vpc-demo.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "ap-east-1b"
    map_public_ip_on_launch = false

    tags = tomap({
        "kubernetes.io/role/internal-elb" = 1,
    })
}

resource "aws_internet_gateway" "eks-gw" {
  vpc_id = aws_vpc.eks-vpc-demo.id

  tags = {
    Name = "eks-gw"
  }
}

# Nat gateway
resource "aws_eip" "nat-eip" {}
resource "aws_eip" "nat-eip-2" {}
resource "aws_nat_gateway" "private-subnet-nat" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.eks-public-1a-subnet.id

  tags = {
    Name = "NAT 1"
  }

  depends_on = [aws_eip.nat-eip]
}

resource "aws_nat_gateway" "private-subnet-nat-2" {
  allocation_id = aws_eip.nat-eip-2.id
  subnet_id     = aws_subnet.eks-public-1b-subnet.id

  tags = {
    Name = "NAT 2"
  }

  depends_on = [aws_eip.nat-eip-2]
}

# Route table
resource "aws_route_table" "eks-public" {
    vpc_id = aws_vpc.eks-vpc-demo.id
}

resource "aws_route" "r-eks-public" {
  route_table_id = aws_route_table.eks-public.id 
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.eks-gw.id
}

resource "aws_route_table" "eks-private" {
    vpc_id = aws_vpc.eks-vpc-demo.id
}

resource "aws_route" "r-eks-private" {
  route_table_id = aws_route_table.eks-private.id 
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private-subnet-nat.id
}

resource "aws_route_table" "eks-private-2" {
    vpc_id = aws_vpc.eks-vpc-demo.id
}

resource "aws_route" "r-eks-private-2" {
  route_table_id = aws_route_table.eks-private-2.id 
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private-subnet-nat-2.id
}

# Associate route table

resource "aws_route_table_association" "public-a" {
  subnet_id      = aws_subnet.eks-public-1a-subnet.id
  route_table_id = aws_route_table.eks-public.id
}

resource "aws_route_table_association" "public-b" {
  subnet_id      = aws_subnet.eks-public-1b-subnet.id
  route_table_id = aws_route_table.eks-public.id
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = aws_subnet.eks-private-1a-subnet.id
  route_table_id = aws_route_table.eks-private.id
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = aws_subnet.eks-private-1b-subnet.id
  route_table_id = aws_route_table.eks-private-2.id
}