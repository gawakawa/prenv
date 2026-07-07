variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Region for the Cloud Run service."
  type        = string
  default     = "asia-northeast1"
}

variable "pr_number" {
  description = "Pull request number. Used to name and isolate the preview environment."
  type        = number
}

variable "repo" {
  description = "GitHub repository in OWNER/REPO format. Disambiguates the Cloud Run service name when multiple repositories share this managed project."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.repo))
    error_message = "repo must be in OWNER/REPO form."
  }

  validation {
    condition     = length("${lower(replace(var.repo, "/[^a-zA-Z0-9]+/", "-"))}-pr-${var.pr_number}") <= 63
    error_message = "The Cloud Run service name derived from repo and pr_number (\"<owner>-<repo>-pr-<N>\") must be 63 characters or fewer. Shorten the repository name."
  }
}

variable "containers" {
  description = <<-EOT
    Application containers to run inside the preview service. Exactly one
    container must set `port` (Cloud Run ingress). Every name listed in
    another container's `depends_on` must belong to a container with a
    `startup_probe` — Cloud Run rejects the deploy with a 400 otherwise —
    or (when `enable_db_sidecar = true`) be the built-in `postgres` sidecar.

    When `enable_db_sidecar = true`, a Postgres container named `postgres`
    listens on `localhost:5432` with database `app`, user `postgres`, and no
    password. Wire it explicitly on the container that needs it:
      env        = [{ name = "DATABASE_URL", value = "postgres://postgres@localhost:5432/app?sslmode=disable" }]
      depends_on = ["postgres"]
  EOT
  type = list(object({
    name              = string
    image             = string
    port              = optional(number)
    env               = optional(list(object({ name = string, value = string })), [])
    depends_on        = optional(list(string), [])
    cpu_limit         = optional(string, "1")
    memory_limit      = optional(string, "512Mi")
    startup_cpu_boost = optional(bool, true)
    startup_probe = optional(object({
      tcp_port              = number
      initial_delay_seconds = optional(number, 5)
      period_seconds        = optional(number, 5)
      timeout_seconds       = optional(number, 3)
      failure_threshold     = optional(number, 24)
    }))
  }))

  validation {
    condition     = length([for c in var.containers : c if c.port != null]) == 1
    error_message = "Exactly one container must set `port` (Cloud Run ingress requires one ingress container)."
  }

  validation {
    condition = alltrue([
      for c in var.containers : alltrue([
        for dep in c.depends_on :
        contains([for d in var.containers : d.name if d.startup_probe != null], dep)
        || (var.enable_db_sidecar && dep == "postgres")
      ])
    ])
    error_message = "Every `depends_on` target must define `startup_probe` (or be the built-in `postgres` sidecar when enable_db_sidecar = true)."
  }
}

variable "enable_db_sidecar" {
  description = "Run a Postgres sidecar container (name `postgres`, localhost:5432, database `app`) alongside the application containers."
  type        = bool
  default     = true
}

variable "db_image" {
  description = "Postgres sidecar image. Ignored when enable_db_sidecar = false."
  type        = string
  default     = "postgres:18-alpine"
}
