provider "aws" {
  region = var.account.region
}

data "aws_caller_identity" "current" {}

################################################################################
# CodePipeline Artifacts Bucket
################################################################################

module "pipeline_artifacts_bucket" {
  source       = "../modules/s3"
  bucket_name  = "${data.aws_caller_identity.current.account_id}-ecs-pipelines-artifacts"
  kms_key_name = "${data.aws_caller_identity.current.account_id}-ecs-pipelines-artifacts-key"
}

################################################################################
# Microservice pipeline
################################################################################

module "python_microservice_pipeline" {
  source                              = "../modules/code_pipeline_python"
  repository_name                     = "ecs-offering-python-app"
  artifacts_bucket_arn                = module.pipeline_artifacts_bucket.bucket_arn
  artifacts_bucket_encryption_key_arn = module.pipeline_artifacts_bucket.bucket_key_arn
  account_id                          = data.aws_caller_identity.current.account_id
  aws_region                          = var.account.region
  pipeline_articats_bucket_name       = module.pipeline_artifacts_bucket.bucket_name
  ecr_repository_name                 = var.ecr_repository_name
  cluster_name                        = var.cluster_name
  container_name                      = var.container_name
  service_name                        = var.service_name
}
