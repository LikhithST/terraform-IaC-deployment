provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      iac-tool = "terraform"
    }
  }
}

resource "aws_s3_bucket" "terraform_state_book" {
  bucket        = "tf-state-book"
  force_destroy = true
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

resource "aws_dynamodb_table" "terraform_locks_reference" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}