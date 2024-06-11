resource "aws_sns_topic" "ecs_topic_for_alerts" {
  name = var.sns_topic_name_for_alerts
  tags = var.tags
}

resource "aws_sns_topic_subscription" "sns-email-for-alerts" {
  topic_arn = aws_sns_topic.ecs_topic_for_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email_for_cloudwatch_alerts
}

# Define here the alerts that must be enabled as defualt for any ECS Cluster
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cloudwatch-metrics.html

resource "aws_cloudwatch_metric_alarm" "CPUReservation" {
  alarm_name                = "${var.cluster_name}-CPUReservation"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUReservation"
  namespace                 = "AWS/ECS"
  period                    = 120
  statistic                 = "Average"
  threshold                 = var.CPUReservation_threshold
  alarm_description         = "The percentage of CPU units that are reserved by running tasks in the cluster"
  insufficient_data_actions = []
  dimensions = {
    ClusterName = var.cluster_name
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.ecs_topic_for_alerts.arn]
  ok_actions      = [aws_sns_topic.ecs_topic_for_alerts.arn]
  tags            = var.tags
}

resource "aws_cloudwatch_metric_alarm" "CPUUtilization" {
  alarm_name                = "${var.cluster_name}-CPUUtilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 120
  statistic                 = "Average"
  threshold                 = var.CPUUtilization_threshold
  alarm_description         = "The percentage of CPU units that are used in the cluster or service"
  insufficient_data_actions = []
  dimensions = {
    ClusterName = var.cluster_name
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.ecs_topic_for_alerts.arn]
  ok_actions      = [aws_sns_topic.ecs_topic_for_alerts.arn]
  tags            = var.tags
}

resource "aws_cloudwatch_metric_alarm" "MemoryReservation" {
  alarm_name                = "${var.cluster_name}-MemoryReservation"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "MemoryReservation"
  namespace                 = "AWS/ECS"
  period                    = 120
  statistic                 = "Average"
  threshold                 = var.MemoryReservation_threshold
  alarm_description         = "The percentage of memory that is reserved by running tasks in the cluster"
  insufficient_data_actions = []
  dimensions = {
    ClusterName = var.cluster_name
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.ecs_topic_for_alerts.arn]
  ok_actions      = [aws_sns_topic.ecs_topic_for_alerts.arn]
  tags            = var.tags
}

resource "aws_cloudwatch_metric_alarm" "MemoryUtilization" {
  alarm_name                = "${var.cluster_name}-MemoryUtilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "MemoryUtilization"
  namespace                 = "AWS/ECS"
  period                    = 120
  statistic                 = "Average"
  threshold                 = var.MemoryUtilization_threshold
  alarm_description         = "The percentage of memory that is used in the cluster or service"
  insufficient_data_actions = []
  dimensions = {
    ClusterName = var.cluster_name
  }
  actions_enabled = true
  alarm_actions   = [aws_sns_topic.ecs_topic_for_alerts.arn]
  ok_actions      = [aws_sns_topic.ecs_topic_for_alerts.arn]
  tags            = var.tags
}