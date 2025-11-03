# Hosting Stack - Kubernetes platform layer

unit "cluster" {
  source = "../../../units/hosting/cluster"
  path   = "cluster"
}

unit "karpenter" {
  source = "../../../units/hosting/karpenter"
  path   = "karpenter"
}

unit "addons" {
  source = "../../../units/hosting/addons"
  path   = "addons"
}

unit "pod_identities" {
  source = "../../../units/hosting/pod-identities"
  path   = "pod-identities"
}

unit "argocd_apps" {
  source = "../../../units/hosting/argocd_apps"
  path   = "argocd_apps"
}

unit "s3" {
  source = "../../../units/hosting/s3"
  path   = "s3"
}

unit "eso_secrets" {
  source = "../../../units/hosting/eso_secrets"
  path   = "eso_secrets"
}
