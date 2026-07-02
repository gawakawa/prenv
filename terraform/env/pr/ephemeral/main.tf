locals {
  backend_port = 8081
}

resource "google_cloud_run_v2_service" "preview" {
  # iap_enabled is a Beta-only field, so this resource uses the google-beta provider.
  provider = google-beta

  name     = "prenv-pr-${var.pr_number}"
  project  = var.project_id
  location = var.region

  # Must be false so `tofu destroy` can remove the service on PR close.
  deletion_protection = false

  # BETA launch stage is required to use the preview iap_enabled field.
  launch_stage = "BETA"

  # Enable IAP — restricts access to identities listed in the foundation's
  # iap_members variable. Public (allUsers) access is removed.
  iap_enabled = true

  template {
    scaling {
      max_instance_count = 1
    }

    volumes {
      name = "pgdata"
      empty_dir {
        medium     = "MEMORY"
        size_limit = "256Mi"
      }
    }

    containers {
      name  = "frontend"
      image = var.frontend_image
      ports { container_port = 8080 }
      env {
        name  = "BACKEND_PORT"
        value = tostring(local.backend_port)
      }
      resources {
        limits            = { cpu = "1", memory = "512Mi" }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      depends_on = ["backend"]
    }

    containers {
      name  = "backend"
      image = var.image
      env {
        name  = "PORT"
        value = tostring(local.backend_port)
      }
      env {
        name  = "DATABASE_URL"
        value = "postgres://postgres@localhost:5432/app?sslmode=disable"
      }
      resources {
        limits            = { cpu = "1", memory = "512Mi" }
        cpu_idle          = true
        startup_cpu_boost = true
      }
      startup_probe {
        tcp_socket { port = local.backend_port }
        initial_delay_seconds = 5
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 24
      }
      depends_on = ["postgres"]
    }

    containers {
      name  = "postgres"
      image = var.db_image
      env {
        name  = "POSTGRES_DB"
        value = "app"
      }
      env {
        name  = "POSTGRES_HOST_AUTH_METHOD"
        value = "trust"
      }
      volume_mounts {
        name       = "pgdata"
        mount_path = "/var/lib/postgresql"
      }
      resources {
        limits   = { cpu = "1", memory = "512Mi" }
        cpu_idle = true
      }
      startup_probe {
        tcp_socket { port = 5432 }
        initial_delay_seconds = 5
        period_seconds        = 5
        timeout_seconds       = 3
        failure_threshold     = 24
      }
    }
  }
}
