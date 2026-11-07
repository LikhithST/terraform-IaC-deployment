provider "aws" {
  region                = "us-east-1"
  tag_policy_compliance = "error"
  default_tags {
    tags = {
      iac-tool = "terraform"
    }
  }
}

# Route53 zone is shared across staging and production
resource "aws_route53_zone" "primary" {
  name = "bookmykarte.com"
}