module "preview" {
  # Pinned to a prenv commit SHA. Bump when adopting newer prenv changes.
  source = "git::https://github.com/gawakawa/prenv.git//terraform/modules/preview?ref=feea0950ab5771874cf3ede17f57ce2345b86c0a"

  project_id = var.project_id
  region     = var.region
  pr_number  = var.pr_number
  repo       = var.repo

  # Set to true (the module default) if your app needs the built-in Postgres
  # sidecar — see the module's README for the depends_on/DATABASE_URL contract.
  enable_db_sidecar = false

  # Exactly one container must set `port` (Cloud Run ingress). Every
  # `depends_on` target must define `startup_probe`, or Cloud Run rejects the
  # deploy with a 400. See the module's README for the full schema.
  containers = [
    {
      name  = "app"
      image = var.image
      port  = 8080
    },
  ]
}
