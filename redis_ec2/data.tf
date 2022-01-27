data "aws_ami" "linux" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-focal-*-amd64-server-*",
    ]
  }
}
data "aws_iam_instance_profile" "gateway" {
  name = "gateway"
}

data "aws_security_group" "ecs_sg"{
    name = format("gateway-ecs-%s", local.environment) 
}

data "aws_vpc" "gateway_vpc" {
  filter {
    name = "tag:Name"
    values = [format("gateway-%s", local.environment)]
  }
}

data "aws_subnet_ids" "gateway_subnets_ids" {
  vpc_id = data.aws_vpc.gateway_vpc.id
}