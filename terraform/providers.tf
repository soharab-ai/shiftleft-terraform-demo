
provider "aws" {
  profile = var.profile
  region  = var.region
}

provider "aws" {
  alias  = "plain_text_access_keys_provider"
  region = "us-west-1"
  assume_role {
    role_arn     = "arn:aws:iam::ACCOUNT_ID:role/DeploymentRole"
    session_name = "terraform-deployment"
    external_id  = "unique-external-id"
  }
}


terraform {
  backend "s3" {
    encrypt = true
  }
}
