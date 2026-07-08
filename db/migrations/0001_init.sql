CREATE TABLE prenvs (
  pr_number  INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  url        TEXT NOT NULL,
  status     TEXT NOT NULL,
  commit_sha TEXT NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
