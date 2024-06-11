terraform {
  backend "s3" {
    bucket         = "131423435875-terraform-states"
    key            = "ecs-service/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "TerraformLockStates"
  }
}