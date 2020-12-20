terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

provider "kubernetes" {}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx"
    labels = {
      App = "ScalableNginx"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        App = "ScalableNginx"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginx"
        }
      }
      spec {
        container {
          image = "nginx:1.7.9"
          name  = "ngins"

          port {
            container_port = 80
          }

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "50m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "nginx" {
  metadata {
    name = "scalable-nginx"
  }

  spec {
    min_replicas = 2
    max_replicas = 10
    target_cpu_utilization_percentage = 15

    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = "scalable-nginx"
    }

  }
}
