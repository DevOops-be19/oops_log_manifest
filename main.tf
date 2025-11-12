# Kubernetes 프로바이더 설정
provider "kubernetes" {
  config_path = "~/.kube/config"  # 로컬 Kubernetes 설정 파일 경로
}

# Spring Boot Deployment and Service
resource "kubernetes_deployment" "boot003dep" {
  metadata {
    name = "boot003dep"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "boot003kube"
      }
    }

    template {
      metadata {
        labels = {
          app = "boot003kube"
        }
      }

      spec {
        container {
          image             = "kjandgo/jen_19_boot2:latest"
          name              = "boot-container"
          image_pull_policy = "Always"

          port {
            container_port = 7777
          }

          env {
            name  = "SPRING_DATASOURCE_URL"
            value = "jdbc:mariadb://mariadb003ser:3310/calcdb"
          }

          env {
            name  = "SPRING_DATASOURCE_USERNAME"
            value = "root"
          }

          env {
            name  = "SPRING_DATASOURCE_PASSWORD"
            value = "root1234"
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 7777
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 7777
            }
            initial_delay_seconds = 60
            period_seconds        = 15
            timeout_seconds       = 5
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_deployment.mariadb003dep,
    kubernetes_service.mariadb003ser
  ]
}

resource "kubernetes_service" "boot003ser" {
  metadata {
    name = "boot003ser"
  }

  spec {
    selector = {
      app = "boot003kube"
    }

    port {
      port        = 8001
      target_port = 7777
    }

    type = "ClusterIP"
  }
}


# Ingress
resource "kubernetes_ingress_v1" "sw_camp_ingress_db" {
  metadata {
    name = "sw-camp-ingress-db"
    annotations = {
      "nginx.ingress.kubernetes.io/ssl-redirect"  = "false"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          path      = "/()(.*)$"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.vue003ser.metadata[0].name
              port {
                number = 8000
              }
            }
          }
        }
        path {
          path      = "/boot(/|$)(.*)$"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = kubernetes_service.boot003ser.metadata[0].name
              port {
                number = 8001
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.vue003ser,
    kubernetes_service.boot003ser
  ]
}
