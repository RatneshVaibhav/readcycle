# Credentials never live in these files: Terraform uses the AWS CLI login on this machine
# (export AWS_PROFILE=readcycle after `aws login --profile readcycle`).
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "readcycle"
      ManagedBy = "Terraform"
      Owner     = var.owner
    }
  }
}
