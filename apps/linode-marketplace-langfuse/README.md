# Langfuse Quick Deploy App

Langfuse is an open-source LLM engineering and observability platform for tracing, monitoring,
evaluating, and debugging LLM/agent applications. This Marketplace App deploys Langfuse (`latest`,
v3.207.0 at time of testing) on Ubuntu 24.04 via Docker Compose, behind nginx with a Let's Encrypt
certificate and Langfuse's native login (single sign-in layer, self-registration disabled).

The admin user, a default organization/project, and the project API keys are generated at deploy
time and written to `/home/<sudo_user>/.credentials` — there is no setup wizard to complete.

## Software Included

| Software | Version | Description |
| :---     | :----   | :---        |
| Langfuse | latest (v3.207.0) | LLM engineering / observability platform (web + async worker) |
| PostgreSQL | 17 | Transactional database (loopback only) |
| ClickHouse | 24.12 | OLAP store for traces, observations, and scores (loopback only) |
| Redis | 7 | Cache and queue (loopback only) |
| MinIO | latest | S3-compatible blob store for events (bundled; used unless Linode Object Storage is supplied) |
| Docker CE | latest | Container runtime for the Compose stack |
| nginx | 1.24 | Web server / reverse proxy (TLS termination) |
| certbot | 2.x | Let's Encrypt TLS certificate client |

**Supported Distributions:**

- Ubuntu 24.04 LTS

## Linode Helpers Included

| Name  | Action  |
| :---  | :---    |
| Hostname | Assigns a hostname based on the domain provided via UDF, or uses the default rDNS. DNS and SSL configurations use the Hostname-generated `_domain` var. |
| Create DNS Record | Creates DNS A records for the domain/subdomain via the Linode API when an API token is supplied. |
| Sudo User | Creates a limited `sudo` user from the UDF-supplied `user_name` and generates its password. |
| SSH Key | Writes a UDF-supplied SSH pubkey to `/home/$username/.ssh/authorized_keys`. |
| Secure SSH | Standard SSH hardening (disables password auth / root login) — applied only when `disable_root` is set. |
| Update Packages | Performs standard apt update and upgrade actions as root. |
| UFW | Imports `ufw_rules.yml` (22, 80, 443) and enables the firewall. Database, cache, and object-store ports are bound to `127.0.0.1` and are not exposed. |
| Fail2Ban | Installs, activates, and enables the Fail2Ban service. |
| Docker | Installs Docker CE (used to run the Langfuse Compose project). |
| Certbot SSL | Handles SSL/TLS certificate issuance via Let's Encrypt against nginx. |

## Blob Storage: bundled MinIO or Linode Object Storage

Langfuse requires S3-compatible blob storage. This app offers two paths, selected by the Object
Storage UDFs:

- **Bundled MinIO (default):** leave the Object Storage UDFs empty. A local MinIO container provides
  mandatory event storage. No prerequisites.
- **Linode Object Storage:** fill in **all four** Object Storage UDFs (`obj_bucket`, `obj_endpoint`,
  `obj_access_key`, `obj_secret_key`). The bucket must **already exist** and the key must have
  read/write access to it — the playbook validates this **before** installing and aborts early if the
  bucket is unreachable. This path also enables multi-modal media uploads (served via presigned URLs
  over the public Object Storage endpoint).

## Post-Deployment

When the playbook finishes, the operator can:

- Browse to Langfuse at `https://<domain-or-rdns>/` and sign in with the admin credentials.
- Read the generated credentials from `/home/<sudo_user>/.credentials`. The file contains:
  - App URL
  - Langfuse admin login email + password
  - Default project API keys (public `pk-lf-…` + secret `sk-lf-…`)
  - Sudo username + password
  - Which blob-storage backend is in use (bundled MinIO or the named Object Storage bucket)
- Point an application/SDK at `https://<domain-or-rdns>` using the project API keys, then watch
  traces appear under the default project. See the [Langfuse quickstart](https://langfuse.com/docs/get-started).

<!-- REVIEW: confirm the post-deploy steps + credential contents against the deployed box. -->

## Use our API

Customers can deploy Langfuse through the Linode Marketplace or directly using the API. Before using
the commands below, create an [API token](https://www.linode.com/docs/products/tools/linode-api/get-started/#create-an-api-token)
or configure [linode-cli](https://www.linode.com/products/cli/), and substitute your own values.

<!-- REVIEW: replace stackscript_id 00000 with the Marketplace-assigned StackScript ID. Object
     Storage UDFs (obj_bucket/obj_endpoint/obj_access_key/obj_secret_key) are optional — omit for the
     bundled MinIO path, or add all four for Linode Object Storage. -->

SHELL:
```
curl -H "Content-Type: application/json" \
-H "Authorization: ******" \
-X POST -d '{
    "image": "linode/ubuntu24.04",
    "region": "us-southeast",
    "type": "g6-standard-4",
    "label": "langfuse-occ-us-southeast",
    "tags": [],
    "root_pass": "A_Secure_Password",
    "authorized_users": [
        "user1"
    ],
    "booted": true,
    "backups_enabled": false,
    "private_ip": false,
    "stackscript_id": 00000,
    "stackscript_data": {
        "user_name": "sudo_user",
        "disable_root": "No",
        "token_password": "A_Valid_API_Token",
        "subdomain": "examplesubdomain",
        "domain": "domain.tld",
        "soa_email_address": "email@domain.tld",
        "user_email": "admin@domain.tld"
    }
}' https://api.linode.com/v4/linode/instances
```

CLI:
```
linode-cli linodes create \
  --image 'linode/ubuntu24.04' \
  --region us-southeast \
  --type g6-standard-4 \
  --label langfuse-occ-us-southeast \
  --root_pass A_Secure_Password \
  --authorized_users user1 \
  --booted true \
  --backups_enabled false \
  --private_ip false \
  --stackscript_id 000000 \
  --stackscript_data '{"user_name":"sudo_user","disable_root":"No","token_password":"A_Valid_API_Token","subdomain":"examplesubdomain","domain":"domain.tld","soa_email_address":"email@domain.tld","user_email":"admin@domain.tld"}'
```

## Resources

- [Langfuse Documentation](https://langfuse.com/docs)
- [Langfuse Self-Hosting Guide](https://langfuse.com/self-hosting)
- [Langfuse Repository](https://github.com/langfuse/langfuse)
