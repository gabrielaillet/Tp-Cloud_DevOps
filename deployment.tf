data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.my_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_persistent_volume_claim" "db-pvc" {
  metadata {
    name = "db-pvc"
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "standard" # Ensure this matches the available storage class
  }
}
# Deployment for PostgreSQL
resource "kubernetes_deployment" "db" {
  depends_on = [kubernetes_persistent_volume_claim.db-pvc]
  metadata {
    name = "db"
  }

  spec {
    selector {
      match_labels = {
        app = "db" # Match the YAML label
      }
    }

    template {
      metadata {
        labels = {
          app = "db" # Match the YAML label
        }
      }

      spec {
        container {
          name  = "postgres" # Matching container name in the YAML
          image = "postgres:15-alpine"

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = "postgres"
          }

          volume_mount {
            name       = "postgres-data" # Matching volume name
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "data"
          }
        }

        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.db-pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# Service for PostgreSQL
resource "kubernetes_service" "db" {
  metadata {
    name = "db"
  }

  spec {
    selector = {
      app = "db" # Matching label with deployment
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}


resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
    labels = {
      app = "redis"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis"
          image = "redis:alpine"

          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      protocol    = "TCP"
      port        = 6379
      target_port = 6379
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "result" {
  metadata {
    name = "result"
    labels = {
      app = "result"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "result"
      }
    }

    template {
      metadata {
        labels = {
          app = "result"
        }
      }

      spec {
        container {
          name  = "result"
          image = "europe-west4-docker.pkg.dev/spry-tree-453513-c0/voting-image/result"

          port {
            container_port = 4000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "result_service" {
  metadata {
    name = "result-service"
  }

  spec {
    selector = {
      app = "result"
    }

    port {
      protocol    = "TCP"
      port        = 4000
      target_port = 4000
    }

    type = "LoadBalancer"
  }
}


resource "kubernetes_job" "seed" {
  depends_on = [kubernetes_service.redis]

  metadata {
    name = "seed"
  }

  spec {
    completions   = 1 # Ensures the job runs only once
    backoff_limit = 1 # Limits retries on failure

    template {
      metadata {
        labels = {
          app = "seed"
        }
      }

      spec {
        restart_policy = "Never" # Ensures the job does not restart on completion

        container {
          name  = "seed"
          image = "europe-west4-docker.pkg.dev/spry-tree-453513-c0/voting-image/seed-kub"
        }
      }
    }
  }
}

resource "kubernetes_deployment" "vote" {
  metadata {
    name = "vote"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "vote"
      }
    }

    template {
      metadata {
        labels = {
          app = "vote"
        }
      }

      spec {
        container {
          name  = "vote"
          image = "europe-west4-docker.pkg.dev/spry-tree-453513-c0/voting-image/v1"

          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "vote_service" {
  metadata {
    name = "vote-service"
  }

  spec {
    selector = {
      app = "vote" # Matches the Deployment labels
    }

    port {
      protocol    = "TCP"
      port        = 5000 # External port
      target_port = 5000 # Port inside the container
    }

    type = "LoadBalancer" # Exposes the service outside the cluster
  }
}


resource "kubernetes_deployment" "worker" {
  metadata {
    name = "worker"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "worker"
      }
    }

    template {
      metadata {
        labels = {
          app = "worker"
        }
      }

      spec {
        container {
          name  = "worker"
          image = "europe-west4-docker.pkg.dev/spry-tree-453513-c0/voting-image/worker"

          env {
            name  = "REDIS_HOST"
            value = "redis"
          }

          env {
            name  = "POSTGRES_HOST"
            value = "db"
          }

          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_DB"
            value = "postgres"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }

            requests = {
              cpu    = "250m"
              memory = "128Mi"
            }
          }
        }

        restart_policy = "Always"
      }
    }
  }
}

