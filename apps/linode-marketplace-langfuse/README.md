# Langfuse Marketplace App

Deploys [Langfuse](https://langfuse.com) — an open-source LLM engineering / observability platform —
as a One-Click App on Akamai Cloud Compute.

Langfuse runs as a Docker Compose stack (web + worker + Postgres + ClickHouse + Redis, plus a
bundled MinIO by default) behind an nginx reverse proxy with a Let's Encrypt certificate. Native
authentication is enforced; the admin user, default project, and API keys are seeded at deploy time
and written to `/home/<user>/.credentials`.

## Blob storage

Langfuse requires S3-compatible blob storage. This app offers two paths:

- **Bundled MinIO (default):** no configuration required. Ships mandatory event storage.
- **Linode Object Storage:** fill in all four Object Storage UDFs (bucket, endpoint, access key,
  secret key). The bucket must already exist and the key must have read/write access to it — the
  playbook validates this **before** installing and aborts early if the bucket is unreachable.
  This path also enables multi-modal media uploads.

## Structure

```
apps/linode-marketplace-langfuse/
├── site.yml, provision.yml, collections.yml, requirements.txt, ansible.cfg
├── group_vars/linode/vars          # populated at deploy time
└── roles/
    ├── common/                     # hostname, DNS, SSH, hardening, ufw, fail2ban
    ├── langfuse/                   # object-storage precheck, compose stack, nginx + SSL
    └── post/                       # MOTD + .credentials
```

Deployment StackScript: `deployment_scripts/linode-marketplace-langfuse/`.
