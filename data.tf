data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  # checkov:skip=CKV_AWS_394: We slice the first N zones; new AZs appended by AWS do not change the selection.
  state = "available"
}

locals {
  name       = "${var.project_name}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  region     = data.aws_region.current.name
  azs        = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  trail_name = "${local.name}-trail"
  trail_arn  = "arn:${local.partition}:cloudtrail:${local.region}:${local.account_id}:trail/${local.trail_name}"
}
