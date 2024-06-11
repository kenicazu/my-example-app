output "python_pipeline_arn" {
  value       = module.python_microservice_pipeline.pipeline_arn
  description = "CodePipeline pipeline ARN"
}

output "pipeline_artifacts_bucket_arn" {
  value       = module.pipeline_artifacts_bucket.bucket_arn
  description = "The artifacts S3 Bucket ARN"
}