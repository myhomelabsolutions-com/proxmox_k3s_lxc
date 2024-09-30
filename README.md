# K3s Cluster on Proxmox LXC

This project sets up a K3s cluster using Proxmox LXC containers and optionally configures Cloudflare DNS entries. It uses Terraform to automate the infrastructure deployment process.

## Features

- Automated setup of a K3s cluster with 1 master node and 2 worker nodes
- LXC containers based on Debian 12 with zst compression
- Optional Cloudflare DNS configuration for master and worker nodes
- Passwordless SSH access to all nodes

## Prerequisites

- Proxmox VE 7.0 or later with nested virtualization enabled
- Terraform 1.0 or later
- Cloudflare account with API token (if using Cloudflare DNS)
- SSH key pair for passwordless access

## Setup

1. Clone this repository:
   ```
   git clone <repository_url>
   cd <repository_directory>
   ```

2. Update the `terraform.tfvars` file with your specific values:
   - Proxmox host details
   - Cloudflare API token and zone ID (if using Cloudflare DNS)
   - External IP address
   - SSH key path
   - Set `deploy_cloudflare_dns` to `false` if you don't want to deploy Cloudflare DNS entries

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

## Components

- **Proxmox LXC Containers**: Configured with necessary tweaks for K3s compatibility
- **K3s Cluster**: 1 master node and 2 worker nodes
- **Cloudflare DNS** (Optional): Configured with A records for master and worker nodes

### K3s Cluster Configuration

The K3s cluster is configured with specific roles and taints to ensure proper workload distribution:

#### Master Node
- Roles and Labels:
  - etcd role
  - control-plane role
  - master role
- Taint: `node-role.kubernetes.io/master=true:NoSchedule`
  This taint prevents regular workloads from being scheduled on the master node.

#### Worker Nodes
- Label: `node-role.kubernetes.io/worker=true`
- No taints applied, allowing workloads to be scheduled on these nodes

This configuration ensures that:
- The master node is dedicated to cluster management tasks.
- All regular workloads are scheduled on the worker nodes.
- There's a clear separation of responsibilities between master and worker nodes.

## Notes

- The LXC containers are configured to allow nesting and have the necessary tweaks for running K3s
- The master node is assigned VMID 400, and worker nodes are assigned VMIDs 500 and 501
- Each node is configured with 4 cores, 8GB of memory, and a 60GB root filesystem
- Cloudflare DNS entries will not be created if the `deploy_cloudflare_dns` variable is set to `false` in your `terraform.tfvars` file

## Troubleshooting

If you encounter any issues during deployment or usage, please check the following:

1. Ensure Proxmox is properly configured with nested virtualization enabled
2. If using Cloudflare DNS, verify that the Cloudflare API token has the necessary permissions
3. Check the Terraform and Proxmox logs for any error messages

For more detailed information, refer to the individual Terraform configuration files in this repository.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.