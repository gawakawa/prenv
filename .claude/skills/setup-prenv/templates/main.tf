module "preview" {
  source = "git::https://github.com/gawakawa/prenv.git//terraform/modules/preview?ref=main"

  project_id = var.project_id
  region     = var.region
  pr_number  = var.pr_number

  # Exactly one container must set `port` (Cloud Run ingress). Every
  # `depends_on` target must define `startup_probe`, or Cloud Run rejects the
  # deploy with a 400. See the module's README for the full schema and the
  # built-in `postgres` sidecar contract (enable_db_sidecar, default true).
  containers = [
    {
      name  = "app"
      image = var.image
      port  = 8080
    },
  ]
}
