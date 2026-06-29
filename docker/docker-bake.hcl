variable "AR_REPO" {}
variable "GH_REPO" {}
variable "BACKEND_TAG"  { default = "latest" }
variable "DB_TAG"       { default = "latest" }
variable "FRONTEND_TAG" { default = "latest" }

group "default" {
  targets = ["backend", "db", "frontend"]
}

target "backend" {
  context    = "backend"
  dockerfile = "../docker/backend/Dockerfile"
  tags       = ["${AR_REPO}/${GH_REPO}/backend:${BACKEND_TAG}"]
  cache-from = ["type=registry,ref=${AR_REPO}/${GH_REPO}/backend:buildcache"]
  cache-to   = ["type=registry,ref=${AR_REPO}/${GH_REPO}/backend:buildcache,mode=max,image-manifest=true,oci-mediatypes=true"]
}

target "db" {
  context    = "db"
  dockerfile = "../docker/db/Dockerfile"
  tags       = ["${AR_REPO}/${GH_REPO}/db:${DB_TAG}"]
}

target "frontend" {
  context    = "frontend"
  dockerfile = "../docker/frontend/Dockerfile"
  tags       = ["${AR_REPO}/${GH_REPO}/frontend:${FRONTEND_TAG}"]
  cache-from = ["type=registry,ref=${AR_REPO}/${GH_REPO}/frontend:buildcache"]
  cache-to   = ["type=registry,ref=${AR_REPO}/${GH_REPO}/frontend:buildcache,mode=max,image-manifest=true,oci-mediatypes=true"]
}
