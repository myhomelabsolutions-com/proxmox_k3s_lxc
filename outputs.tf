# Output values

output "k3s_master_ip" {
  value       = proxmox_lxc.k3s_master.hostname
  description = "Hostname of the K3s master node"
}

output "k3s_worker_ips" {
  value       = [for worker in proxmox_lxc.k3s_worker : worker.hostname]
  description = "Hostnames of the K3s worker nodes"
}

output "kubeconfig_command" {
  value       = "ssh ${var.container_user}@${proxmox_lxc.k3s_master.hostname} 'cat /etc/rancher/k3s/k3s.yaml' > kubeconfig.yaml && sed -i 's/127.0.0.1/${proxmox_lxc.k3s_master.hostname}/g' kubeconfig.yaml"
  description = "Command to retrieve and update the kubeconfig file for accessing the K3s cluster"
}