provider "aws" {
  region = local.region
  default_tags {
    tags = {
    Environment = local.environment
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    }
  }
}

locals {
  name        = "gateway"
  environment = "terraform"
  region      = "ap-northeast-2"
}

#----- VPC --------
module "vpc" {
  source = "../../../../modules/services/networking/vpc"

  name        = local.name
  environment = local.environment
  
  cidr        = "10.0.0.0/16"
  enable_ipv6 = false

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

}

#----- Security groups --------
module "alb_sg" {
  source = "../../../../modules/services/networking/security_groups"

  name        = local.name
  environment = local.environment
  
  vpc_id = module.vpc.vpc_id
  prefix = "alb"

  ingress_with_cidr_blocks = [{
    rule        = "alb-https"
    cidr_blocks = "0.0.0.0/0"
  }]

  egress_with_cidr_blocks = [ {
    rule = "all-all"
    cidr_blocks = "0.0.0.0/0"

  } ]
}

module "ecs_sg" {
  source = "../../../../modules/services/networking/security_groups"

  name        = local.name
  environment = local.environment

  vpc_id = module.vpc.vpc_id
  prefix = "ecs"


  ingress_with_source_security_group_id = [ {
    rule = "ecs-tcp"
    source_security_group_id = module.alb_sg.security_group_id
  } ]

  egress_with_cidr_blocks = [ {
    rule = "all-all"
    cidr_blocks = "0.0.0.0/0"
  } ]
  
}

module "redis_sg" {
  source = "../../../../modules/services/networking/security_groups"

  name        = local.name
  environment = local.environment

  vpc_id = module.vpc.vpc_id
  prefix = "redis"

  ingress_with_source_security_group_id = [ {
    rule = "redis-tcp"
    source_security_group_id = module.ecs_sg.security_group_id
  } ]

  egress_with_cidr_blocks = [ {
    rule = "all-all"
    cidr_blocks = "0.0.0.0/0"
  } ]
  
}