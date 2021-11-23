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
  domain_tld  ="pokt.network"
  domain_name = "*.gateway.pokt.network"


}

data "aws_route53_zone" "dns_zone" {
  name         = local.environment != "" ? format("%s-%s.%s", local.name, local.environment, local.domain_tld) : format("%s.%s", local.name, local.domain_tld)
} 

module "acm" {
  source = "../../../../modules/services/acm"

  domain_name               = local.domain_name
  subject_alternative_names = [
        "*.api.s0.b.hmny.io",
        "*.api.s0.stn.hmny.io",
        "*.api.s0.t.hmny.io",
        "*.api.s1.b.hmny.io",
        "*.api.s1.stn.hmny.io",
        "*.api.s1.t.hmny.io",
        "*.api.s2.b.hmny.io",
        "*.api.s2.stn.hmny.io",
        "*.api.s2.t.hmny.io",
        "*.api.s3.b.hmny.io",
        "*.api.s3.stn.hmny.io",
        "*.api.s3.t.hmny.io",
        "*.b.hmny.io",
        "*.harmony.one",
        "*.hmny.io",
        "*.s0.b.hmny.io",
        "*.s0.stn.hmny.io",
        "*.s0.t.hmny.io",
        "*.s1.b.hmny.io",
        "*.s1.stn.hmny.io",
        "*.s1.t.hmny.io",
        "*.s2.b.hmny.io",
        "*.s2.stn.hmny.io",
        "*.s2.t.hmny.io",
        "*.s3.b.hmny.io",
        "*.s3.stn.hmny.io",
        "*.s3.t.hmny.io",
        "*.stn.hmny.io",
        "*.t.hmny.io",
    ]
  validation_method                           = "DNS"
  certificate_transparency_logging_preference = true  

}

module "dns_validation" {
    source = "../../../../modules/services/dns/records"
    
    zone_id = data.aws_route53_zone.dns_zone.id
    name    = module.acm.main_domain_validation_options[local.domain_name]["name"]
    type    = module.acm.main_domain_validation_options[local.domain_name]["type"]
    records = [module.acm.main_domain_validation_options[local.domain_name]["record"]]
    dns_ttl  = 60
}

# resource "aws_acm_certificate_validation" "this" {
#   certificate_arn = module.acm.acm_certificate_arn
#   validation_record_fqdns = [for record in module.dns_validation : record.fqdn]
#   depends_on = [module.dns_validation]
# }

