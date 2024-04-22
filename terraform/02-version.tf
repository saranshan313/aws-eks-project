terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.40.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.29.0"
    }
  }

  backend "s3" {
    # bucket         = "tf-remote-state-234-343-555"
    # key            = "terraform.tfstate"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-remote-state-dynamo"
    # encrypt        = true
  }
}