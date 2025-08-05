
provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "aws" {
  alias  = "secure_provider"
  region = "us-west-1"
  version = "~> 4.0"
  
  assume_role {
    role_arn     = var.aws_role_arn
    session_name = "terraform-session"
    external_id  = var.external_id
  }
  
  default_tags {
    tags = {
      ManagedBy    = "Terraform"
      Environment  = var.environment
    }
  }
}


terraform {
  backend "s3" {
    encrypt = true
  }
}
