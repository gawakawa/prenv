FROM postgres:18-alpine
# Runs on first init in filename order: migrations (0001_) before seed (zz_).
COPY migrations/0001_init.sql /docker-entrypoint-initdb.d/0001_init.sql
COPY seed.sql                 /docker-entrypoint-initdb.d/zz_seed.sql
