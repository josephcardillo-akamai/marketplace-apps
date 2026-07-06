# Langfuse Quick Deploy App

![langfuse.png](langfuse.png)

Deploy [Langfuse](https://langfuse.com/) — the open-source LLM engineering platform
(tracing/observability, evals, prompt management, metrics) — on Akamai Cloud Compute.

## Architecture

Official Docker Compose stack (`langfuse/langfuse:3`): web app + async worker + PostgreSQL 17 +
ClickHouse + Redis, fronted by NGINX with a Let's Encrypt certificate. All services bind to
loopback; only ports 22/80/443 are exposed. Signup is disabled and the admin account, project,
and SDK API keypair are provisioned headlessly at deploy time — credentials land in
`/home/$USERNAME/.credentials`.

## Blob storage options

Langfuse requires S3-compatible storage for raw event payloads. This app offers two paths:

- **Default (no extra fields):** a bundled MinIO container on a local volume, loopback-only.
  Fully self-contained. Multimodal media uploads are disabled on this path (they require a
  client-reachable storage endpoint).
- **Linode Object Storage (recommended for production):** pre-create a bucket and an access key
  ([docs](https://techdocs.akamai.com/cloud-computing/docs/object-storage)), then fill in the
  four optional Object Storage fields at deploy time. MinIO is omitted entirely; event data,
  multimodal media, and batch exports are served from your bucket over HTTPS.

Switching after deployment is possible (edit `/opt/langfuse/docker-compose.yml`) but events
already written to MinIO stay there — there is no built-in migration. Choose at deploy time.

## Sizing

Upstream recommends at least 4 cores / 16 GiB RAM / 100 GiB storage for the compose deployment
(ClickHouse is the memory driver) — use a 16 GB plan or larger.

## After deployment

1. Log in at `https://<your-domain>/` with the email you provided and the generated password
   from `.credentials`.
2. Point your SDKs at the instance with the generated project keys:
   `LANGFUSE_HOST=https://<your-domain>`, `LANGFUSE_PUBLIC_KEY=pk-lf-…`,
   `LANGFUSE_SECRET_KEY=sk-lf-…`.
3. Optional: configure SMTP (`EMAIL_FROM_ADDRESS`, `SMTP_CONNECTION_URL` in
   `/opt/langfuse/docker-compose.yml`) to enable password resets and invites — see
   https://langfuse.com/self-hosting/configuration.
