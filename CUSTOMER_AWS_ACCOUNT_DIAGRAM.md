# Customer AWS Account - HoneyHive Deployment

## What You'll See in Your AWS Console

### 🏗️ **Infrastructure Overview**

```mermaid
graph TB
    subgraph "Your AWS Account"
        subgraph "VPC 10.x.0.0/16"
            subgraph "Public Subnets"
                ALB[⚖️ Application Load Balancer<br/>honeyhive-alb-{env}]
                NAT[🌐 NAT Gateway<br/>honeyhive-nat-{env}]
                VPN[🔐 Twingate Connector<br/>honeyhive-vpn-{env}]
            end
            
            subgraph "Private Subnets"
                subgraph "EKS Cluster: honeyhive-{env}"
                    EKS[☸️ EKS Control Plane<br/>Managed by AWS]
                    WORKERS[🖥️ Worker Nodes<br/>honeyhive-nodes-{env}]
                    KARP[📈 Karpenter<br/>honeyhive-karpenter-{env}]
                end
                
                subgraph "HoneyHive Services"
                    API[🔌 HoneyHive API<br/>honeyhive-api-{env}]
                    UI[🖥️ HoneyHive UI<br/>honeyhive-ui-{env}]
                    WORKER[⚙️ Background Workers<br/>honeyhive-workers-{env}]
                end
                
                subgraph "Observability Stack"
                    PROM[📊 Prometheus<br/>honeyhive-prometheus-{env}]
                    GRAFANA[📈 Grafana<br/>honeyhive-grafana-{env}]
                    FLUENT[📝 Fluent Bit<br/>honeyhive-fluent-{env}]
                end
                
                subgraph "Data Layer"
                    RDS[🗄️ RDS PostgreSQL<br/>honeyhive-db-{env}]
                    S3[📦 S3 Buckets<br/>honeyhive-*-{env}]
                    REDIS[🔴 Redis Cache<br/>honeyhive-redis-{env}]
                end
            end
        end
        
        subgraph "AWS Services"
            KMS[🔐 KMS Key<br/>honeyhive-encryption-{env}]
            SECRETS[🔑 Secrets Manager<br/>honeyhive-secrets-{env}]
            CLOUDWATCH[📊 CloudWatch<br/>honeyhive-monitoring-{env}]
        end
    end
    
    subgraph "External Access"
        USERS[👥 Your Users]
        TWINGATE[🔐 Twingate VPN]
        GITHUB[🐙 GitHub Actions]
    end
    
    %% User access
    USERS --> ALB
    TWINGATE --> VPN
    
    %% Internal connections
    ALB --> API
    ALB --> UI
    API --> RDS
    API --> S3
    API --> REDIS
    WORKER --> RDS
    WORKER --> S3
    
    %% Observability
    PROM --> S3
    GRAFANA --> PROM
    FLUENT --> S3
    
    %% Security
    API --> SECRETS
    WORKER --> SECRETS
    SECRETS --> KMS
    
    %% Monitoring
    EKS --> CLOUDWATCH
    RDS --> CLOUDWATCH
    S3 --> CLOUDWATCH
```

## AWS Console Resources

### 🏗️ **EC2 & Compute**

#### **EKS Cluster**
```yaml
EKS Console:
  - Cluster: honeyhive-{env}
  - Node Groups: honeyhive-nodes-{env}
  - Add-ons: VPC CNI, CoreDNS, KubeProxy
  - Networking: VPC, Subnets, Security Groups
  - Logging: CloudWatch Logs enabled
```

#### **ECS Services**
```yaml
ECS Console:
  - Cluster: honeyhive-{env}
  - Service: honeyhive-vpn-{env}
  - Task Definition: honeyhive-twingate-{env}
  - Service Discovery: Private DNS
  - Load Balancer: Application Load Balancer
```

### 🗄️ **Storage & Database**

#### **S3 Buckets**
```yaml
S3 Console:
  - honeyhive-metrics-{env}-{region}
  - honeyhive-logs-{env}-{region}
  - honeyhive-backups-{env}-{region}
  - honeyhive-config-{env}-{region}
  - honeyhive-artifacts-{env}-{region}

Features:
  - Server-side encryption (SSE-S3)
  - Versioning enabled
  - Lifecycle policies
  - Access logging
  - Cross-region replication (optional)
```

#### **RDS Database**
```yaml
RDS Console:
  - Instance: honeyhive-db-{env}
  - Engine: PostgreSQL
  - Instance Class: db.t3.medium
  - Storage: 100GB (gp3)
  - Multi-AZ: Enabled
  - Backups: 7 days retention
  - Encryption: Enabled
```

### 🔐 **Security & Access**

#### **IAM Roles**
```yaml
IAM Console:
  - honeyhive-eks-cluster-{env}
  - honeyhive-eks-nodes-{env}
  - honeyhive-karpenter-{env}
  - honeyhive-eso-{env}
  - honeyhive-twingate-{env}
  - honeyhive-api-{env}
  - honeyhive-workers-{env}
  - honeyhive-monitoring-{env}

Policies:
  - S3 access policies
  - RDS access policies
  - CloudWatch Logs policies
  - KMS encryption policies
  - Cross-account access policies
```

#### **Secrets Manager**
```yaml
Secrets Manager:
  - honeyhive-db-credentials-{env}
  - honeyhive-api-keys-{env}
  - honeyhive-ssl-certificates-{env}
  - honeyhive-encryption-keys-{env}
  - honeyhive-cross-account-{env}

Features:
  - Automatic rotation
  - Cross-account access
  - Audit logging
  - Encryption at rest
```

### 🌐 **Networking**

#### **VPC Configuration**
```yaml
VPC Console:
  - VPC: honeyhive-vpc-{env}
  - Subnets: 6 subnets (3 public, 3 private)
  - Route Tables: 6 route tables
  - Internet Gateway: honeyhive-igw-{env}
  - NAT Gateway: honeyhive-nat-{env}
  - VPC Endpoints: S3, ECR, EKS
  - Security Groups: 6 security groups
```

#### **Load Balancer**
```yaml
EC2 Load Balancer:
  - Application Load Balancer: honeyhive-alb-{env}
  - Target Groups: honeyhive-tg-{env}
  - Listeners: HTTPS (443)
  - SSL Certificate: honeyhive-ssl-{env}
  - Health Checks: Configured
  - Access Logs: Enabled
```

### 📊 **Monitoring & Logging**

#### **CloudWatch**
```yaml
CloudWatch Console:
  - Log Groups: honeyhive-{env}-*
  - Metrics: EKS, RDS, S3, ALB
  - Dashboards: honeyhive-{env}-dashboard
  - Alarms: honeyhive-{env}-alarms
  - Insights: honeyhive-{env}-insights

Log Groups:
  - /aws/eks/honeyhive-{env}/cluster
  - /aws/eks/honeyhive-{env}/application
  - /aws/rds/honeyhive-db-{env}
  - /aws/loadbalancer/honeyhive-alb-{env}
```

#### **KMS Encryption**
```yaml
KMS Console:
  - Key: honeyhive-encryption-{env}
  - Alias: honeyhive-{env}
  - Usage: S3, RDS, EBS, Secrets Manager
  - Rotation: Annual
  - Audit: CloudTrail enabled
  - Cross-account: Configured
```

## Resource Naming Convention

### 📋 **Naming Pattern**
```yaml
Pattern: honeyhive-{service}-{env}-{region}
Examples:
  - honeyhive-vpc-test-usw2
  - honeyhive-eks-test-usw2
  - honeyhive-db-test-usw2
  - honeyhive-metrics-test-usw2
  - honeyhive-alb-test-usw2
```

### 🏷️ **Resource Tags**
```yaml
Standard Tags:
  - Organization: honeyhive
  - Environment: {env}
  - Service: {service}
  - Region: {region}
  - Deployment: {deployment}
  - ManagedBy: terraform
  - CostCenter: honeyhive-{env}
  - Backup: required
  - Monitoring: enabled
```

## Cost Breakdown

### 💰 **Monthly AWS Costs**

#### **Compute Resources**
```yaml
EKS Cluster:
  - Control Plane: $73/month
  - Worker Nodes (3x t3.large): $150/month
  - ECS Services: $50/month
  - Total Compute: $273/month

Storage:
  - S3 Storage (1.7TB): $40/month
  - RDS Database (100GB): $60/month
  - EBS Volumes: $30/month
  - Total Storage: $130/month

Network:
  - Application Load Balancer: $20/month
  - NAT Gateway: $45/month
  - Data Transfer: $20/month
  - Total Network: $85/month

Security:
  - KMS Key: $1/month
  - Secrets Manager: $5/month
  - Total Security: $6/month

Total Monthly Cost: ~$494/month
```

#### **Scaling Costs**
```yaml
Small (100 users): $500-800/month
Medium (500 users): $1,000-1,500/month
Large (1000+ users): $2,000-3,000/month
Enterprise (5000+ users): $5,000-10,000/month
```

## Operational Dashboard

### 📊 **What You'll Monitor**

#### **AWS Console Dashboards**
```yaml
EKS Dashboard:
  - Cluster health
  - Node status
  - Pod metrics
  - Resource utilization
  - Scaling events

RDS Dashboard:
  - Database performance
  - Connection counts
  - Storage usage
  - Backup status
  - Security events

S3 Dashboard:
  - Storage usage
  - Request metrics
  - Data transfer
  - Cost analysis
  - Lifecycle policies

CloudWatch Dashboard:
  - System metrics
  - Application logs
  - Custom metrics
  - Alert status
  - Cost tracking
```

#### **HoneyHive Dashboards**
```yaml
Application Dashboard:
  - User activity
  - API performance
  - Error rates
  - Response times
  - Throughput metrics

Infrastructure Dashboard:
  - Resource utilization
  - Scaling events
  - Health checks
  - Performance metrics
  - Cost optimization
```

---

*This shows exactly what AWS resources will be created in your account and how they'll appear in the AWS Console.*
