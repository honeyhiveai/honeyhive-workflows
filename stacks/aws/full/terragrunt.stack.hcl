# Full Stack - Complete HoneyHive platform deployment
# This stack orchestrates all layers: substrate, hosting, and application

# Substrate Layer
unit "vpc" {
  source = "../../../units/substrate/vpc"
  path   = "substrate/vpc"
}

unit "dns" {
  source = "../../../units/substrate/dns"
  path   = "substrate/dns"

}

unit "twingate" {
  source = "../../../units/substrate/twingate"
  path   = "substrate/twingate"

}

# Hosting Layer
unit "cluster" {
  source = "../../../units/hosting/cluster"
  path   = "hosting/cluster"

}

unit "karpenter" {
  source = "../../../units/hosting/karpenter"
  path   = "hosting/karpenter"

}

unit "addons" {
  source = "../../../units/hosting/addons"
  path   = "hosting/addons"

}

unit "pod_identities" {
  source = "../../../units/hosting/pod-identities"
  path   = "hosting/pod-identities"

}

unit "external_secrets" {
  source = "../../../units/hosting/external_secrets"
  path   = "hosting/external_secrets"

}

unit "argocd_apps" {
  source = "../../../units/hosting/argocd_apps"
  path   = "hosting/argocd_apps"

}

# Application Layer
unit "database" {
  source = "../../../units/application/database"
  path   = "application/database"

}

unit "s3" {
  source = "../../../units/application/s3"
  path   = "application/s3"

}

unit "ecr" {
  source = "../../../units/application/ecr"
  path   = "application/ecr"

}

unit "secrets_configs" {
  source = "../../../units/application/secrets_configs"
  path   = "application/secrets_configs"

}

unit "iam" {
  source = "../../../units/application/iam"
  path   = "application/iam"

}

unit "argocd_apps" {
  source = "../../../units/application/argocd_apps"
  path   = "application/argocd_apps"

}

