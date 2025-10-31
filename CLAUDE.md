# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains Terraform configuration for deploying an RKE2 (Rancher Kubernetes Engine 2) Kubernetes cluster on OpenStack. The infrastructure consists of:
- A single control plane node with a floating IP for external access
- Multiple worker nodes (configurable, default 3)
- Private networking with security groups
- Cloud-init based RKE2 installation

## Architecture

The deployment is structured across three main Terraform files:

**main.tf**: Core compute resources and cluster configuration
- Control plane instance with templated cloud-init (server.cfg)
- Worker instances with templated cloud-init (agent.cfg)
- Floating IP allocation and association for control plane
- Random token generation for RKE2 cluster authentication
- Uses Ubuntu 24.04 images from OpenStack

**network.tf**: All networking infrastructure
- Private network (192.168.1.0/24) for cluster internal communication
- Router connecting private network to external network
- Security groups with rules for:
  - SSH (22), HTTP (80), HTTPS (443)
  - Kubernetes API (6443)
  - RKE2 supervisor port (9345, internal only)
  - ICMP

**versions.tf**: Terraform provider configuration for OpenStack

**Cloud-init templates**:
- `server.cfg`: Control plane node initialization (installs RKE2 server, k9s)
- `agent.cfg`: Worker node initialization (installs RKE2 agent, connects to control plane)

## Common Commands

### Initialize and validate
```bash
terraform init                 # Initialize providers
terraform validate             # Validate configuration
terraform fmt                  # Format all .tf files
```

### Deploy cluster
```bash
terraform plan                 # Preview changes
terraform apply                # Deploy infrastructure
terraform apply -auto-approve  # Deploy without confirmation
```

### Manage infrastructure
```bash
terraform destroy              # Destroy all resources
terraform state list           # List all resources in state
terraform output               # Show all outputs
terraform output instance_ip   # Show control plane IP
```

### Scale workers
```bash
terraform apply -var="number_workers=5"  # Scale to 5 workers
```

### Provision nodes without RKE2
```bash
terraform apply -var="install_rke2=false"  # Deploy only base infrastructure
```

## Key Variables

- `number_workers`: Number of worker nodes (default: "3")
- `control_plane_flavor`: OpenStack flavor for control plane (default: "m1.medium")
- `worker_flavor`: OpenStack flavor for workers (default: "m1.medium")
- `public_network`: External network name (default: "ext-net")
- `rke2_version`: RKE2 version to install (default: "v1.31.1+rke2r1")
- `install_rke2`: Whether to install RKE2 on nodes (default: true). Set to false to provision only base infrastructure without Kubernetes.

## Important Implementation Notes

**Hard-coded key pair**: The SSH key pair is hard-coded as "ds" in main.tf:58 and main.tf:77. When modifying or adapting this code, update the `key_pair` attribute to match the target OpenStack environment.

**Token security**: The RKE2 cluster token is generated randomly and output in plaintext. This is visible in Terraform state and outputs.

**Cloud-init dependencies**: The control plane must be fully initialized before workers can join. The RKE2 server needs to be running on port 9345 before agents attempt connection. Terraform handles resource dependencies, but timing issues can occur if the control plane installation is slow.

**Floating IP allocation**: The floating IP is allocated before the control plane instance but associated after creation via port lookup. This ensures the external IP is available for cloud-init templating.

**Network topology**: Worker nodes communicate with the control plane via private network (192.168.1.0/24). The control plane is accessible externally via floating IP. Port 9345 is restricted to the internal subnet.