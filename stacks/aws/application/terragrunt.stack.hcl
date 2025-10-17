# Application Stack - Application resources
# This stack includes database and S3 buckets

unit "database" {
  source = "../../../units/application/database"
  path   = "database"
}

unit "s3" {
  source = "../../../units/application/s3"
  path   = "s3"
}

