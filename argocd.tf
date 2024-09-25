resource "null_resource" "install_argocd_and_nginx" {
  depends_on = [null_resource.k3s_master, null_resource.k3s_workers]

  connection {
    type        = "ssh"
    user        = var.container_user
    private_key = file("~/.ssh/id_rsa")
    host        = proxmox_lxc.k3s_master.hostname
  }

  provisioner "file" {
    source      = "nginx-ingress.yaml"
    destination = "/tmp/nginx-ingress.yaml"
  }

  provisioner "file" {
    source      = "argocd.yaml"
    destination = "/tmp/argocd.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      # Create namespaces
      "kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -",
      "kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -",
      "kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -",

      # Apply NGINX Ingress Controller
      "kubectl apply -f /tmp/nginx-ingress.yaml",
      "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app=nginx-ingress --timeout=300s",

      # Install cert-manager
      "kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml",
      "kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager",

      # Create ClusterIssuer for Let's Encrypt
      <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: cert-manager.io/v1
      kind: ClusterIssuer
      metadata:
        name: letsencrypt-prod
      spec:
        acme:
          server: https://acme-v02.api.letsencrypt.org/directory
          email: ${var.email_address}
          privateKeySecretRef:
            name: letsencrypt-prod
          solvers:
          - http01:
              ingress:
                class: nginx
      EOT
      EOF
      ,

      # Apply ArgoCD
      "kubectl apply -f /tmp/argocd.yaml",
      "kubectl wait --namespace argocd --for=condition=available --timeout=600s deployment/argocd-server",

      # Update ArgoCD Ingress to use TLS
      <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: argocd-server-ingress
        namespace: argocd
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: "letsencrypt-prod"
          nginx.ingress.kubernetes.io/ssl-passthrough: "true"
          nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      spec:
        tls:
        - hosts:
          - argocd.${var.domain_name}
          secretName: argocd-secret-tls
        rules:
        - host: argocd.${var.domain_name}
          http:
            paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: argocd-server-service
                  port: 
                    number: 80
      EOT
      EOF
      ,

      # Clean up temporary files
      "rm /tmp/nginx-ingress.yaml /tmp/argocd.yaml"
    ]
  }
}

resource "null_resource" "configure_argocd" {
  depends_on = [null_resource.install_argocd_and_nginx]

  connection {
    type        = "ssh"
    user        = var.container_user
    private_key = file("~/.ssh/id_rsa")
    host        = proxmox_lxc.k3s_master.hostname
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d > /tmp/argocd_password",
      "argocd_password=$(cat /tmp/argocd_password)",
      "kubectl -n argocd patch secret argocd-secret --type='json' -p='[{\"op\": \"replace\", \"path\": \"/data/admin.password\", \"value\": \"'$(echo -n \"$argocd_password\" | base64)'\"}]'",
      "rm /tmp/argocd_password",
    ]
  }
}