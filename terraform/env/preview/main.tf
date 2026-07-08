locals {
  backend_port = 8081

  # CI resolves and builds these three images (see .github/workflows/deploy-prenv.yml);
  # defaults here are placeholders used only for teardown, where no build happens.
  frontend_image = lookup(var.images, "frontend", "us-docker.pkg.dev/cloudrun/container/hello")
  backend_image  = lookup(var.images, "backend", "us-docker.pkg.dev/cloudrun/container/hello")
  db_image       = lookup(var.images, "db", "postgres:18-alpine")
}

module "preview" {
  source = "../../modules/preview"

  project_id = var.project_id
  region     = var.region
  pr_number  = var.pr_number
  repo       = var.repo
  db_image   = local.db_image

  containers = [
    {
      name  = "frontend"
      image = local.frontend_image
      port  = 8080
      env = [
        { name = "BACKEND_PORT", value = tostring(local.backend_port) },
      ]
      depends_on = ["backend"]
    },
    {
      name  = "backend"
      image = local.backend_image
      env = [
        { name = "PORT", value = tostring(local.backend_port) },
        { name = "DATABASE_URL", value = "postgres://postgres@localhost:5432/app?sslmode=disable" },
        { name = "GCS_BUCKET", value = var.tfstate_bucket },
        { name = "REPO", value = var.repo },
      ]
      depends_on    = ["postgres"]
      startup_probe = { tcp_port = local.backend_port }
    },
  ]
}
