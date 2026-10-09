variable "kubeconfig" {
  type    = string
  default = "~/.kube/config"
}

variable "cert_manager_version" {
  type        = string
  description = "Версия чарта jetstack/cert-manager"
}

variable "argocd_version" {
  type        = string
  description = "Версия чарта argo/argo-cd"
}
