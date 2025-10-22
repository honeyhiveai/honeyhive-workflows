# HoneyHive AWS Resources Specification

## What Gets Created in Your AWS Account

### 🏗️ **Core Infrastructure Resources**

#### **VPC & Networking**
```yaml
VPC:
  - 1 VPC (10.x.0.0/16)
  - 3 Public Subnets (across AZs)
  - 3 Private Subnets (across AZs)
  - 1 Internet Gateway
  - 1 NAT Gateway
  - 6 Route Tables
  - 6 Security Groups
  - 3 VPC Endpoints (S3, ECR, EKS)

DNS:
  - 1 Private Hosted Zone
  - 1 Public Hosted Zone (optional)
  - SSL/TLS Certificates (ACM)
```

#### **EKS Cluster**
```yaml
EKS:
  - 1 EKS Cluster
  - 1 Node Group (initial)
  - 1 Karpenter Node Pool
  - 1 OIDC Identity Provider
  - 2 IAM Roles (Cluster + Node)
  - 1 Security Group (Cluster)
  - 1 Security Group (Node)
```

### 🚀 **Application Services**

#### **HoneyHive Core Services**
```yaml
API Services:
  - HoneyHive API (Deployment)
  - HoneyHive UI (Deployment)
  - Background Workers (Deployment)
  - Webhook Handlers (Deployment)

Ingress:
  - 1 Application Load Balancer
  - 1 Ingress Controller
  - 1 SSL Certificate
  - 1 Target Group
```

#### **Observability Stack**
```yaml
Monitoring:
  - Prometheus (Deployment)
  - Grafana (Deployment)
  - AlertManager (Deployment)
  - Node Exporter (DaemonSet)

Logging:
  - Fluent Bit (DaemonSet)
  - Log Aggregator (Deployment)
  - Log Storage (S3)

Tracing:
  - OpenTelemetry Collector (Deployment)
  - Jaeger (Deployment)
  - Trace Storage (S3)
```

### 🗄️ **Data Storage**

#### **S3 Buckets**
```yaml
Storage:
  - honeyhive-metrics-{env}-{region} (Prometheus data)
  - honeyhive-logs-{env}-{region} (Application logs)
  - honeyhive-backups-{env}-{region} (Database backups)
  - honeyhive-config-{env}-{region} (Configuration files)
  - honeyhive-artifacts-{env}-{region} (Build artifacts)

Encryption:
  - KMS Customer Managed Key
  - Server-side encryption (SSE-S3)
  - Bucket versioning enabled
  - Lifecycle policies configured
```

#### **Database Services**
```yaml
RDS PostgreSQL:
  - 1 DB Instance (db.t3.medium)
  - 1 DB Subnet Group
  - 1 DB Parameter Group
  - 1 DB Security Group
  - 1 DB Option Group
  - Automated backups (7 days)
  - Multi-AZ deployment (optional)

Redis:
  - 1 ElastiCache Cluster
  - 1 Subnet Group
  - 1 Security Group
  - Encryption in transit
  - Encryption at rest
```

### 🔐 **Security & Access**

#### **IAM Roles & Policies**
```yaml
Service Roles:
  - EKS Cluster Service Role
  - EKS Node Group Role
  - Karpenter Node Role
  - External Secrets Operator Role
  - Twingate ECS Task Role
  - HoneyHive Application Roles (3)

Policies:
  - S3 Access Policies
  - RDS Access Policies
  - CloudWatch Logs Policies
  - KMS Encryption Policies
  - Cross-Account Access Policies
```

#### **Secrets Management**
```yaml
AWS Secrets Manager:
  - Database credentials
  - API keys and tokens
  - SSL certificates
  - Encryption keys
  - Cross-account access policies

KMS:
  - Customer Managed Key
  - Key rotation enabled
  - Cross-account access
  - Audit logging enabled
```

### 🌐 **VPN & Access**

#### **Twingate Integration**
```yaml
ECS Services:
  - Twingate Connector (Fargate)
  - Twingate Resource (Terraform)
  - Twingate Group (Terraform)
  - Twingate User (Terraform)

Network:
  - Security Groups
  - Load Balancer Target Group
  - Health Checks
  - Logging Configuration
```

## Resource Sizing & Costs

### 📊 **Default Configuration**

#### **Compute Resources**
```yaml
EKS Cluster:
  - Control Plane: Managed by AWS
  - Worker Nodes: 3 nodes (t3.large)
  - Storage: 100GB per node (gp3)
  - Auto-scaling: 3-50 nodes

ECS Services:
  - Twingate Connector: 0.5 vCPU, 1GB RAM
  - Background Workers: 2 vCPU, 4GB RAM
  - API Services: 4 vCPU, 8GB RAM
```

#### **Storage Resources**
```yaml
S3 Storage:
  - Metrics: 1TB initial
  - Logs: 500GB initial
  - Backups: 200GB initial
  - Total: ~1.7TB initial

RDS Storage:
  - Database: 100GB (gp3)
  - Backups: 7 days retention
  - Snapshots: Automated
```

#### **Network Resources**
```yaml
Load Balancer:
  - Application Load Balancer
  - 1 Target Group
  - SSL Certificate
  - Health Checks

NAT Gateway:
  - 1 NAT Gateway
  - Elastic IP
  - Data processing charges
```

### 💰 **Estimated Monthly Costs**

#### **Small Deployment (100 users)**
```yaml
Compute:
  - EKS Cluster: $73/month
  - Worker Nodes: $150/month
  - ECS Services: $50/month
  - Total Compute: $273/month

Storage:
  - S3 Storage: $40/month
  - RDS Database: $60/month
  - Total Storage: $100/month

Network:
  - Load Balancer: $20/month
  - NAT Gateway: $45/month
  - Data Transfer: $20/month
  - Total Network: $85/month

Total: ~$458/month
```

#### **Medium Deployment (500 users)**
```yaml
Compute:
  - EKS Cluster: $73/month
  - Worker Nodes: $400/month
  - ECS Services: $150/month
  - Total Compute: $623/month

Storage:
  - S3 Storage: $150/month
  - RDS Database: $120/month
  - Total Storage: $270/month

Network:
  - Load Balancer: $20/month
  - NAT Gateway: $45/month
  - Data Transfer: $50/month
  - Total Network: $115/month

Total: ~$1,008/month
```

#### **Large Deployment (1000+ users)**
```yaml
Compute:
  - EKS Cluster: $73/month
  - Worker Nodes: $800/month
  - ECS Services: $300/month
  - Total Compute: $1,173/month

Storage:
  - S3 Storage: $400/month
  - RDS Database: $300/month
  - Total Storage: $700/month

Network:
  - Load Balancer: $20/month
  - NAT Gateway: $45/month
  - Data Transfer: $100/month
  - Total Network: $165/month

Total: ~$2,038/month
```

## Security & Compliance

### 🔐 **Data Protection**

#### **Encryption**
```yaml
At Rest:
  - S3: AES-256 encryption
  - RDS: AES-256 encryption
  - EBS: AES-256 encryption
  - KMS: Customer managed keys

In Transit:
  - TLS 1.3 for all communications
  - HTTPS for all web traffic
  - Database connections encrypted
  - API communications encrypted
```

#### **Access Control**
```yaml
Authentication:
  - Multi-factor authentication
  - SSO integration
  - RBAC implementation
  - Session management

Authorization:
  - IAM roles and policies
  - Kubernetes RBAC
  - Network security groups
  - API rate limiting
```

### 🛡️ **Network Security**

#### **Network Isolation**
```yaml
VPC Configuration:
  - Private subnets for all workloads
  - Public subnets for load balancers only
  - NAT Gateway for outbound access
  - VPC Endpoints for AWS services

Security Groups:
  - Web tier: HTTPS (443) only
  - Application tier: Internal communication
  - Database tier: Application access only
  - Monitoring tier: Metrics collection
```

#### **VPN Access**
```yaml
Twingate Configuration:
  - Secure VPN connection
  - User authentication
  - Network segmentation
  - Audit logging
  - Session management
```

## Operational Requirements

### 🔧 **AWS Account Setup**

#### **Prerequisites**
```yaml
Account Requirements:
  - AWS Account with admin access
  - Billing configured
  - Service limits increased
  - Support plan (Business or Enterprise)

Permissions:
  - Cross-account access
  - Service role creation
  - Resource tagging
  - CloudFormation access
```

#### **Service Limits**
```yaml
Required Limits:
  - EKS Clusters: 1
  - VPCs: 1
  - NAT Gateways: 1
  - Load Balancers: 1
  - RDS Instances: 1
  - S3 Buckets: 5
  - KMS Keys: 1
```

### 📊 **Monitoring & Alerting**

#### **CloudWatch Integration**
```yaml
Metrics:
  - EKS cluster metrics
  - RDS performance metrics
  - S3 storage metrics
  - Load balancer metrics
  - Custom application metrics

Logs:
  - EKS cluster logs
  - Application logs
  - Security logs
  - Audit logs
  - Performance logs
```

#### **Alerting**
```yaml
Critical Alerts:
  - Cluster health
  - Database connectivity
  - Storage capacity
  - Security events
  - Performance degradation

Notification Channels:
  - Email alerts
  - Slack integration
  - PagerDuty integration
  - SMS notifications
```

## Deployment Process

### 🚀 **Initial Setup**

#### **Phase 1: Infrastructure**
```yaml
Week 1:
  - AWS account preparation
  - VPC and networking setup
  - Security groups configuration
  - IAM roles and policies
  - KMS key creation
```

#### **Phase 2: Platform**
```yaml
Week 2:
  - EKS cluster deployment
  - Node group configuration
  - Karpenter setup
  - Core services deployment
  - Monitoring stack installation
```

#### **Phase 3: Application**
```yaml
Week 3:
  - HoneyHive services deployment
  - Database setup
  - S3 bucket configuration
  - VPN access setup
  - User authentication
```

#### **Phase 4: Testing**
```yaml
Week 4:
  - End-to-end testing
  - Performance validation
  - Security testing
  - User acceptance testing
  - Go-live preparation
```

### 🔄 **Ongoing Operations**

#### **Maintenance**
```yaml
Daily:
  - System monitoring
  - Backup verification
  - Security scanning
  - Performance monitoring

Weekly:
  - Security updates
  - Performance optimization
  - Capacity planning
  - Documentation updates

Monthly:
  - Disaster recovery testing
  - Security audit
  - Cost optimization
  - Feature updates
```

---

*This specification provides complete details on what AWS resources will be created in your account for HoneyHive deployment.*
