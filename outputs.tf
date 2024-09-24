# Output values

output "k3s_master_ip" {
  value       = proxmox_lxc.k3s_master.hostname
  description = "Hostname of the K3s master node"
}

output "k3s_worker_ips" {
  value       = [for worker in proxmox_lxc.k3s_worker : worker.hostname]
  description = "Hostnames of the K3s worker nodes"
}

output "argocd_url" {
  value       = "https://argocd.${var.domain_name}"
  description = "URL to access ArgoCD web interface"
}

output "argocd_initial_password_command" {
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
  description = "Command to retrieve the initial ArgoCD admin password"
}

output "wildcard_domain" {
  value       = "*.${var.domain_name}"
  description = "Wildcard domain for deploying applications"
}

output "kubeconfig_command" {
  value       = "ssh ${var.container_user}@${proxmox_lxc.k3s_master.hostname} 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig.yaml && sed -i 's/127.0.0.1/${proxmox_lxc.k3s_master.hostname}/g' kubeconfig.yaml"
  description = "Command to retrieve and update the kubeconfig file for accessing the K3s cluster"
}