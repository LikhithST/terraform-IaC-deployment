provider "aws" {
  region = "us-east-1"
  tag_policy_compliance = "error"
  default_tags {
    tags = {
      iac-tool = "terraform"
    }
  }
}

locals {
  environment_name = "staging"
}

variable "db_pass" {
  sensitive = true
  description = "db password"
  type = string
}

module "web-app-module" {
  source = "../web-app-module"
  
  # Input variables
  bucket_prefix    = "web-app-data-${local.environment_name}"
  domain           = "devopsdeployed.com"
  environment_name = local.environment_name
  instance_type    = "t2.micro"
  create_dns_zone  = false
  db_name          = "${local.environment_name}mydb"
  db_user          = "foo"
  db_pass          = var.db_pass
}