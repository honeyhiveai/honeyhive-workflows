# Hosting Stack - Fixes Needed for End-to-End Automation

## 🎯 Current State (October 21, 2025)

**Working**: 56 of 59 pods running (95% healthy!)
- ✅ EKS Cluster operational
- ✅ Karpenter provisioning nodes  
- ✅ Most Helm charts deployed
- 🔧 EBS CSI needs IAM role configuration

**Issue**: Manual intervention required to install EKS native addons

---

## 🏗️ Required Architectural Changes

### 1. Move EKS Native Addons to Cluster Module

**Current (WRONG)**:
```
hosting/aws/kubernetes/addons/main.tf:
  eks_addons = {
    vpc-cni = { most_recent = true }
    coredns = { most_recent = true }
    kube-proxy = { most_recent = true }
    aws-ebs-csi-driver = { ... }
  }
```

**Should be (RIGHT)**:
```
hosting/aws/kubernetes/cluster/main.tf:
module "eks" {
  cluster_addons = {
    vpc-cni = {
      most_recent = true
      before_compute = true  # Deploy before nodes
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.cluster_iam.roles["EBSCSIDriver"].arn
    }
    snapshot-controller = {
      most_recent = true
    }
  }
}
```

**Why**: 
- EKS addons are cluster infrastructure, not application addons
- Must deploy WITH cluster for proper initialization
- VPC CNI needed BEFORE any pods can get IPs
- CoreDNS needed for pod DNS resolution

### 2. Remove EKS Addons from Addons Module

**Delete from**
