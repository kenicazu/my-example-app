provider "aws" {
  region = var.account.region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret" "datadog" {
  name = "datadog"
}

data "aws_secretsmanager_secret_version" "secret_credentials" {
  secret_id = data.aws_secretsmanager_secret.datadog.id
}

# Configure the Datadog provider
provider "datadog" {
  api_key = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["datadog_api_key"]
  app_key = jsondecode(data.aws_secretsmanager_secret_version.secret_credentials.secret_string)["datadog_app_key"]
}


# Create a new Datadog - Amazon Web Services integration
resource "datadog_integration_aws" "sandbox" {
  account_id = data.aws_caller_identity.current.account_id
  role_name  = var.datadog_integration_aws.roleName

}


data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        datadog_integration_aws.sandbox.external_id
      ]
    }
  }
}

data "aws_iam_policy_document" "datadog_aws_integration" {
  statement {
    actions = [
      "apigateway:GET",
      "autoscaling:Describe*",
      "backup:List*",
      "budgets:ViewBudget",
      "cloudfront:GetDistributionConfig",
      "cloudfront:ListDistributions",
      "cloudtrail:DescribeTrails",
      "cloudtrail:GetTrailStatus",
      "cloudtrail:LookupEvents",
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*",
      "codedeploy:List*",
      "codedeploy:BatchGet*",
      "directconnect:Describe*",
      "dynamodb:List*",
      "dynamodb:Describe*",
      "ec2:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "elasticache:Describe*",
      "elasticache:List*",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeTags",
      "elasticfilesystem:DescribeAccessPoints",
      "elasticloadbalancing:Describe*",
      "elasticmapreduce:List*",
      "elasticmapreduce:Describe*",
      "es:ListTags",
      "es:ListDomainNames",
      "es:DescribeElasticsearchDomains",
      "events:CreateEventBus",
      "fsx:DescribeFileSystems",
      "fsx:ListTagsForResource",
      "health:DescribeEvents",
      "health:DescribeEventDetails",
      "health:DescribeAffectedEntities",
      "kinesis:List*",
      "kinesis:Describe*",
      "lambda:GetPolicy",
      "lambda:List*",
      "logs:DeleteSubscriptionFilter",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DescribeSubscriptionFilters",
      "logs:FilterLogEvents",
      "logs:PutSubscriptionFilter",
      "logs:TestMetricFilter",
      "organizations:Describe*",
      "organizations:List*",
      "rds:Describe*",
      "rds:List*",
      "redshift:DescribeClusters",
      "redshift:DescribeLoggingStatus",
      "route53:List*",
      "s3:GetBucketLogging",
      "s3:GetBucketLocation",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
      "s3:PutBucketNotification",
      "ses:Get*",
      "sns:List*",
      "sns:Publish",
      "sqs:ListQueues",
      "states:ListStateMachines",
      "states:DescribeStateMachine",
      "support:DescribeTrustedAdvisor*",
      "support:RefreshTrustedAdvisorCheck",
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues",
      "xray:BatchGetTraces",
      "xray:GetTraceSummaries"
    ]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "datadog_aws_integration" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration.json
}

resource "aws_iam_role" "datadog_aws_integration" {
  name               = var.datadog_integration_aws.roleName
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role.json
}

resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration.arn
}


# Creating Datadog Alerts

resource "datadog_monitor" "cluster_cpuutilization" {
  name    = "ECS - CPU check"
  type    = "metric alert"
  message = "ECS - CPU is > 80%! Notify: @${var.sns_topic_name_for_alerts}"

  query = "avg(last_15m):avg:aws.ecs.cluster.cpuutilization{clustername:${var.cluster_name}} > ${var.datadog_integration_aws.alert_cpuutilization_threshold}"

  monitor_thresholds {
    critical = var.datadog_integration_aws.alert_cpuutilization_threshold
  }
}

resource "datadog_monitor" "memory_utilization" {
  name    = "ECS - Memory check"
  type    = "metric alert"
  message = "ECS - MEMORY is > 80%! Notify: @${var.sns_topic_name_for_alerts}"

  query = "avg(last_15m):avg:aws.ecs.cluster.memory_utilization{clustername:${var.cluster_name}} > ${var.datadog_integration_aws.alert_memory_utilization_threshold}"

  monitor_thresholds {
    critical = var.datadog_integration_aws.alert_memory_utilization_threshold
  }
}

resource "datadog_monitor" "task_pending" {
  name    = "ECS - TaskPending check"
  type    = "metric alert"
  message = "ECS - Task pending is > 0! Notify: @${var.sns_topic_name_for_alerts}"

  query = "avg(last_15m):avg:aws.ecs.service.pending{clustername:${var.cluster_name}} > 0"

  monitor_thresholds {
    critical = 0
  }
}

