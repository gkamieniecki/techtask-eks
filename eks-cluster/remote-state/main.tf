provider "aws" {
  region            = "eu-central-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket            = "techtask-state-bucket-gk"
  acl               = "private"
  force_destroy     = true

  versioning {
    enabled         = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "techtask-state-lock-gk"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
  tags            = {
  Name            = "DynamoDB Terraform Techtask State Locking"
 }
}