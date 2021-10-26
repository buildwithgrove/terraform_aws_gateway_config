resource "aws_ecr_repository" "gateway" {
  name                 = "${var.ecr_repo}-${var.environment}"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
  encryption_configuration {
    encryption_type ="AES256"
  }
  tags ={
      Name = "${var.ecr_repo}-${var.environment}"
  }

}