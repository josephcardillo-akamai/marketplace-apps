<!--
Template: STANDARD marketplace app README (service / CMS / HashiCorp-style).
Fill every <placeholder> from the validated artifacts. Delete this comment block.
This README is a STARTING POINT — the operator must review it before the PR is final.
References for tone/structure: linode-marketplace-hashicorp-nomad, -hashicorp-vault (READMEs).
-->

# <App Name> Marketplace App

Deploy [<App Name>](<upstream-url>) on Akamai Cloud Compute — <one-line description of what the
app does and who it's for>.

## What gets deployed

- <App Name> <version> installed via <install method>, running as a systemd service.
- nginx reverse proxy with a Let's Encrypt certificate (HTTP→HTTPS redirect).
- <auth model: native login / nginx basic-auth outer layer / mTLS — and why>.
- A limited sudo user; UFW (22, 80, 443<, app ports>); fail2ban.
- Generated credentials written to `/home/<user>/.credentials`.

## Deployment options (UDFs)

| Field | Description | Default |
|---|---|---|
| Limited sudo user | The non-root user created on the instance | — |
| Disable root SSH | Harden SSH to key-only, no root | No |
| Domain / Subdomain | FQDN for the TLS certificate | — |
| <app-specific UDF> | <description> | <default> |

## Getting started after deploy

1. SSH in (or use LISH) and read `/home/<user>/.credentials`.
2. Browse to `https://<subdomain>.<domain>` and log in with the generated admin credentials.
3. <first-run guidance — what to do next>.

<!-- REVIEW: confirm the first-run steps against the actual deployed box. -->

## Sample workload / verification

<A concrete thing the user can do to confirm it works — a sample config, a test request, etc.>
<!-- REVIEW: replace with a real, tested example from e2e_testing.md. -->

## Scaling & operations

- <vertical scaling notes / where data lives / backup pointers>.
- <how to renew certs (certbot timer), where logs are>.

## Software included

| Software | Version | License |
|---|---|---|
| <App Name> | <version> | <license> |
| nginx | <version> | BSD-2-Clause |
| certbot | <version> | Apache-2.0 |

## Documentation

- Upstream: <docs-url>
- Akamai Marketplace docs: <marketplace-doc-url-if-any>
