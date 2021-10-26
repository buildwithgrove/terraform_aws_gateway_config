# Setup the aws provider

provider "aws" {
  access_key  = "${var.aws_access_key_id}"
  secret_key  = "${var.aws_secret_access_key}"
  region      = "${var.region}"
  assume_role {
     role_arn = "arn:aws:iam::059424750518:role/gateway-test"
  }
  default_tags {
    tags = {
    Environment = "${var.environment}"
    Project = "Gateway"
    Automation = "true"
    Owner = "DevOps team"
    }
  }
}
