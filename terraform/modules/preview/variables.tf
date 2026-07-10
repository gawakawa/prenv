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
    condition = length(
      "${lower(replace(split("/", var.repo)[0], "/[^a-zA-Z0-9]+/", "-"))}--${lower(replace(split("/", var.repo)[1], "/[^a-zA-Z0-9]+/", "-"))}-pr-${var.pr_number}"
    ) <= 63
    error_message = "The Cloud Run service name derived from repo and pr_number (\"<owner>--<repo>-pr-<N>\") must be 63 characters or fewer. Shorten the repository name."
  }
}

variable "containers" {
  description = <<-EOT
    Application containers to run inside the preview service. Exactly one
    container must set `port` (Cloud Run ingress). Every name listed in
    another container's `depends_on` must belong to a container with a
    `startup_probe` — Cloud Run rejects the deploy with a 400 otherwise.
    `volume_mounts` references entries in `var.volumes` by name.
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
    volume_mounts = optional(list(object({
      name       = string
      mount_path = string
    })), [])
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
      ])
    ])
    error_message = "Every `depends_on` target must define `startup_probe`."
  }
}

variable "volumes" {
  description = "Volumes shared across containers. `containers[*].volume_mounts` reference these by name."
  type = list(object({
    name = string
    empty_dir = optional(object({
      medium     = string
      size_limit = string
    }))
  }))
  default = []
}
