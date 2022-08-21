provider "aws" {
  region     = local.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
  default_tags {
    tags = local.tags
  }
}

/*

terraform {
  cloud {
    organization = "pokt-foundation"

    workspaces {
      name = "us-west-2-rds"
    }
  }
}

*/
