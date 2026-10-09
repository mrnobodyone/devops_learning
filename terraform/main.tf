provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kubeconfig)
  }
}

# --- cert-manager ---
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true
  timeout          = 600

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# --- CA и ClusterIssuer'ы ---
resource "helm_release" "issuers" {
  name      = "platform-issuers"
  chart     = "${path.module}/charts/platform-issuers"
  namespace = "cert-manager"
  wait      = true

  depends_on = [helm_release.cert_manager]
}

# --- ArgoCD ---
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_version
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [file("${path.module}/values/argocd.yaml")]
}

# --- корневое приложение (app-of-apps) ---
resource "helm_release" "root_app" {
  name      = "platform-root"
  chart     = "${path.module}/charts/platform-root"
  namespace = "argocd"
  wait      = true

  depends_on = [
    helm_release.argocd,
    helm_release.issuers,
  ]
}
