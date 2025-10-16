# Deployment Type Definitions
# This file defines the different deployment patterns and their characteristics

locals {
  # Define all deployment types with their features and components
  deployment_types = {
    # Full Stack - Complete HoneyHive platform
    full_stack = {
      description = "Complete platform with all features"
      features = {
        twingate             = true   # VPN access
        monitoring           = true   # Prometheus/Grafana
        argocd              = true   # GitOps
        eso                 = true   # External Secrets Operator
        observability       = true   # Logs, metrics, traces
        backup              = true   # Velero backups
        karpenter           = true   # Auto-scaling
        gpu_support         = false  # GPU nodes (optional)
        batch_compute       = false  # AWS Batch (optional)
      }
      components = {
        substrate = {
          vpc      = true
          dns      = true
          twingate = true
        }
        hosting = {
          cluster         = true
          karpenter      = true
          addons         = true
          pod_identities = true
        }
        application = {
          database = true
          s3       = true
        }
      }
      # Resource sizing
      cluster_config = {
        node_instance_types = ["t3.xlarge", "t3.2xlarge"]
        min_nodes          = 3
        max_nodes          = 10
        desired_nodes      = 3
      }
    }
    
    # Control Plane - API and management services
    control_plane = {
      description = "API, dashboard, and GitOps management"
      features = {
        twingate             = false  # No VPN (customers use their own)
        monitoring           = true   # Central monitoring
        argocd              = true   # Manage data planes
        eso                 = true   # Secret management
        observability       = true   # Central observability
        backup              = true   # Backup control plane data
        karpenter           = false  # Fixed sizing
        gpu_support         = false  # No GPU needed
        batch_compute       = false  # No batch processing
      }
      components = {
        substrate = {
          vpc      = true
          dns      = true
          twingate = false
        }
        hosting = {
          cluster         = true
          karpenter      = false
          addons         = true
          pod_identities = true
        }
        application = {
          database = true   # Control plane state
          s3       = true   # Artifacts, configs
        }
      }
      cluster_config = {
        node_instance_types = ["t3.large", "t3.xlarge"]
        min_nodes          = 2
        max_nodes          = 4
        desired_nodes      = 2
      }
    }
    
    # Data Plane - Compute workloads
    data_plane = {
      description = "Compute workloads and processing"
      features = {
        twingate             = false  # Access via control plane
        monitoring           = false  # Ships to control plane
        argocd              = false  # Managed by control plane
        eso                 = true   # Get secrets from control
        observability       = true   # Local collection
        backup              = false  # Stateless workloads
        karpenter           = true   # Critical for scaling
        gpu_support         = true   # ML workloads (optional)
        batch_compute       = true   # Large-scale processing (optional)
      }
      components = {
        substrate = {
          vpc      = true
          dns      = true
          twingate = false
        }
        hosting = {
          cluster         = true
          karpenter      = true   # Auto-scaling critical
          addons         = true
          pod_identities = true
        }
        application = {
          database = false  # Uses control plane DB
          s3       = true   # Temp storage
        }
      }
      cluster_config = {
        node_instance_types = ["c6i.2xlarge", "c6i.4xlarge", "g4dn.xlarge"]
        min_nodes          = 1
        max_nodes          = 100
        desired_nodes      = 2
      }
    }
    
    # Federated BYOC - Customer cloud, HoneyHive managed
    federated_byoc = {
      description = "Deploy in customer's AWS account with HoneyHive management"
      features = {
        twingate             = false  # Customer VPN
        monitoring           = true   # Limited monitoring
        argocd              = true   # GitOps in customer account
        eso                 = true   # Customer's secrets
        observability       = true   # Compliance requirement
        backup              = true   # Customer data protection
        karpenter           = true   # Optional auto-scaling
        gpu_support         = false  # Customer decides
        batch_compute       = false  # Customer decides
        customer_kms        = true   # Use customer's keys
        compliance_controls = true   # Audit and compliance
        data_residency      = true   # Data stays in region
        network_isolation   = true   # PrivateLink only
      }
      components = {
        substrate = {
          vpc          = true
          dns          = true
          twingate     = false
          customer_vpn = true   # Customer's VPN
        }
        hosting = {
          cluster         = true
          karpenter      = true
          addons         = true
          pod_identities = true
        }
        application = {
          database = true   # In customer account
          s3       = true   # In customer account
        }
        byoc = {
          cross_account_roles  = true
          compliance_controls  = true
          data_residency      = true
          customer_kms        = true
          network_isolation   = true
        }
      }
      cluster_config = {
        node_instance_types = ["t3.large", "t3.xlarge"]  # Customer preference
        min_nodes          = 2
        max_nodes          = 20
        desired_nodes      = 3
      }
    }
    
    # Hybrid SaaS - Control in HoneyHive, Data in customer
    hybrid_saas = {
      description = "Control plane in HoneyHive cloud, data plane in customer cloud"
      features = {
        twingate             = false  # No direct access
        monitoring           = false  # Forward to control
        argocd              = false  # Managed by control
        eso                 = true   # Hybrid secrets
        observability       = true   # Forward to control
        backup              = false  # Control plane handles
        karpenter           = true   # Scale in customer
        gpu_support         = true   # Customer workloads
        batch_compute       = true   # Customer processing
        hybrid_connector    = true   # Connect to control
        data_proxy         = true   # Secure data transfer
        privatelink        = true   # Secure connectivity
      }
      components = {
        substrate = {
          vpc      = true
          dns      = true
          twingate = false
        }
        hosting = {
          cluster         = true
          karpenter      = true
          addons         = true
          pod_identities = true
        }
        application = {
          database = false  # In control plane
          s3       = true   # Customer data
        }
        hybrid = {
          control_plane_connector = true
          api_gateway            = true
          data_proxy             = true
          privatelink_endpoints  = true
          telemetry_forwarder   = true
        }
      }
      cluster_config = {
        node_instance_types = ["c6i.xlarge", "c6i.2xlarge"]
        min_nodes          = 2
        max_nodes          = 50
        desired_nodes      = 3
      }
    }
    
    # Edge deployment - IoT and edge computing
    edge = {
      description = "Edge deployment for IoT and low-latency requirements"
      features = {
        twingate             = false
        monitoring           = false  # Limited
        argocd              = false
        eso                 = true
        observability       = false  # Limited bandwidth
        backup              = false
        karpenter           = false  # Fixed resources
        gpu_support         = false
        batch_compute       = false
        edge_optimized      = true   # Edge-specific
        offline_capable     = true   # Work offline
      }
      components = {
        substrate = {
          vpc      = true
          dns      = true
          twingate = false
        }
        hosting = {
          cluster         = true   # K3s or EKS Anywhere
          karpenter      = false
          addons         = false  # Minimal
          pod_identities = true
        }
        application = {
          database = false  # Local SQLite
          s3       = false  # Local storage
        }
      }
      cluster_config = {
        node_instance_types = ["t3.small", "t3.medium"]
        min_nodes          = 1
        max_nodes          = 3
        desired_nodes      = 1
      }
    }
  }
  
  # Get current deployment type from config
  current_deployment_type = try(
    include.tenant_config.locals.cfg.deployment_type,
    "full_stack"  # Default if not specified
  )
  
  # Get the configuration for current deployment type
  deployment_config = local.deployment_types[local.current_deployment_type]
  
  # Export features for use in units
  deployment_features = local.deployment_config.features
  
  # Export components for conditional deployment
  deployment_components = local.deployment_config.components
  
  # Export cluster configuration
  cluster_config = local.deployment_config.cluster_config
}
