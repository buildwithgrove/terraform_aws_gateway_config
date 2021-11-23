output "domain_validation_options" {
    value = module.acm.acm_certificate_domain_validation_options
}

output "certificate_arn" {
    value = module.acm.acm_certificate_arn
}