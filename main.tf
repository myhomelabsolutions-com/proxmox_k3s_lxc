resource "proxmox_lxc" "k3s_node" {
  # ... (existing configuration)

  provisioner "remote-exec" {
    inline = [
      "modprobe br_netfilter",
      "modprobe overlay",
      "echo '#!/bin/sh -e' > /etc/rc.local",
      "echo 'if [ ! -e /dev/kmsg ]; then ln -s /dev/console /dev/kmsg; fi' >> /etc/rc.local",
      "echo 'mount --make-rshared /' >> /etc/rc.local",
      "chmod 755 /etc/rc.local",
      "wget -O /tmp/k3s-install.sh https://get.k3s.io",
      "chmod 700 /tmp/k3s-install.sh",
    ]
  }
}

resource "null_resource" "k3s_master" {
  count = var.master_count

  provisioner "remote-exec" {
    inline = [
      "INSTALL_K3S_EXEC='server --node-external-ip=${proxmox_lxc.k3s_node[count.index].ip}' /tmp/k3s-install.sh",
      "cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token",
    ]
  }

  connection {
    type     = "ssh"
    user     = var.lxc_user
    password = var.lxc_password
    host     = proxmox_lxc.k3s_node[count.index].ip
  }

  depends_on = [proxmox_lxc.k3s_node]
}

resource "null_resource" "k3s_worker" {
  count = var.worker_count

  provisioner "remote-exec" {
    inline = [
      "K3S_URL='https://${proxmox_lxc.k3s_node[0].ip}:6443' K3S_TOKEN='${file("/tmp/node-token")}' /tmp/k3s-install.sh",
    ]
  }

  connection {
    type     = "ssh"
    user     = var.lxc_user
    password = var.lxc_password
    host     = proxmox_lxc.k3s_node[count.index + var.master_count].ip
  }

  depends_on = [null_resource.k3s_master]
}

resource "null_resource" "configure_kubectl" {
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /root/.kube",
      "cp /etc/rancher/k3s/k3s.yaml /root/.kube/config",
      "sed -i 's/127.0.0.1/${proxmox_lxc.k3s_node[0].ip}/' /root/.kube/config",
      "kubectl get nodes",
    ]
  }

  connection {
    type     = "ssh"
    user     = var.lxc_user
    password = var.lxc_password
    host     = proxmox_lxc.k3s_node[0].ip
  }

  depends_on = [null_resource.k3s_worker]
}# ... (rest of the file)
