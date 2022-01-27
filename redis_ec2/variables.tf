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