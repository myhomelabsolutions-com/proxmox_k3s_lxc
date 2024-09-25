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
      "if ! command -v k3s &> /dev/null; then",
      "  curl -sfL https://get.k3s.io | K3S_DISABLE_TRAEFIK=true sh - || exit 1",
      "fi",
      "until kubectl get nodes | grep -q ' Ready'; do sleep 5; done",
      "kubectl get nodes",
      "K3S_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)",
      "echo $K3S_TOKEN > /tmp/k3s_join_token",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa ${var.container_user}@${proxmox_lxc.k3s_master.hostname}:/tmp/k3s_join_token .
      for i in 0 1; do
        scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_rsa k3s_join_token ${var.container_user}@${proxmox_lxc.k3s_worker[i].hostname}:/tmp/
      done
      rm k3s_join_token
    EOT
  }
}

resource "null_resource" "k3s_workers" {
  count      = 2
  depends_on = [proxmox_lxc.k3s_worker, null_resource.lxc_config, null_resource.k3s_master]

  connection {
    type        = "ssh"
    user        = var.container_user
    private_key = file("~/.ssh/id_rsa")
    host        = proxmox_lxc.k3s_worker[count.index].hostname
  }

  provisioner "remote-exec" {
    inline = [
      "if ! command -v k3s &> /dev/null; then",
      "  K3S_TOKEN=$(cat /tmp/k3s_join_token)",
      "  curl -sfL https://get.k3s.io | K3S_URL=https://${proxmox_lxc.k3s_master.hostname}:6443 K3S_TOKEN=$K3S_TOKEN K3S_NODE_LABEL=node-role.kubernetes.io/worker=true K3S_NODE_TAINT=node-role.kubernetes.io/worker=:NoSchedule K3S_DISABLE_TRAEFIK=true sh - || exit 1",
      "fi",
      "rm /tmp/k3s_join_token",
    ]
  }
}

output "k3s_master_ip" {
  value = proxmox_lxc.k3s_master.hostname
}

output "k3s_worker_ips" {
  value = proxmox_lxc.k3s_worker[*].hostname
}