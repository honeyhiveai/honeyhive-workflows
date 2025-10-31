# Application Stack - Application resources
# This stack includes database, S3 buckets, and IAM roles

unit "database" {
  source = "${get_parent_terragrunt_dir()}/units/application/database"
  path   = "database"
}

unit "s3" {
  source = "${get_parent_terragrunt_dir()}/units/application/s3"
  path   = "s3"
}

unit "iam" {
  source = "${get_parent_terragrunt_dir()}/units/application/iam"
  path   = "iam"
}

