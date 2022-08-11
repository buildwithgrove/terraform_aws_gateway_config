variable "aws_access_key_id" {
    description = "aws access key id"
    type        = string  
}

variable "aws_secret_access_key" {
    description = "aws secret access key"
    type        = string
}

variable "environment" {
    description = "Environment for the gateway, possible values: prod, test, canary,etc."
    type        = string
    default     = null   
}
variable "region" {
    description = "aws region where to launch the gateway"
    type        = string
    default     = null  
}

variable "name" {
    description = "Name of the project, recommended value: gateway"
    type        = string 
    default     =  null
}

variable "public_subnets" {
    description = "List of cidr values for the vpc public subnets"
    type        = list(string) 
    default     =  null
}

variable "ingress_with_cidr_blocks" {
    description = "Security group extra rules for ecs, e.g to add ip address for ssh"
    type        = list(map(string)) 
    default     =  []
}

variable "instance_type" {
    description = "The ec2 instance type we are launching with"
    type        = string
    default     = null
}

variable "domain_name" {
    description = "Domain name used to generate ssl certificate"
    type        = string
    default     = null
}

variable "vpc_cidr" {
    description = "The CIDR block of the VPC"
    type        = string
    default     = null
}

variable "redis_node_type" {
    description = "The elasticache instance class to be used."
    type        = string
    default     = null
}

variable "support_container_insights" {
    description = "Whether the region supports container insights"
    type        = bool
    default     = true
}

variable "create_key_pair" {
    description = "Whether to create a new key or use an existing one"
    type        = bool
    default     = true
}