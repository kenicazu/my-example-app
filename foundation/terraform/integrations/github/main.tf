provider "aws" {
  region = var.account.region
}

data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "github" {
  name = "github"
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.github.id
}

################################################################################
# CodePipeline Artifacts Bucket
################################################################################

module "pipeline_artifacts_bucket" {
  source       = "../../modules/s3"
  bucket_name  = "${data.aws_caller_identity.current.account_id}-ecs-github-pipeline-artifacts"
  kms_key_name = "${data.aws_caller_identity.current.account_id}-ecs-github-pipeline-artifacts-key"
}

################################################################################
# Microservice pipeline
################################################################################

module "python_microservice_pipeline" {
  source                              = "../../modules/code_pipeline_python_github_actions"
  repository_name                     = var.repository_name
  artifacts_bucket_arn                = module.pipeline_artifacts_bucket.bucket_arn
  artifacts_bucket_encryption_key_arn = module.pipeline_artifacts_bucket.bucket_key_arn
  account_id                          = data.aws_caller_identity.current.account_id
  aws_region                          = var.account.region
  pipeline_articats_bucket_name       = module.pipeline_artifacts_bucket.bucket_name
  ecr_repository_name                 = var.ecr_repository_name
  cluster_name                        = var.cluster_name
  container_name                      = var.container_name
  service_name                        = var.service_name
  organization_name                   = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["organization_name"]
  code_star_connection_arn            = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["code_star_connection_arn"]
  dockerhub_secret_name               = var.dockerhub_secret_name
}
