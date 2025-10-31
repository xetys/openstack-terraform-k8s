# RKE2 Kubernetes Cluster on OpenStack

Terraform configuration to deploy an RKE2 (Rancher Kubernetes Engine 2) Kubernetes cluster on OpenStack.

## Prerequisites

- Terraform installed
- OpenStack credentials configured
- SSH key pair named "ds" in your OpenStack project (or modify the `key_pair` value in main.tf)
- Access to an OpenStack environment with Ubuntu 24.04 images

## Quick Start

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the cluster
terraform apply

# Get the control plane IP
terraform output instance_ip
```

After deployment, SSH to the control plane node:
```bash
ssh ubuntu@<instance_ip>
```

Access the cluster:
```bash
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH="/var/lib/rancher/rke2/bin:$PATH"
kubectl get nodes
```

## Configuration

### Main Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `number_workers` | "3" | Number of worker nodes |
| `control_plane_flavor` | "m1.medium" | OpenStack flavor for control plane |
| `worker_flavor` | "m1.medium" | OpenStack flavor for workers |
| `public_network` | "ext-net" | External network name |
| `rke2_version` | "v1.31.1+rke2r1" | RKE2 version to install |
| `install_rke2` | true | Whether to install RKE2 (set to false for base infrastructure only) |

### Examples

Scale workers:
```bash
terraform apply -var="number_workers=5"
```

Deploy without RKE2 (infrastructure only):
```bash
terraform apply -var="install_rke2=false"
```

Use different flavors:
```bash
terraform apply -var="control_plane_flavor=m1.large" -var="worker_flavor=m1.small"
```

## Architecture

- 1 control plane node with external floating IP
- N worker nodes (configurable)
- Private network (192.168.1.0/24)
- Security groups for SSH, HTTP/HTTPS, Kubernetes API, and RKE2 communication

## Cleanup

```bash
terraform destroy
```