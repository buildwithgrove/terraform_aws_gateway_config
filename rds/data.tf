data "aws_vpc" "selected" {
  #id = "${var.vpc_id}"
  filter {
    name   = "tag:Name"
    values = ["default"]
  }
}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_security_group" "rds_sg"{
    #name = format("gateway-ecs-%s", local.environment) 
  name = "portal-api-postgres" 
}
