terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
  backend "s3" {
    encrypt        = true
    bucket         = "techtask-state-bucket-gk"
    region         = "eu-central-1"
    key            = "terraform.tfstate"
    dynamodb_table = "techtask-state-lock-gk"
    profile        = "scalac"
  }

  required_version = ">= 0.14"
}

