data "aws_region" "current" {}

locals {
 az1 = "${data.aws_region.current.name}a"
 az2 = "${data.aws_region.current.name}b"
 az3 = "${data.aws_region.current.name}c"

}
resource "aws_vpc" "gateway_vpc" {
  cidr_block            = "${var.vpc_cidr_block}"
  instance_tenancy      = "default"
  enable_dns_hostnames  = true
  tags = {
    Name = "${var.vpc_name}-${var.environment}"
  }
}

resource "aws_internet_gateway" "vpc_internet_gw" {
  vpc_id = aws_vpc.gateway_vpc.id
  tags = {
    Name = "vpc-internet-gw-${var.environment}"
  }
}

resource "aws_route_table" "public_sn_rt_1" {
  vpc_id = "${aws_vpc.gateway_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_internet_gw.id}"
  }
  tags = {
    Name = "public-sn-rt-1-${var.environment}"
  }
}

resource "aws_route_table_association" "public_sn_rt_asso_1" {
  subnet_id      = "${aws_subnet.gateway_public_sn_01.id}"
  route_table_id = "${aws_route_table.public_sn_rt_1.id}"
}

resource "aws_route_table" "public_sn_rt_2" {
  vpc_id = "${aws_vpc.gateway_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_internet_gw.id}"
  }
  tags = {
    Name = "public-sn-rt-2-${var.environment}"
  }
}

resource "aws_route_table_association" "public_sn_rt_asso_2" {
  subnet_id      = "${aws_subnet.gateway_public_sn_02.id}"
  route_table_id = "${aws_route_table.public_sn_rt_2.id}"
}

resource "aws_route_table" "public_sn_rt_3" {
  vpc_id = "${aws_vpc.gateway_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_internet_gw.id}"
  }
  tags = {
    Name = "public-sn-rt-3-${var.environment}"
  }
}

resource "aws_route_table_association" "public_sn_rt_asso_3" {
  subnet_id      = "${aws_subnet.gateway_public_sn_03.id}"
  route_table_id = "${aws_route_table.public_sn_rt_3.id}"
}

resource "aws_subnet" "gateway_public_sn_01" {
  vpc_id            = "${aws_vpc.gateway_vpc.id}"
  cidr_block        = "${var.public_subnet_CIDR_1}"
  availability_zone = local.az1
  tags = {
    Name = "${var.public_subnet_name_1}-${var.environment}"
  }
}

resource "aws_subnet" "gateway_public_sn_02" {
  vpc_id            = "${aws_vpc.gateway_vpc.id}"
  cidr_block        = "${var.public_subnet_CIDR_2}"
  availability_zone = local.az2
  tags = {
    Name = "${var.public_subnet_name_2}-${var.environment}"
  }
}

resource "aws_subnet" "gateway_public_sn_03" {
  vpc_id            = "${aws_vpc.gateway_vpc.id}"
  cidr_block        = "${var.public_subnet_CIDR_3}"
  availability_zone = local.az3
  tags = {
    Name = "${var.public_subnet_name_3}-${var.environment}"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_sg_name}"
  vpc_id      = "${aws_vpc.gateway_vpc.id}"
  description = "Allow HTTPS inbound traffic"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow only HTTPS inbound traffic for alb"
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic anywhere"
  }

  tags = {
    Name = "${var.alb_sg_name}-${var.environment}"
  }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.ecs_sg_name}-${var.environment}"
  vpc_id = "${aws_vpc.gateway_vpc.id}"

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb_sg.id}"]
    description     = "Allow inbound traffic from ALB on port 3000"
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic anywhere"
  }


  tags = {
    Name = "${var.ecs_sg_name}-${var.environment}"
  }
}

resource "aws_security_group" "redis_sg" {
  name   = "${var.redis_sg_name}-${var.environment}"
  vpc_id = "${aws_vpc.gateway_vpc.id}"

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ecs_sg.id}"]
    description     = "Allow inbound traffic from ecs on port 6379"
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic anywhere"
  }
  tags = {
    Name = "${var.redis_sg_name}-${var.environment}"
  }
}


