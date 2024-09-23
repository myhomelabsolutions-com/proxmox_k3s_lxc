output "k3s_node_ips" {
  description = "IP addresses of the k3s nodes"
  value       = {for node in proxmox_lxc.k3s_node : node.hostname => node.network[0].ip}
}

output "k3s_node_hostnames" {
  description = "Hostnames of the k3s nodes"
  value       = proxmox_lxc.k3s_node[*].hostname
}

output "cloudflare_dns_records" {
  description = "Cloudflare DNS records for k3s nodes"
  value       = {for record in cloudflare_record.k3s_dns : record.name => record.value}
}

output "k3s_master_hostname" {
  description = "Hostname of the k3s master node"
  value       = proxmox_lxc.k3s_node[0].hostname
}

output "k3s_worker_hostnames" {
  description = "Hostnames of the k3s worker nodes"
  value       = slice(proxmox_lxc.k3s_node[*].hostname, 1, length(proxmox_lxc.k3s_node))
}

output "public_ipv4" {
  description = "Public IPv4 address used for Cloudflare DNS records"
  value       = chomp(data.http.public_ipv4.response_body)
}