variable "AR_REPO" {}
variable "TAG" { default = "latest" }

group "default" {
  targets = ["app", "db"]
}

target "app" {
  context    = "app"
  dockerfile = "../docker/app/Dockerfile"
  tags       = ["${AR_REPO}/app:${TAG}"]
  cache-from = ["type=registry,ref=${AR_REPO}/app:buildcache"]
  cache-to   = ["type=registry,ref=${AR_REPO}/app:buildcache,mode=max,image-manifest=true,oci-mediatypes=true"]
}

target "db" {
  context    = "db"
  dockerfile = "../docker/db/Dockerfile"
  tags       = ["${AR_REPO}/db:${TAG}"]
}
