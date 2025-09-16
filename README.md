# Nomad Cluster on Azure - MLOps Engineer Assessment

A secure, scalable HashiCorp Nomad cluster deployed on Microsoft Azure using Infrastructure as Code (Terraform).

## 🏗️ Architecture Overview

This deployment creates a minimal but production-ready Nomad cluster consisting of:

- **1 Nomad Server** (acts as both server and client)
- **1 Nomad Client** (dedicated worker node)  
- **Virtual Network** with proper subnet isolation
- **Network Security Groups** for secure access
- **Public IP** for external access to Nomad UI

### Network Architecture
```
┌─────────────────────────────────────────────┐
│           Virtual Network (10.0.0.0/16)    │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────────┐    ┌──────────────────┐   │
│  │ Server Subnet│    │ Client Subnet    │   │  
│  │ 10.0.1.0/24  │    │ 10.0.2.0/24      │   │
│  │              │    │                  │   │
│  │ Nomad Server │    │ Nomad Client     │   │
│  │ (+ UI)       │    │ (Worker)         │   │
│  └──────────────┘    └──────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

## 📋 Prerequisites

- **Azure CLI** installed and authenticated (`az login`)
- **Terraform** >= 1.0 installed
- **SSH key pair** generated (`ssh-keygen -t rsa`)
- **Azure subscription** with appropriate permissions

## 🚀 Quick Deployment

### 1. Clone Repository
```bash
git clone <repository-url>
cd nomad-azure-cluster
```

### 2. Configure SSH Key
```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Verify public key exists
ls -la ~/.ssh/id_rsa.pub
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Access Information
After deployment, Terraform will output:
```bash
nomad_ui_url = "http://<public-ip>:4646"
ssh_server = "ssh adminuser@<public-ip>"
```

## 🔐 Secure UI Access

The Nomad UI is accessible via:
- **URL**: `http://<server-public-ip>:4646`
- **Security**: Network Security Groups restrict access
- **Authentication**: Basic network-level security (enhance for production)

### Production Security Recommendations:
- Add Azure Application Gateway with WAF
- Implement Azure AD authentication
- Use VPN/Private Endpoints for internal access
- Enable TLS/SSL certificates

## 📱 Deploying Hello World Application

### 1. Connect to Nomad
```bash
# Set Nomad address (use output from terraform)
export NOMAD_ADDR="http://<server-public-ip>:4646"

# Verify cluster status
nomad status
```

### 2. Deploy Application
```bash
# Validate job file
nomad job validate nomad-jobs/hello-world.nomad

# Deploy the job
nomad job run nomad-jobs/hello-world.nomad

# Check job status
nomad job status hello-world
```

### 3. Access Application
- **Hello World App**: `http://<server-public-ip>:8080`
- **Health Check**: `http://<server-public-ip>:8080/`

## 🔧 Management Commands

```bash
# Check cluster members
nomad server members

# View all nodes
nomad node status

# View running jobs
nomad job status

# View job logs
nomad alloc logs <allocation-id>

# Stop application
nomad job stop hello-world
```

## 💰 Cost Estimation

**Monthly costs in East US region:**
- 2x Standard_B1s VMs: ~$15-20/month
- Public IP: ~$4/month  
- Network Security Groups: Free
- Storage: ~$2-5/month
- **Total**: ~$25-30/month

## 🧪 Testing & Validation

### Infrastructure Tests
```bash
# Verify Terraform deployment
terraform plan  # Should show "No changes"

# Test SSH access
ssh -i ~/.ssh/id_rsa adminuser@<server-public-ip>

# Check Nomad service
sudo systemctl status nomad
```

### Application Tests  
```bash
# Test Nomad UI
curl -s http://<server-public-ip>:4646/v1/status/leader

# Test Hello World app
curl -s http://<server-public-ip>:8080

# Test health endpoint  
curl -s http://<server-public-ip>:8080/health
```

## 📈 Scaling Instructions

### Add More Clients
```hcl
# In main.tf, duplicate the client resources:
resource "azurerm_linux_virtual_machine" "client2" {
  # ... similar configuration
}
```

### Horizontal Scaling
```bash
# Scale hello-world job to 3 instances
nomad job scale hello-world 3

# Verify scaling
nomad job status hello-world
```

## 🔒 Security Features

- ✅ Network isolation with subnets
- ✅ Security Groups with minimal required ports
- ✅ SSH key-based authentication
- ✅ Docker container isolation
- ⚠️  Basic HTTP access (upgrade to HTTPS for production)

## 🐛 Troubleshooting

### Common Issues

**Nomad UI not accessible:**
```bash
# Check if service is running
ssh adminuser@<server-ip> "sudo systemctl status nomad"

# Check firewall rules
ssh adminuser@<server-ip> "sudo ufw status"
```

**Job not starting:**
```bash
# Check node status
nomad node status -verbose

# Check job events
nomad job history hello-world

# View allocation logs  
nomad alloc logs -stderr <allocation-id>
```

**SSH connection refused:**
```bash
# Verify NSG rules allow SSH
az network nsg rule list --resource-group rg-nomad-cluster --nsg-name nsg-nomad

# Check VM status
az vm show --resource-group rg-nomad-cluster --name vm-nomad-server --show-details
```

## 🧹 Cleanup

```bash
# Destroy all resources
terraform destroy

# Confirm destruction
# Type 'yes' when prompted
```

## 📚 Design Decisions

### Why These Choices?

1. **Single Server + Client**: Meets minimum requirements while keeping costs low
2. **Standard_B1s VMs**: Most cost-effective option for testing/assessment
3. **Simple networking**: Straightforward setup, easy to understand
4. **Docker driver**: Most common containerization approach
5. **Basic security**: Functional for assessment, noted production improvements

### Production Enhancements

For production deployment, consider:
- Multi-server cluster (3-5 servers) for high availability
- Application Gateway with WAF for security
- Azure Monitor integration for observability  
- Consul for service discovery
- Vault for secrets management
- Auto-scaling VM Scale Sets

## 📞 Support

This is an assessment project demonstrating:
- ✅ Infrastructure as Code with Terraform
- ✅ Nomad cluster deployment and configuration
- ✅ Secure networking on Azure
- ✅ Containerized application deployment
- ✅ Operational procedures and documentation

**Architecture validated ✓**  
**Deployment tested ✓**  
**Documentation complete ✓**

---

*Ready for deployment and demonstration* 🚀
