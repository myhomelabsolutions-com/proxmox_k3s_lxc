# LXC container configuration

resource "proxmox_lxc" "k3s_master" {
  target_node  = "pve"
  hostname     = "k3s-master"
  ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  password     = var.container_password
  unprivileged = false
  start        = true
  vmid         = 400

  cores  = 2
  memory = 4096
  rootfs {
    storage = "local-lvm"
    size    = "60G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  features {
    nesting = true
    keyctl  = true
    fuse    = true
  }

  ssh_public_keys = file("~/.ssh/id_rsa.pub")

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.container_user
      private_key = file("~/.ssh/id_rsa")
      host        = self.hostname
    }

    inline = [
      "apt update && apt install -y curl jq",
      "echo '#!/bin/sh -e' > /etc/rc.local",
      "echo 'ln -s /dev/console /dev/kmsg' >> /etc/rc.local",
      "echo 'mount --make-rshared /' >> /etc/rc.local",
      "chmod +x /etc/rc.local",
      "reboot",
    ]
  }
}

resource "proxmox_lxc" "k3s_worker" {
  count        = 2
  target_node  = "pve"
  hostname     = "k3s-worker-${count.index + 1}"
  ostemplate   = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  password     = var.container_password
  unprivileged = false
  start        = true
  vmid         = 500 + count.index

  cores  = 2
  memory = 4096
  rootfs {
    storage = "local-lvm"
    size    = "60G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  features {
    nesting = true
    keyctl  = true
    fuse    = true
  }
  ssh_public_keys = file("~/.ssh/id_rsa.pub")

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.container_user
      private_key = file("~/.ssh/id_rsa")
      host        = self.hostname
    }

    inline = [
      "apt update && apt install -y curl jq ",
      "echo '#!/bin/sh -e' > /etc/rc.local",
      "echo 'ln -s /dev/console /dev/kmsg' >> /etc/rc.local",
      "echo 'mount --make-rshared /' >> /etc/rc.local",
      "chmod +x /etc/rc.local",
      "reboot",
    ]
  }
}

resource "null_resource" "lxc_config" {
  count = 3

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = var.proxmox_user
      password = var.proxmox_password
      host     = var.proxmox_host
    }

    inline = [
      "echo 'lxc.apparmor.profile: unconfined' >> /etc/pve/lxc/${count.index < 1 ? 400 : 500 + count.index - 1}.conf",
      "echo 'lxc.cgroup.devices.allow: a' >> /etc/pve/lxc/${count.index < 1 ? 400 : 500 + count.index - 1}.conf",
      "echo 'lxc.cap.drop:' >> /etc/pve/lxc/${count.index < 1 ? 400 : 500 + count.index - 1}.conf",
      "echo 'lxc.mount.auto: \"proc:rw sys:rw\"' >> /etc/pve/lxc/${count.index < 1 ? 400 : 500 + count.index - 1}.conf",
      "sed -i 's/lxc.apparmor.profile = generated/lxc.apparmor.profile = unconfined/' /etc/pve/lxc/${count.index < 1 ? 400 : 500 + count.index - 1}.conf",
      "systemctl restart pve-lxc-syscalld.service"
    ]
  }

  depends_on = [proxmox_lxc.k3s_master, proxmox_lxc.k3s_worker]
}