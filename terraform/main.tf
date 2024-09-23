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
      "echo \"mount -o remount,rw /\" >> /etc/rc.local",
      "echo \"mount -o remount,rw /proc\" >> /etc/rc.local",
      "echo \"mount -o remount,rw /sys\" >> /etc/rc.local",
      "chmod +x /etc/rc.local",
      "systemctl enable rc-local.service",
      "systemctl start rc-local.service",
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
      host     = "${self.hostname}"
    }
  }
}

resource "cloudflare_record" "k3s_dns" {
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

resource "null_resource" "ansible_provisioner" {
  depends_on = [local_file.ansible_inventory, cloudflare_record.k3s_dns]

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/../ansible/inventory.ini ${path.module}/../ansible/k3s-install.yml"
    environment = {
      CLOUDFLARE_API_TOKEN = var.cloudflare_api_token
    }
  }
}