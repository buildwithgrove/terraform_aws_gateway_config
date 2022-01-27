variable "aws_access_key_id" {
    description = "aws access key id"
    type        = string
    default     = null  
}

variable "aws_secret_access_key" {
    description = "aws secret access key"
    type        = string
    default     = null   
}

variable "region" {
    description = "aws region where to launch the gateway"
    type        = string
    default     = null  
}

variable "environment" {
    description = "Environment for the gateway, possible values: prod, test, canary,etc."
    type        = string
    default     = null
}

variable "ingress_with_cidr_blocks" {
    description = "Security group extra rules, e.g to add ip address for ssh"
    type        = list(map(string)) 
    default     =  []
}