#!/bin/bash
# CI UDF defaults for langfuse. Sourced before the deploy script so required UDF vars
# have sensible values when not explicitly set. Object Storage fields default empty so CI
# exercises the bundled-MinIO path.

DEFAULT_DNS="$(hostname -I | awk '{print $1}' | tr '.' '-' | awk '{print $1 ".ip.linodeusercontent.com"}')"

declare -A UDF_VARS

if [[ -n "${USER_NAME:-}" ]]; then UDF_VARS["USER_NAME"]="${USER_NAME}"; else UDF_VARS["USER_NAME"]="admin"; fi
if [[ -n "${DISABLE_ROOT:-}" ]]; then UDF_VARS["DISABLE_ROOT"]="${DISABLE_ROOT}"; else UDF_VARS["DISABLE_ROOT"]="No"; fi
if [[ -n "${TOKEN_PASSWORD:-}" ]]; then UDF_VARS["TOKEN_PASSWORD"]="${TOKEN_PASSWORD}"; else UDF_VARS["TOKEN_PASSWORD"]=""; fi
if [[ -n "${SUBDOMAIN:-}" ]]; then UDF_VARS["SUBDOMAIN"]="${SUBDOMAIN}"; else UDF_VARS["SUBDOMAIN"]=""; fi
if [[ -n "${DOMAIN:-}" ]]; then UDF_VARS["DOMAIN"]="${DOMAIN}"; else UDF_VARS["DOMAIN"]=""; fi
if [[ -n "${SOA_EMAIL_ADDRESS:-}" ]]; then UDF_VARS["SOA_EMAIL_ADDRESS"]="${SOA_EMAIL_ADDRESS}"; else UDF_VARS["SOA_EMAIL_ADDRESS"]="admin@${DEFAULT_DNS#*.}"; fi
if [[ -n "${USER_EMAIL:-}" ]]; then UDF_VARS["USER_EMAIL"]="${USER_EMAIL}"; else UDF_VARS["USER_EMAIL"]="admin@${DEFAULT_DNS#*.}"; fi
# Object Storage: empty in CI -> bundled MinIO path
if [[ -n "${OBJ_BUCKET:-}" ]]; then UDF_VARS["OBJ_BUCKET"]="${OBJ_BUCKET}"; else UDF_VARS["OBJ_BUCKET"]=""; fi
if [[ -n "${OBJ_ENDPOINT:-}" ]]; then UDF_VARS["OBJ_ENDPOINT"]="${OBJ_ENDPOINT}"; else UDF_VARS["OBJ_ENDPOINT"]=""; fi
if [[ -n "${OBJ_ACCESS_KEY:-}" ]]; then UDF_VARS["OBJ_ACCESS_KEY"]="${OBJ_ACCESS_KEY}"; else UDF_VARS["OBJ_ACCESS_KEY"]=""; fi
if [[ -n "${OBJ_SECRET_KEY:-}" ]]; then UDF_VARS["OBJ_SECRET_KEY"]="${OBJ_SECRET_KEY}"; else UDF_VARS["OBJ_SECRET_KEY"]=""; fi

set_vars() {
	for key in "${!UDF_VARS[@]}"; do
		export "${key}"="${UDF_VARS[$key]}"
	done
}

set_vars
