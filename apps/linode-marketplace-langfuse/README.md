# Langfuse Quick Deploy App

Langfuse is an open-source LLM engineering platform for tracing, evaluating, and debugging AI
applications — observability, evals, prompt management, and metrics for teams building with LLMs.
This Marketplace App deploys Langfuse (latest v3) on Ubuntu 24.04 via Docker Compose, behind
nginx with a Let's Encrypt certificate and Langfuse's native email/password login (public
signup disabled; the admin account is provisioned at deploy time).

Event payloads require S3-compatible storage. By default the app runs a bundled, loopback-only
MinIO container — fully self-contained. Optionally, provide the four Object Storage fields at
deploy time (bucket, S3 endpoint, access key, secret key — all four or none; the bucket must
already exist) to use [Linode Object Storage](https://techdocs.akamai.com/cloud-computing/docs/object-storage)
instead: MinIO is omitted entirely and multimodal media uploads (trace attachments: images,
audio, PDFs) are enabled, served via presigned URLs from your bucket. Media uploads are disabled
on the MinIO path because they require a client-reachable storage endpoint.

## Software Included

| Software | Version | Description |
| :---     | :----   | :---        |
| Langfuse | latest (v3.206 at time of testing) | LLM engineering platform (web app + async worker) |
| PostgreSQL | 17 | Transactional data store |
| ClickHouse | latest | OLAP store for traces/observations |
| Redis | 7 | Cache + ingestion queue |
| MinIO | latest | S3-compatible blob storage (default path only; omitted when Object Storage is configured) |
| Docker CE | latest | Container runtime (Compose v2 project) |
| nginx | 1.24 | Web server / reverse proxy |
| certbot | latest | Let's Encrypt TLS certificate client |

**Supported Distributions:**

- Ubuntu 24.04 LTS

## Linode Helpers Included

| Name  | Action  |
| :---  | :---    |
| Hostname | Assigns a hostname to the Linode based on the domain provided via UDF, or uses the default rDNS. For consistency, DNS and SSL configurations use the Hostname-generated `_domain` var. |
| Sudo User | Creates a limited `sudo` user from the UDF-supplied `username` and generates its password. Usernames containing illegal characters will cause the play to fail. |
| SSH Key | Writes a UDF-supplied SSH pubkey to `/home/$username/.ssh/authorized_keys`. To add an SSH key to `root`, use [Cloud Manager SSH Keys](https://www.linode.com/docs/products/tools/cloud-manager/guides/manage-ssh-keys/). |
| Secure SSH | Standard SSH hardening — writes to `/etc/ssh/sshd_config` to disable password auth and require public-key auth (applied only when `disable_root` is set). |
| Update Packages | Performs standard apt update and upgrade actions as root. |
| UFW | Imports `ufw_rules.yml` (22, 80, 443) and enables the firewall. All stack services (PostgreSQL, ClickHouse, Redis, MinIO, the app itself) bind to loopback and are not exposed. |
| Fail2Ban | Installs, activates, and enables the Fail2Ban service. |
| Docker | Installs Docker CE + Compose v2 plugin (runs the Langfuse compose project). |
| Certbot SSL | Handles SSL/TLS certificate issuance via Let's Encrypt against nginx. |
| Addons | Optional monitoring/observability exporters (`newrelic`, `node_exporter`, `opentelemetry_collector`, `alloy`). |

## Post-Deployment

When the playbook finishes, the operator can:

- Browse to Langfuse at `https://<domain-or-rdns>/` and log in with the admin email provided at
  deploy time (`user_email` UDF) and the generated password.
- Read the generated credentials from `/home/<sudo_user>/.credentials`. The file contains:
  - Sudo username + password
  - Langfuse admin login (email) + password
  - Langfuse project API keypair (`pk-lf-…` / `sk-lf-…`) for SDK/OpenTelemetry clients
  - The blob-storage configuration in effect (bundled MinIO, or your Object Storage bucket)
- Send a first trace using the project keys — point any [Langfuse SDK](https://langfuse.com/docs/observability/get-started)
  at the instance with `LANGFUSE_HOST=https://<domain-or-rdns>`, `LANGFUSE_PUBLIC_KEY`, and
  `LANGFUSE_SECRET_KEY` from the credentials file, then watch it appear under **Tracing**.
- Optional: configure SMTP (`EMAIL_FROM_ADDRESS`, `SMTP_CONNECTION_URL` in
  `/opt/langfuse/docker-compose.yml`) to enable password resets and email invites — see the
  [self-hosting configuration reference](https://langfuse.com/self-hosting/configuration).

Public signup is disabled (`AUTH_DISABLE_SIGNUP=true`); add team members via organization
invites in the UI. Upstream recommends at least 4 cores / 16 GiB RAM / 100 GiB storage for this
stack (ClickHouse is the memory driver) — use a 16 GB plan or larger.

<!-- REVIEW: confirm post-deploy wording + credential file contents against a fresh deploy before submitting. -->

## Use our API

Customers can deploy Langfuse through the Linode Marketplace or directly using the API. Before using the commands below, create an [API token](https://www.linode.com/docs/products/tools/linode-api/get-started/#create-an-api-token) or configure [linode-cli](https://www.linode.com/products/cli/), and substitute your own values for the defaults.

SHELL:
```
curl -H "Content-Type: application/json" \
-H "Authorization: Bearer $TOKEN" \
-X POST -d '{
    "image": "linode/ubuntu24.04",
    "region": "us-southeast",
    "type": "g6-standard-6",
    "label": "langfuse-occ-us-southeast",
    "tags": [],
    "root_pass": "A_Secure_Password",
    "authorized_users": [
        "user1",
        "user2"
    ],
    "booted": true,
    "backups_enabled": false,
    "private_ip": false,
    "stackscript_id": 00000,
    "stackscript_data": {
        "soa_email_address": "email@domain.tld",
        "user_name": "sudo_user",
        "user_email": "admin@domain.tld",
        "disable_root": "No",
        "token_password": "A_Valid_API_Token",
        "subdomain": "examplesubdomain",
        "domain": "domain.tld",
        "add_ons": "none",
        "obj_bucket": "",
        "obj_endpoint": "",
        "obj_access_key": "",
        "obj_secret_key": ""
    }
}' https://api.linode.com/v4/linode/instances
```
<!-- REVIEW: replace stackscript_id 00000 with the published Marketplace StackScript ID. The four obj_* fields are optional — set ALL FOUR (pre-created bucket) to use Linode Object Storage, or leave all empty for bundled MinIO. -->

CLI:
```
linode-cli linodes create \
  --image 'linode/ubuntu24.04' \
  --region us-southeast \
  --type g6-standard-6 \
  --label langfuse-occ-us-southeast \
  --root_pass A_Secure_Password \
  --authorized_users user1 \
  --authorized_users user2 \
  --booted true \
  --backups_enabled false \
  --private_ip false \
  --stackscript_id 000000 \
  --stackscript_data '{"soa_email_address":"email@domain.tld","user_name":"sudo_user","user_email":"admin@domain.tld","disable_root":"No","token_password":"A_Valid_API_Token","subdomain":"examplesubdomain","domain":"domain.tld","add_ons":"none","obj_bucket":"","obj_endpoint":"","obj_access_key":"","obj_secret_key":""}'
```

## Resources

- [Langfuse Documentation](https://langfuse.com/docs)
- [Langfuse Self-Hosting Guide](https://langfuse.com/self-hosting)
- [Langfuse Repository](https://github.com/langfuse/langfuse)
- [Linode Object Storage](https://techdocs.akamai.com/cloud-computing/docs/object-storage)
