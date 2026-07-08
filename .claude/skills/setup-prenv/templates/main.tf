module "preview" {
  # Pinned to a prenv commit SHA. Bump when adopting newer prenv changes.
  source = "git::https://github.com/gawakawa/prenv.git//terraform/modules/preview?ref=feea0950ab5771874cf3ede17f57ce2345b86c0a"

  project_id = var.project_id
  region     = var.region
  pr_number  = var.pr_number
  repo       = var.repo

  # Exactly one container must set `port` (Cloud Run ingress). Every
  # `depends_on` target must define `startup_probe`, or Cloud Run rejects the
  # deploy with a 400. See the module's README for the full schema.
  # Remove the `postgres` entry and `volumes` below if the app doesn't use a DB.
  containers = [
    {
      name  = "app"
      image = lookup(var.images, "app", "us-docker.pkg.dev/cloudrun/container/hello")
      port  = 8080
      env = [
        { name = "DATABASE_URL", value = "postgres://postgres@localhost:5432/app?sslmode=disable" },
      ]
      depends_on = ["postgres"]
    },
    {
      name  = "postgres"
      image = lookup(var.images, "db", "postgres:18-alpine")
      env = [
        { name = "POSTGRES_DB", value = "app" },
        { name = "POSTGRES_HOST_AUTH_METHOD", value = "trust" },
      ]
      startup_cpu_boost = false
      startup_probe     = { tcp_port = 5432 }
      volume_mounts     = [{ name = "pgdata", mount_path = "/var/lib/postgresql" }]
    },
  ]

  volumes = [
    { name = "pgdata", empty_dir = { medium = "MEMORY", size_limit = "256Mi" } },
  ]
}
