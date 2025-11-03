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

unit "argocd_apps" {
  source = "../../../units/application/argocd_apps"
  path   = "argocd_apps"
}
