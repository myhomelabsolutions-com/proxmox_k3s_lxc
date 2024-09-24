terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.11"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "proxmox" {
  pm_api_url = var.proxmox_api_url
  pm_user = var.proxmox_user
  pm_password = var.proxmox_password
  pm_tls_insecure = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

data "http" "public_ipv4" {
  url = "https://ipv4.icanhazip.com"
}

resource "proxmox_lxc" "k3s_node" {
  count = var.node_count
  target_node = var.proxmox_node
  hostname = "k3s-node-${count.index + 1}"
  ostemplate = var.lxc_template
  password = var.lxc_password
  unprivileged = false
  features {
    nesting = true
    keyctl = true
  }

  cores = var.lxc_cores
  memory = var.lxc_memory
  swap = 0 # Disable swap
  start = true

  network {
    name = "k3s-net"
    bridge = "vmbr0"
    ip = "dhcp"
  }

  rootfs {
    storage = var.lxc_storage
    size = var.lxc_disk_size
  }

  ssh_public_keys = file(var.ssh_public_key_file)

  // Configure LXC container settings
  provisioner "remote-exec" {
    inline = [
      "echo 'overlay' >> /etc/modules",
      "mount --make-rshared /",
      "echo \"lxc.apparmor.profile=unconfined\" >> /etc/lxc/default.conf",
      "echo \"lxc.cgroup.devices.allow=a\" >> /etc/lxc/default.conf",
      "echo \"lxc.cap.drop=\" >> /etc/lxc/default.conf",
      "echo \"lxc.mount.auto=proc:rw sys:rw\" >> /etc/lxc/default.conf",
      "echo \"#!/bin/sh -e\" >> /etc/rc.local",
      "echo \"\" >> /etc/rc.local",
      "echo \"# Kubeadm 1.15 needs /dev/kmsg to be there, but it's not in lxc, but we can just use /dev/console instead\" >> /etc/rc.local",
      "echo \"# see: https://github.com/kubernetes-sigs/kind/issues/662\" >> /etc/rc.local",
      "echo \"if [ ! -e /dev/kmsg ]; then\" >> /etc/rc.local",
      "echo \"    ln -s /dev/console /dev/kmsg\" >> /etc/rc.local",
      "echo \"fi\" >> /etc/rc.local",
      "echo \"\" >> /etc/rc.local",
      "echo \"# https://medium.com/@kvaps/run-kubernetes-in-lxc-container-f04aa94b6c9c\" >> /etc/rc.local",
      "echo \"mount --make-rshared /\" >> /etc/rc.local",
      "chmod +x /etc/rc.local",
      "sed -i 's/lxc.cgroup.memory.use_hierarchy = 0/lxc.cgroup.memory.use_hierarchy = 1/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.cpu.rt.runtime = -1/lxc.cgroup.cpu.rt.runtime = 950000/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.cpu.rt.period = 1000000/lxc.cgroup.cpu.rt.period = 1000000/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.cpu.shares = 1024/lxc.cgroup.cpu.shares = 2048/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.cpu.cfs.quota = -1/lxc.cgroup.cpu.cfs.quota = 950000/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.cpu.cfs.period = 100000/lxc.cgroup.cpu.cfs.period = 100000/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.memory.limit_in_bytes = -1/lxc.cgroup.memory.limit_in_bytes = 2147483648/' /etc/lxc/default.conf",
      "sed -i 's/lxc.cgroup.memory.swap.max = -1/lxc.cgroup.memory.swap.max = 2147483648/' /etc/lxc/default.conf",
      "ln -s /dev/console /dev/kmsg",
    ]
    connection {
      type     = "ssh"
      user     = "root"
      password = var.lxc_password
      host     = self.hostname
    }
  }
}resource "cloudflare_record" "k3s_dns" {
  count = var.node_count
  zone_id = var.cloudflare_zone_id
  name = "${proxmox_lxc.k3s_node[count.index].hostname}.${var.domain}"
  value = chomp(data.http.public_ipv4.response_body)
  type = "A"
  proxied = false
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl",
    {
      k3s_nodes = proxmox_lxc.k3s_node[*].hostname
    }
  )
  filename = "${path.module}/../ansible/inventory.ini"
}

resource "null_resource" "k3s_master_setup" {
  depends_on = [proxmox_lxc.k3s_node, cloudflare_record.k3s_dns]

  connection {
    type     = "ssh"
    user     = "root"
    password = var.lxc_password
    host     = proxmox_lxc.k3s_node[0].hostname
  }

  provisioner "remote-exec" {
    inline = [
      "modprobe br_netfilter",
      "modprobe overlay",
      "echo '#!/bin/sh -e' > /etc/rc.local",
      "echo 'if [ ! -e /dev/kmsg ]; then ln -s /dev/console /dev/kmsg; fi' >> /etc/rc.local",
      "echo 'mount --make-rshared /' >> /etc/rc.local",
      "chmod +x /etc/rc.local",
      "curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh",
      "chmod +x /tmp/k3s-install.sh",
      "INSTALL_K3S_EXEC='server --node-external-ip=${proxmox_lxc.k3s_node[0].network[0].ip}' /tmp/k3s-install.sh",
      "mkdir -p /root/.kube",
      "cp /etc/rancher/k3s/k3s.yaml /root/.kube/config",
      "sed -i 's|https://localhost:6443|https://${proxmox_lxc.k3s_node[0].hostname}:6443|g' /root/.kube/config"
    ]
  }
}
resource "null_resource" "k3s_worker_setup" {
  count      = var.node_count - 1
  depends_on = [null_resource.k3s_master_setup]

  connection {
    type     = "ssh"
    user     = "root"
    password = var.lxc_password
    host     = proxmox_lxc.k3s_node[count.index + 1].hostname
  }

  provisioner "remote-exec" {
    inline = [
      "modprobe br_netfilter",
      "modprobe overlay",
      "curl -sfL https://get.k3s.io -o /tmp/k3s-install.sh",
      "chmod +x /tmp/k3s-install.sh",
      "K3S_URL='https://${proxmox_lxc.k3s_node[0].hostname}:6443' K3S_TOKEN='${null_resource.k3s_master_setup.triggers.k3s_token}' /tmp/k3s-install.sh"
    ]
  }
}

resource "null_resource" "verify_k3s_cluster" {
  depends_on = [null_resource.k3s_worker_setup]

  connection {
    type     = "ssh"
    user     = "root"
    password = var.lxc_password
    host     = proxmox_lxc.k3s_node[0].hostname
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl get nodes"
    ]
  }
}