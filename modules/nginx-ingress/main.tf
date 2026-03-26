terraform {
  required_version = ">= 1.0"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0.1"
    }
  }
}

# Create namespace for Nginx Ingress Controller
resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Install Nginx Ingress Controller via Helm
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name

  values = [
    yamlencode({
      controller = {
        replicaCount = var.replica_count
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"                 = "external"
            "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type"      = "ip"
            "service.beta.kubernetes.io/aws-load-balancer-scheme"               = "internet-facing"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-path"     = "/healthz"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-port"     = "10254"
            "service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol" = "HTTP"
          }
        }
        metrics = {
          enabled = true
        }
        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "200m"
            memory = "256Mi"
          }
        }
        admissionWebhooks = {
          enabled = true
        }
        ingressClassResource = {
          name    = "nginx"
          default = true
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.ingress_nginx]
}
