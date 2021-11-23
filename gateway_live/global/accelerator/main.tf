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

module "accelerator" {
    source = "../../../modules/services/accelerator"

    name        = local.name
    environment = local.environment

    listeners = [
    {
      client_affinity = "NONE"
      protocol        = "TCP"
      port_ranges = [
        {
          from_port = 3000
          to_port   = 3000 # alb listeners ports
        }, 
        {
          from_port = 443
          to_port   = 443 # alb listeners ports
        }, 
      ]
    }
  ]

    
}