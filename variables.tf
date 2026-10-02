variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for every resource."
  type        = string
  default     = "secure-lz"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "Use 3-20 lowercase letters, numbers or hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "Use 2 or 3 AZs for high availability."
  }
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private subnets can reach the internet. Costs ~$32/month."
  type        = bool
  default     = false
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty threat detection."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "How long to keep CloudWatch logs (VPC flow logs)."
  type        = number
  default     = 365
}

variable "cloudtrail_log_expiration_days" {
  description = "Days before CloudTrail logs in S3 are deleted."
  type        = number
  default     = 365
}

variable "db_port" {
  description = "Database port allowed from the app tier only."
  type        = number
  default     = 5432
}

variable "alert_email" {
  description = "Email that receives CIS security alarms (root login, no-MFA login, etc.). Leave empty to skip."
  type        = string
  default     = ""
}
