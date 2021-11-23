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
  domain_tld  = "pokt.network"
  alb_name    = "${local.name}-${local.environment}"
  alb_dns_name = format("dualstack.%s", data.aws_lb.alb.dns_name)
}

data "aws_route53_zone" "dns_zone" {
  name = local.environment != "" ? format("%s-%s.%s", local.name, local.environment, local.domain_tld) : format("%s.%s", local.name, local.domain_tld)
} 

data "aws_lb" "alb" { 
  name = local.alb_name
}

module "dns_record" {
    source = "../../../../../modules/services/dns/records"

    zone_id = data.aws_route53_zone.dns_zone.zone_id
    name    = "*"
    type    = "A"
    alias = {
        name                   = local.alb_dns_name
        zone_id                = data.aws_lb.alb.zone_id
        evaluate_target_health = "disabled"
        }
}