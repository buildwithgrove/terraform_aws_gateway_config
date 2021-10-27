resource "aws_s3_bucket" "terraform_state" {
    bucket = "gateway-terraform-state-${var.environment}-${var.region}"
    versioning {
      enabled = true
    }
    lifecycle {
      prevent_destroy = true
    }
}

resource "aws_dynamodb_table" "terraform_state_locking" {
    name            = "terraform-state-locking-${var.environment}"
    hash_key        = "LockID"
    write_capacity  = 5
    read_capacity   = 5
    attribute {
        name = "LockID"
        type = "S"
  }
}