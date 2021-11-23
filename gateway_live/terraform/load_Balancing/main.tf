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
  alb_sg_name = format("%s-%s-%s", local.name, "alb", local.environment) 
  subnets    = tolist(data.aws_subnet_ids.gateway_subnets_ids.ids)


}

data "aws_vpc" "gateway_vpc" {
  filter {
    name = "tag:Name"
    values = [local.vpc_name]
  }
}

data "aws_security_group" "alb_sg" {
  name = local.alb_sg_name
}

data "aws_subnet_ids" "gateway_subnets_ids" {
  vpc_id = data.aws_vpc.gateway_vpc.id
}

data "aws_acm_certificate" "ssl_certificate" {
  domain =  "*.gateway-staging.pokt.network"
  types = ["AMAZON_ISSUED"]
}

module "alb" {
    source = "../../../../modules/services/load_balancing"
    
    name                       = local.name
    environment                = local.environment 

    vpc_id                     = data.aws_vpc.gateway_vpc.id

    load_balancer_type         = "application"
    internal                   = false
    security_groups            = [data.aws_security_group.alb_sg.id] 
    subnets                    = [ local.subnets[0], local.subnets[1]]
    enable_http2               = true
    ip_address_type            = "ipv4"
    drop_invalid_header_fields = true

    target_groups = [
        {
          name                 = format("%s-%s", local.name, local.environment)
          port                 = 3000
          protocol             = "HTTP"
          protocol_version     = "HTTP1"
          target_type          = "ip"
          deregistration_delay           = 300
          load_balancing_algorithm_type  = "round_robin"

          health_check = {
            enabled             = true
            interval            = 30
            path                = "/"
            port                = "traffic-port"
            healthy_threshold   = 5
            unhealthy_threshold = 2
            timeout             = 5
            protocol            = "HTTP"
            matcher             = "200"
          }
        }
      ]

    https_listeners = [
      # Forward action is default, either when defined or undefined 
      {
        port               = 443
        protocol           = "HTTPS"
        certificate_arn    = data.aws_acm_certificate.ssl_certificate.arn
        ssl_policy         = "ELBSecurityPolicy-2016-08"
        action_type        = "forward"
        target_group_index = 0
      }
    ]
}
