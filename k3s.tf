# K3s cluster configuration

resource "null_resource" "k3s_master" {
  depends_on = [proxmox_lxc.k3s_master, null_resource.lxc_config]

  connection {
    type        = "ssh"
    user        = var.container_user
    private_key = file("~/.ssh/id_rsa")
    host        = proxmox_lxc.k3s_master.hostname
  }

  provisioner "remote-exec" {
    inline = [
      "export ANSIBLE_HOST_KEY_CHECKING=False",
      "curl -sfL https://get.k3s.io | K3S_DISABLE_TRAEFIK=true sh -",
      "until kubectl get nodes | grep -q ' Ready'; do sleep 5; done",
      "kubectl get nodes",
      "cat /var/lib/rancher/k3s/server/node-token > /tmp/k3s_join_token.txt",
    ]
  }

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ${var.container_user}@${proxmox_lxc.k3s_master.hostname}:/tmp/k3s_join_token.txt k3s_join_token.txt"
  }
}

resource "null_resource" "k3s_workers" {
  count      = 2
  depends_on = [proxmox_lxc.k3s_worker, null_resource.lxc_config, null_resource.k3s_master]

  provisioner "local-exec" {
    command = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ${var.container_user}@${proxmox_lxc.k3s_worker[count.index].hostname} 'curl -sfL https://get.k3s.io | K3S_URL=https://${proxmox_lxc.k3s_master.hostname}:6443 K3S_TOKEN=$(cat k3s_join_token.txt) K3S_NODE_LABEL=node-role.kubernetes.io/worker=true K3S_NODE_TAINT=node-role.kubernetes.io/worker=:NoSchedule K3S_DISABLE_TRAEFIK=true sh -'"
  }
}

data "local_file" "k3s_join_token" {
  filename = "k3s_join_token.txt"
}

output "k3s_join_token" {
  value     = data.local_file.k3s_join_token.content
  sensitive = true
}