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

#----- ECR --------

module "gateway-repo" {
    source = "../../../../modules/services/registry"
    
    name        = local.name
    environment = local.environment

    image_tag_mutability     = "MUTABLE"
    scan_images_on_push      = false
    encryption_type          = "AES256"
}
