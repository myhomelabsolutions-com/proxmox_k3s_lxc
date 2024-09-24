# Proxmox host configuration

resource "null_resource" "proxmox_config" {
  connection {
    type     = "ssh"
    user     = var.proxmox_user
    password = var.proxmox_password
    host     = var.proxmox_host
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.conf",
      "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf",
      "sysctl -p",
      "modprobe br_netfilter",
      "echo 'br_netfilter' >> /etc/modules-load.d/modules.conf",
      "echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.d/99-kubernetes-cri.conf",
      "echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.d/99-kubernetes-cri.conf",
      "echo 'net.bridge.bridge-nf-call-ip6tables = 1' >> /etc/sysctl.d/99-kubernetes-cri.conf",
      "sysctl --system",
    ]
  }
}


output "proxmox_config_id" {
  value       = null_resource.proxmox_config.id
  description = "ID of the Proxmox configuration resource"
}