# K3s Cluster on Proxmox LXC with ArgoCD

This project sets up a highly available K3s cluster using Proxmox LXC containers, installs ArgoCD, and configures Cloudflare DNS entries. It uses Terraform to automate the entire infrastructure deployment process.

## Features

- Automated setup of a K3s cluster with 1 master node and 2 worker nodes
- LXC containers based on Ubuntu 24.04 with zst compression
- ArgoCD installation and configuration
- Nginx Ingress Controller for exposing applications
- Automatic SSL certificate generation using Let's Encrypt and cert-manager
- Cloudflare DNS configuration with wildcard subdomain support
- Passwordless SSH access to all nodes

## Prerequisites

- Proxmox VE 7.0 or later with nested virtualization enabled
- Terraform 1.0 or later
- Cloudflare account with API token
- SSH key pair for passwordless access

## Setup

1. Clone this repository:
   ```
   git clone <repository_url>
   cd <repository_directory>
   ```

2. Update the `terraform.tfvars` file with your specific values:
   - Proxmox host details
   - Cloudflare API token and zone ID
   - Domain name
   - SSH key path

3. Initialize Terraform:
   ```
   terraform init
   ```

4. Review the planned changes:
   ```
   terraform plan
   ```

5. Apply the Terraform configuration:
   ```
   terraform apply
   ```
   Or use the provided Makefile:
   ```
   make deploy
   ```

## Usage

### Makefile Commands

- `make`: Display available commands
- `make deploy`: Initialize, format, and apply Terraform configuration
- `make destroy`: Destroy the provisioned resources

### Accessing the Cluster

After successful deployment, use the following command to get the kubeconfig file:

```
$(terraform output -raw kubeconfig_command)
```

Then, set the KUBECONFIG environment variable:

```
export KUBECONFIG=./kubeconfig.yaml
```

Now you can use kubectl to interact with your K3s cluster.

### Accessing ArgoCD

ArgoCD UI will be available at `https://argocd.<your_domain>`. To get the initial admin password, run:

```
$(terraform output -raw argocd_initial_password_command)
```

## Components

- **Proxmox LXC Containers**: Configured with necessary tweaks for K3s compatibility
- **K3s Cluster**: 1 master node and 2 worker nodes
- **ArgoCD**: Installed and configured for GitOps workflows
- **Nginx Ingress Controller**: For exposing applications
- **cert-manager**: For automatic SSL certificate generation
- **Cloudflare DNS**: Configured with A records for nodes and a wildcard record

## Notes

- The LXC containers are configured to allow nesting and have the necessary tweaks for running K3s
- SSL certificates are generated automatically using Let's Encrypt and cert-manager
- All applications deployed will use the same Nginx ingress to expose services using prefixes
- A wildcard DNS record is created to support easy deployment of new applications

## Troubleshooting

If you encounter any issues during deployment or usage, please check the following:

1. Ensure Proxmox is properly configured with nested virtualization enabled
2. Verify that the Cloudflare API token has the necessary permissions
3. Check the Terraform and Proxmox logs for any error messages

For more detailed information, refer to the individual Terraform configuration files in this repository.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.