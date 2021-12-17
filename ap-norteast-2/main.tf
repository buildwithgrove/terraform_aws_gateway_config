provider "aws" {
  region = local.region
  default_tags {
    tags = local.tags
  }
}

module "gateway" {
  source  = "app.terraform.io/pokt-foundation/gateway/aws"
  version = "0.0.3"

  # ---------- ecr -----------
  repo_name                = "${local.name}-${local.environment}"
  image_tag_mutability     = "MUTABLE"
  scan_images_on_push      = false
  encryption_type          = "AES256"

}