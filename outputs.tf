output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (for load balancers)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (for apps and databases)."
  value       = aws_subnet.private[*].id
}

output "security_group_ids" {
  description = "Security groups for each tier."
  value = {
    alb = aws_security_group.alb.id
    app = aws_security_group.app.id
    db  = aws_security_group.db.id
  }
}

output "cloudtrail_bucket" {
  description = "S3 bucket holding CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail.id
}

output "kms_key_arn" {
  description = "KMS key used to encrypt audit logs."
  value       = aws_kms_key.audit.arn
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID (null if disabled)."
  value       = try(aws_guardduty_detector.this[0].id, null)
}

output "security_alerts_topic_arn" {
  description = "SNS topic that receives CIS alarms."
  value       = aws_sns_topic.security_alerts.arn
}
