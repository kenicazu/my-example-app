terraform {
  backend "s3" {
    bucket         = "809940063064-terraform-states"
    key            = "integrations/datadog/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "TerraformLockStates"
  }
}