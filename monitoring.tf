# CloudTrail -> CloudWatch Logs, plus CIS AWS Foundations alarms.
# Each alarm watches the trail for a high-risk event and emails you.

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${local.name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.audit.arn
}

data "aws_iam_policy_document" "cloudtrail_logs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_logs" {
  name               = "${local.name}-cloudtrail-logs"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_logs_assume.json
}

data "aws_iam_policy_document" "cloudtrail_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.cloudtrail.arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_logs" {
  name   = "write-cloudtrail-logs"
  role   = aws_iam_role.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs.json
}

resource "aws_sns_topic" "security_alerts" {
  name              = "${local.name}-security-alerts"
  kms_master_key_id = aws_kms_key.audit.id
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

locals {
  cis_alarms = {
    root-account-usage = {
      description = "The root user was used (CIS 4.3)"
      pattern     = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
    }
    console-login-without-mfa = {
      description = "Console sign-in without MFA (CIS 4.2)"
      pattern     = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") && ($.userIdentity.type = \"IAMUser\") && ($.responseElements.ConsoleLogin = \"Success\") }"
    }
    unauthorized-api-calls = {
      description = "Unauthorized API calls (CIS 4.1)"
      pattern     = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
    }
    iam-policy-changes = {
      description = "IAM policy changed (CIS 4.4)"
      pattern     = "{ ($.eventSource = \"iam.amazonaws.com\") && (($.eventName = \"PutUserPolicy\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"PutGroupPolicy\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"AttachRolePolicy\") || ($.eventName = \"AttachUserPolicy\") || ($.eventName = \"AttachGroupPolicy\")) }"
    }
    cloudtrail-config-changes = {
      description = "CloudTrail stopped, deleted or changed (CIS 4.5)"
      pattern     = "{ ($.eventName = \"StopLogging\") || ($.eventName = \"DeleteTrail\") || ($.eventName = \"UpdateTrail\") }"
    }
    security-group-changes = {
      description = "Security group changed (CIS 4.10)"
      pattern     = "{ ($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"AuthorizeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") }"
    }
    kms-key-deletion = {
      description = "KMS key disabled or scheduled for deletion (CIS 4.7)"
      pattern     = "{ ($.eventSource = \"kms.amazonaws.com\") && (($.eventName = \"DisableKey\") || ($.eventName = \"ScheduleKeyDeletion\")) }"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "cis" {
  for_each       = local.cis_alarms
  name           = "${local.name}-${each.key}"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.key
    namespace = "${local.name}/CIS"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "cis" {
  for_each            = local.cis_alarms
  alarm_name          = "${local.name}-${each.key}"
  alarm_description   = each.value.description
  namespace           = "${local.name}/CIS"
  metric_name         = each.key
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]

  depends_on = [aws_cloudwatch_log_metric_filter.cis]
}
