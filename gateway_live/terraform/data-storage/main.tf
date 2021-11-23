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

  vpc_name      = format("%s-%s", local.name, local.environment)
  redis_sg_name = format("%s-%s-%s", local.name, "redis", local.environment) 
}

data "aws_vpc" "gateway_vpc" {
  filter {
    name = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_subnet_ids" "gateway_subnets_ids" {
  vpc_id = data.aws_vpc.gateway_vpc.id
}

data "aws_security_group" "redis_sg" {
  name = local.redis_sg_name
}

module "redis" {
    source = "../../../../modules/services/data-storage"
    name        = local.name
    environment = local.environment

    redis_sb_group_description   = "provide redis with all the subnets associated with it"
    subnet_ids                   = tolist(data.aws_subnet_ids.gateway_subnets_ids.ids)

  engine                        = "redis"
  engine_version                = "6.x"
  port                          = 6379
  parameter_group_name          = "default.redis6.x"
  node_type                     = "cache.r6g.xlarge"
  multi_az_enabled              = true 
  automatic_failover_enabled    = true
  availability_zones            = ["${local.region}a", "${local.region}b", "${local.region}c"]
  replication_group_description = "gateway redis elasticache"
  number_cache_clusters         = 3
  security_group_ids            = [data.aws_security_group.redis_sg.id]
  at_rest_encryption_enabled    = true 
  transit_encryption_enabled    = false
  maintenance_window            = "mon:18:00-mon:19:00"
  # snapshot_name                 = var.snapshot_name
  # snapshot_arns                 = var.snapshot_arns
  # snapshot_window               = var.snapshot_window
  # snapshot_retention_limit      = var.snapshot_retention_limit
  # final_snapshot_identifier     = var.final_snapshot_identifier
  # apply_immediately             = var.apply_immediately
}