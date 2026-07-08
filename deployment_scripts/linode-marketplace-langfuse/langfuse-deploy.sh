#!/bin/bash

# enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# BEGIN CI-MODE
# modes
#DEBUG="NO"
if [[ -n ${DEBUG} ]]; then
	if [ "${DEBUG}" == "NO" ]; then
		trap "cleanup $? $LINENO" EXIT
	fi
else
	trap "cleanup $? $LINENO" EXIT
fi

if [ "${MODE}" == "staging" ]; then
	trap "provision_failed $? $LINENO" ERR
else
	set -e
fi
# END CI-MODE

## Linode/SSH security settings
#<UDF name="user_name" label="The limited sudo user to be created for the Linode: *No Capital Letters or Special Characters*">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your server's DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for the DNS record: www (Requires Domain)" default="">
#<UDF name="domain" label="Domain" example="The domain for the DNS record: example.com (Requires API token)" default="">
#<UDF name="soa_email_address" label="Email address (for the Let's Encrypt SSL certificate)" example="user@domain.tld">

## Langfuse settings
#<UDF name="user_email" label="Email address for the Langfuse admin login" example="admin@domain.tld">

## Optional: Linode Object Storage (fill in ALL FOUR fields or NONE - enables multimodal media uploads; otherwise a bundled local MinIO is used)
#<UDF name="obj_bucket" label="Object Storage bucket name (optional; must already exist)" default="">
#<UDF name="obj_endpoint" label="Object Storage S3 endpoint (optional)" example="us-ord-1.linodeobjects.com" default="">
#<UDF name="obj_access_key" label="Object Storage access key (optional)" default="">
#<UDF name="obj_secret_key" label="Object Storage secret key (optional)" default="">

# BEGIN CI-GH
#GH_USER=""
#BRANCH=""
# git user and branch
if [[ -n ${GH_USER} && -n ${BRANCH} ]]; then
	echo "[info] git user and branch set.."
	export GIT_REPO="https://github.com/${GH_USER}/marketplace-apps.git"
else
	export GH_USER="akamai-compute-marketplace"
	export BRANCH="main"
	export GIT_REPO="https://github.com/${GH_USER}/marketplace-apps.git"
fi
# END CI-GH

export WORK_DIR="/tmp/marketplace-apps"
export MARKETPLACE_APP="apps/linode-marketplace-langfuse"
export DEBIAN_FRONTEND=noninteractive

function provision_failed {
	echo "[info] Provision failed. Sending status.."

	# dep
	apt install jq -y

	# set token
	local token=($(curl -ks -X POST ${KC_SERVER} \
		-H "Content-Type: application/json" \
		-d "{ \"username\":\"${KC_USERNAME}\", \"password\":\"${KC_PASSWORD}\" }" | jq -r .token))

	# send pre-provision failure
	curl -sk -X POST ${DATA_ENDPOINT} \
		-H "Authorization: ${token}" \
		-H "Content-Type: application/json" \
		-d "{ \"app_label\":\"${APP_LABEL}\", \"status\":\"provision_failed\", \"branch\": \"${BRANCH}\", \
        \"gituser\": \"${GH_USER}\", \"runjob\": \"${RUNJOB}\", \"image\":\"${IMAGE}\", \
        \"type\":\"${TYPE}\", \"region\":\"${REGION}\", \"instance_env\":\"${INSTANCE_ENV}\" }"

	exit $?
}

function cleanup {
	if [ -d "${WORK_DIR}" ]; then
		rm -rf ${WORK_DIR}
	fi
}

function obj_check {
	# Object Storage is all-or-nothing: a partial set of fields fails fast here rather than
	# producing a half-configured deployment.
	local set_count=0
	[[ -n ${OBJ_BUCKET} ]] && set_count=$((set_count + 1))
	[[ -n ${OBJ_ENDPOINT} ]] && set_count=$((set_count + 1))
	[[ -n ${OBJ_ACCESS_KEY} ]] && set_count=$((set_count + 1))
	[[ -n ${OBJ_SECRET_KEY} ]] && set_count=$((set_count + 1))
	if [[ ${set_count} -gt 0 && ${set_count} -lt 4 ]]; then
		echo "[error] Linode Object Storage requires ALL FOUR fields (bucket, endpoint, access key, secret key) - only ${set_count} provided. Fill in all four or leave all empty to use the bundled MinIO."
		exit 1
	fi
}

function udf {
	local group_vars="${WORK_DIR}/${MARKETPLACE_APP}/group_vars/linode/vars"
	sed 's/  //g' <<EOF >${group_vars}
  # sudo username
  username: ${USER_NAME}
EOF

	# boolean conversion - UDFs arrive as strings; only define disable_root when hardening is wanted
	if [ "$DISABLE_ROOT" = "Yes" ]; then
		echo "disable_root: true" >>${group_vars}
	else
		echo "Leaving root login enabled"
	fi

	if [[ -n ${SUBDOMAIN} ]]; then
		echo "subdomain: ${SUBDOMAIN}" >>${group_vars}
	fi

	if [[ -n ${DOMAIN} ]]; then
		echo "domain: ${DOMAIN}" >>${group_vars}
	else
		echo "default_dns: $(hostname -I | awk '{print $1}' | tr '.' '-' | awk {'print $1 ".ip.linodeusercontent.com"'})" >>${group_vars}
	fi

	if [[ -n ${TOKEN_PASSWORD} ]]; then
		echo "token_password: ${TOKEN_PASSWORD}" >>${group_vars}
	else
		echo "No API token entered"
	fi

	if [[ -n ${SOA_EMAIL_ADDRESS} ]]; then
		echo "soa_email_address: ${SOA_EMAIL_ADDRESS}" >>${group_vars}
	else
		echo "No SOA email entered"
	fi

	if [[ -n ${USER_EMAIL} ]]; then
		echo "user_email: ${USER_EMAIL}" >>${group_vars}
	fi

	# Object Storage (all-or-nothing; validated by obj_check). Region is derived from the endpoint.
	if [[ -n ${OBJ_BUCKET} ]]; then
		OBJ_ENDPOINT="${OBJ_ENDPOINT#https://}"
		OBJ_ENDPOINT="${OBJ_ENDPOINT#http://}"
		OBJ_ENDPOINT="${OBJ_ENDPOINT%/}"
		echo "obj_bucket: ${OBJ_BUCKET}" >>${group_vars}
		echo "obj_endpoint: ${OBJ_ENDPOINT}" >>${group_vars}
		echo "obj_region: ${OBJ_ENDPOINT%%.*}" >>${group_vars}
		echo "obj_access_key: ${OBJ_ACCESS_KEY}" >>${group_vars}
		echo "obj_secret_key: ${OBJ_SECRET_KEY}" >>${group_vars}
	fi

	# staging or production mode (ci)
	if [[ "${MODE}" == "staging" ]]; then
		echo "[info] running in staging mode..."
		echo "mode: ${MODE}" >>${group_vars}
	else
		echo "[info] running in production mode..."
		echo "mode: production" >>${group_vars}
	fi
}

function run {
	# validate Object Storage inputs before doing any work
	obj_check

	# install dependencies
	apt-get update
	apt-get install -y git python3 python3-pip

	# clone repo and set up ansible environment
	git -C /tmp clone -b ${BRANCH} ${GIT_REPO}

	# set up python virtual environment
	cd ${WORK_DIR}/${MARKETPLACE_APP}
	apt install python3-venv -y
	python3 -m venv env
	source env/bin/activate
	pip install pip --upgrade
	pip install -r requirements.txt
	ansible-galaxy install -r collections.yml

	# populate group_vars
	udf
	# run playbooks
	export ANSIBLE_HOST_KEY_CHECKING=False
	ansible-playbook -v provision.yml && ansible-playbook -v site.yml
}

function installation_complete {
	echo "Installation Complete"
}

# main
run
installation_complete
