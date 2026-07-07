module "preview" {
  source = "../../modules/preview"

  project_id = var.project_id
  region     = var.region
  pr_number  = var.pr_number
  repo       = var.repo
  db_image   = var.db_image

  containers = [
    {
      name  = "frontend"
      image = var.frontend_image
      port  = 8080
      env = [
        { name = "BACKEND_PORT", value = "8081" },
      ]
      depends_on = ["backend"]
    },
    {
      name  = "backend"
      image = var.image
      env = [
        { name = "PORT", value = "8081" },
        { name = "DATABASE_URL", value = "postgres://postgres@localhost:5432/app?sslmode=disable" },
      ]
      depends_on    = ["postgres"]
      startup_probe = { tcp_port = 8081 }
    },
  ]
}
