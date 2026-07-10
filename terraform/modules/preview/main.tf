locals {
  # Cloud Run service names are unique per project+region and can't contain
  # "/", so the OWNER/REPO identity is flattened into a single label —
  # otherwise two repos' PR numbers collide when sharing one managed project.
  # OWNER and REPO are sanitized independently and joined with "--" (rather
  # than sanitizing "owner/repo" as one string) so that e.g. "a/b-c" and
  # "a-b/c" can't collapse to the same slug.
  repo_parts = split("/", var.repo)
  repo_slug  = "${lower(replace(local.repo_parts[0], "/[^a-zA-Z0-9]+/", "-"))}--${lower(replace(local.repo_parts[1], "/[^a-zA-Z0-9]+/", "-"))}"
}

resource "google_cloud_run_v2_service" "preview" {
  # iap_enabled is a Beta-only field, so this resource uses the google-beta provider.
  provider = google-beta

  name     = "${local.repo_slug}-pr-${var.pr_number}"
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

    dynamic "volumes" {
      for_each = { for v in var.volumes : v.name => v }
      content {
        name = volumes.value.name
        dynamic "empty_dir" {
          for_each = volumes.value.empty_dir != null ? [volumes.value.empty_dir] : []
          content {
            medium     = empty_dir.value.medium
            size_limit = empty_dir.value.size_limit
          }
        }
      }
    }

    dynamic "containers" {
      for_each = { for c in var.containers : c.name => c }
      content {
        name  = containers.value.name
        image = containers.value.image

        dynamic "ports" {
          for_each = containers.value.port != null ? [containers.value.port] : []
          content {
            container_port = ports.value
          }
        }

        dynamic "env" {
          for_each = containers.value.env
          content {
            name  = env.value.name
            value = env.value.value
          }
        }

        dynamic "volume_mounts" {
          for_each = containers.value.volume_mounts
          content {
            name       = volume_mounts.value.name
            mount_path = volume_mounts.value.mount_path
          }
        }

        resources {
          limits            = { cpu = containers.value.cpu_limit, memory = containers.value.memory_limit }
          cpu_idle          = true
          startup_cpu_boost = containers.value.startup_cpu_boost
        }

        dynamic "startup_probe" {
          for_each = containers.value.startup_probe != null ? [containers.value.startup_probe] : []
          content {
            tcp_socket {
              port = startup_probe.value.tcp_port
            }
            initial_delay_seconds = startup_probe.value.initial_delay_seconds
            period_seconds        = startup_probe.value.period_seconds
            timeout_seconds       = startup_probe.value.timeout_seconds
            failure_threshold     = startup_probe.value.failure_threshold
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
