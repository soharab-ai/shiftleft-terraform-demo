
provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "aws" {
  alias   = "plain_text_access_keys_provider"
  region  = "us-west-1"
  version = "~> 4.0"
  
  assume_role {
    role_arn     = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
    session_name = "terraform-session"
  }
}


terraform {
  backend "s3" {
    encrypt = true
  }
}
