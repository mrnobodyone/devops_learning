provider "helm" {
  kubernetes {
    config_path = pathexpand(var.kubeconfig)
  }
}

provider "kubectl" {
  config_path      = pathexpand(var.kubeconfig)
  load_config_file = true
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
    name  = "crds.enabled" # в старых версиях чарта: installCRDs
    value = "true"
  }
}

data "kubectl_file_documents" "issuers" {
  content = file("${path.module}/manifests/cert-manager-issuers.yaml")
}

resource "kubectl_manifest" "issuers" {
  for_each  = data.kubectl_file_documents.issuers.manifests
  yaml_body = each.value

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
resource "kubectl_manifest" "root_app" {
  yaml_body = file("${path.module}/manifests/root-app.yaml")

  depends_on = [
    helm_release.argocd,
    kubectl_manifest.issuers,
  ]
}
