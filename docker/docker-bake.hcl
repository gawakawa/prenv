variable "AR_REPO" {}
variable "GH_REPO" {}
variable "APP_TAG" { default = "latest" }
variable "DB_TAG"  { default = "latest" }

group "default" {
  targets = ["app", "db"]
}

target "app" {
  context    = "app"
  dockerfile = "../docker/app/Dockerfile"
  tags       = ["${AR_REPO}/${GH_REPO}/app:${APP_TAG}"]
  cache-from = ["type=registry,ref=${AR_REPO}/${GH_REPO}/app:buildcache"]
  cache-to   = ["type=registry,ref=${AR_REPO}/${GH_REPO}/app:buildcache,mode=max,image-manifest=true,oci-mediatypes=true"]
}

target "db" {
  context    = "db"
  dockerfile = "../docker/db/Dockerfile"
  tags       = ["${AR_REPO}/${GH_REPO}/db:${DB_TAG}"]
}
