# Proxmox K3s Deployment

This project automates the deployment of a K3s cluster on Proxmox LXC containers using Terraform and Ansible.

## Prerequisites

1. Proxmox server set up and accessible
2. Terraform installed on your local machine
3. Ansible installed on your local machine
4. Cloudflare account for DNS management

## Setup

1. Clone this repository to your local machine.

2. Configure the `terraform/terraform.tfvars` file with your specific settings:
   - Proxmox API URL
   - Proxmox credentials
   - Cloudflare API token and zone ID
   - Domain name
   - Other LXC container settings

3. Initialize Terraform:
   ```
   make init
   ```

4. Review the planned changes:
   ```
   make plan
   ```

5. Apply the Terraform configuration to create the infrastructure:
   ```
   make apply
   ```

6. Once the infrastructure is created, provision the K3s cluster:
   ```
   make provision
   ```

## Usage

- To create the infrastructure and install K3s in one step:
  ```
  make k3s-install
  ```

- To uninstall K3s:
  ```
  make k3s-uninstall
  ```

- To destroy the infrastructure:
  ```
  make destroy
  ```

## Accessing the Cluster

After successful deployment, you can access:
- ArgoCD UI at `https://argocd.<your-domain>`
- Your applications through the Nginx ingress controller

## Troubleshooting

If you encounter any issues, please check the Terraform and Ansible logs for error messages. Ensure that all prerequisites are met and that the Proxmox host is properly configured.

Common issues:
1. Ensure that the Proxmox host allows SSH access for the user specified in `terraform.tfvars`.
2. Verify that the Proxmox API is accessible and that the credentials are correct.
3. Check that the LXC template specified in `terraform.tfvars` exists on your Proxmox host.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.