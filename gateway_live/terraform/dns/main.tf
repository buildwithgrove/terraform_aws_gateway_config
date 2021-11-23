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

module "zone" {
    source = "../../../../modules/services/dns/zone"

    name          = local.name
    environment   = local.environment
    domain_tld    = "pokt.network"

    comment       = format("%s public hosted zone", local.environment)
    force_destroy = false
}


