# Network Virtual Appliance (NVA) Deployment

This repository contains Bicep templates for deploying a Network Virtual Appliance (NVA) in Azure.

## Overview

The template deploys an Ubuntu-based Network Virtual Appliance with the following components:
- Ubuntu 22.04 LTS virtual machine
- Virtual Network with DMZ and workload subnets
- Network Security Group with SSH access
- Public IP address
- Network Interface with IP forwarding enabled
- Route Table for traffic routing through the NVA

## Resources Deployed

- **Virtual Machine**: Ubuntu 22.04 LTS with TrustedLaunch security
- **Virtual Network**: 10.0.0.0/16 address space with:
  - DMZ subnet (10.0.0.0/24) - where the NVA resides
  - Workload subnet (10.0.1.0/24) - for application workloads
- **Network Security Group**: Allows SSH access (port 22)
- **Public IP Address**: Static allocation
- **Network Interface**: Configured with IP forwarding for NVA functionality
- **Route Table**: Routes traffic (0.0.0.0/0) through the NVA

## Deployment Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| nvaVMNic_name | Name of the NVA network interface | nva_nic |
| nvaNSG_name | Name of the Network Security Group | nva_NSG |
| nvaPublicIP_name | Name of the public IP address | nva_public_ip |
| nva_name | Name of the virtual machine | ubuntu |
| vnet_name | Name of the virtual network | VNET |
| routeTable_name | Name of the route table | nva-route-table |
| location | Azure region for deployment | eastus |
| nva_username | Admin username for the VM | localadmin |
| nva_password | Admin password for the VM | *secure parameter* |

## Deployment Instructions

To deploy this template, use the following Azure CLI command:

```bash
az deployment group create --resource-group rg_eastus_hub --template-file nva.bicep --parameters @nva.parameters.json
```

## Security Considerations

- The template enables SSH access from any source IP address. For production environments, restrict this to specific IP ranges.
- The VM is configured with password authentication. Consider using SSH keys for enhanced security.
- IP forwarding is enabled on the network interface to support NVA functionality.

## VM Specifications

- Size: Standard_B2s
- OS Disk: 30GB Premium SSD
- Security: TrustedLaunch with Secure Boot and vTPM enabled

## Network Configuration

- The NVA is deployed in a DMZ subnet (10.0.0.0/24) with a static IP (10.0.0.4)
- A workload subnet (10.0.1.0/24) is provided for application workloads
- IP forwarding is enabled to allow the VM to route traffic between networks
- A public IP is assigned for management access
- A route table directs all traffic (0.0.0.0/0) through the NVA

## Post-Deployment Configuration

After deployment, you'll need to:

1. Configure IP forwarding on the Ubuntu VM:
   ```bash
   # Enable IP forwarding
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
   
   # Configure iptables for NAT
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   ```

2. Install any additional security or networking software required for your NVA functionality