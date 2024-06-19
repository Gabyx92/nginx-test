provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "TFProviders"
      Project     = "Test"
    }
  }
}

#Add tags for cost optimization 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}
