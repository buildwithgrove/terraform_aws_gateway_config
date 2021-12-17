locals {
  name        = "gateway"
  environment = "prod"
  region      = "ap-northeast-2"
  
  tags = {
    Environment = local.environment
    Project     = "Gateway"
    Automation  = "true"
    Owner       = "DevOps team"
    }  

}