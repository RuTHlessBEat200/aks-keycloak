#!/usr/bin/env bash
# Decrypts ejson/secrets.ejson and flattens the "keycloak" object into the
# flat string-map that Terraform's `external` data source requires.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EJSON_FILE="${SCRIPT_DIR}/../../ejson/secrets.ejson"

decrypted="$(ejson decrypt "${EJSON_FILE}")"

jq -c '.keycloak' <<<"${decrypted}"
