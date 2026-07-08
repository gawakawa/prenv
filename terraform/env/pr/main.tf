locals {
  backend_port = 8081

  # Each entry describes one Cloud Run container by role. Fields that don't
  # apply to a role (volume_mount, startup_probe_port) are null and skipped
  # via dynamic blocks below, so all three roles share the same shape.
  containers = {
    frontend = {
      image              = var.frontend_image
      ports              = [8080]
      env                = { BACKEND_PORT = tostring(local.backend_port) }
      volume_mount       = null
      startup_probe_port = null
      depends_on         = ["backend"]
    }
    backend = {
      image = var.backend_image
      ports = []
      env = {
        PORT         = tostring(local.backend_port)
        DATABASE_URL = "postgres://postgres@localhost:5432/app?sslmode=disable"
      }
      volume_mount       = null
      startup_probe_port = local.backend_port
      depends_on         = ["postgres"]
    }
    postgres = {
      image = var.db_image
      ports = []
      env = {
        POSTGRES_DB               = "app"
        POSTGRES_HOST_AUTH_METHOD = "trust"
      }
      volume_mount       = { name = "pgdata", mount_path = "/var/lib/postgresql" }
      startup_probe_port = 5432
      depends_on         = []
    }
  }
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

    dynamic "containers" {
      for_each = local.containers
      content {
        name  = containers.key
        image = containers.value.image

        dynamic "ports" {
          for_each = containers.value.ports
          content {
            container_port = ports.value
          }
        }

        dynamic "env" {
          for_each = containers.value.env
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "volume_mounts" {
          for_each = containers.value.volume_mount == null ? [] : [containers.value.volume_mount]
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }

        resources {
          limits            = { cpu = "1", memory = "512Mi" }
          cpu_idle          = true
          startup_cpu_boost = true
        }

        dynamic "startup_probe" {
          for_each = containers.value.startup_probe_port == null ? [] : [containers.value.startup_probe_port]
          content {
            tcp_socket {
              port = startup_probe.value
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 24
          }
        }

        depends_on = containers.value.depends_on
      }
    }
  }

  # The Cloud Run Admin API doesn't persist launch_stage — it's a request-only
  # directive, and GET always reports back the stage actually required by the
  # service's features. That makes launch_stage a permanent GA/BETA diff.
  lifecycle {
    ignore_changes = [launch_stage]
  }
}
