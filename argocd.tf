resource "null_resource" "install_argocd" {
  depends_on = [null_resource.k3s_master, null_resource.k3s_workers]

  connection {
    type        = "ssh"
    user        = var.container_user
    private_key = file("~/.ssh/id_rsa")
    host        = proxmox_lxc.k3s_master.hostname
  }

  provisioner "remote-exec" {
    inline = [
      # Delete existing resources if they exist
      "kubectl delete namespace argocd --ignore-not-found",
      "kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/cloud/deploy.yaml --ignore-not-found",
      "kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml --ignore-not-found",

      # Recreate resources
      "kubectl create namespace argocd",
      "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml",
      "kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd",

      # Install Nginx Ingress Controller
      "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.0/deploy/static/provider/cloud/deploy.yaml",
      "kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s",

      # Install cert-manager for SSL certificates
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
      # Create Ingress for ArgoCD
      <<-EOF
      cat <<EOT | kubectl apply -f -
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: argocd-server-ingress
        namespace: argocd
        annotations:
          nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
          cert-manager.io/cluster-issuer: letsencrypt-prod
          nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      spec:
        ingressClassName: nginx
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
                  name: argocd-server
                  port: 
                    number: 443
      EOT
      EOF
    ]
  }
}
resource "null_resource" "configure_argocd" {
  depends_on = [null_resource.install_argocd]

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