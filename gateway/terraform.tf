terraform {
  backend "s3" {
    bucket = "gateway-terraform-state-dev-ap-northeast-2"
    key    = "gateway/terraform.tfstate"
    region = "ap-northeast-2"
    dynamodb_table = "terraform-state-locking-dev"
  }
}
