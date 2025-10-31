# Application Stack - Application resources
# This stack includes database, S3 buckets, and IAM roles

unit "database" {
  source = "../../../units/application/database"
  path   = "database"
}

unit "s3" {
  source = "../../../units/application/s3"
  path   = "s3"
}

unit "iam" {
  source = "../../../units/application/iam"
  path   = "iam"
}
