variable "aws_access_key_id" {
    description = "aws access key id "
    type        = string
    default     = null  
}

variable "aws_secret_access_key" {
    description = "aws secret access key"
    type        = string
    default     = null   
}

variable "name" {
    description = "name of the task definition"
    type        = string
    default     = null  
}

variable "environment" {
    description = "Environement for the task definition, possible values: prod, test, canary"
    type        = string
    default     = null   
}
variable "region" {
    description = "aws region where to launch this task definition"
    type        = string
    default     = null  
}
