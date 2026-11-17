#!/usr/bin/env bash
set -euo pipefail

credential_path=${GOOGLE_APPLICATION_CREDENTIALS:-}
if [[ ! -f "$credential_path" || ! -r "$credential_path" ]]; then
  printf '%s\n' 'Set GOOGLE_APPLICATION_CREDENTIALS to your Firebase service account JSON file.' >&2
  exit 1
fi

if [[ -z ${BADAL_ADMIN_PASSWORD:-} ]]; then
  if [[ ! -t 0 ]]; then
    printf '%s\n' 'Run this command in a terminal to enter the new admin password.' >&2
    exit 1
  fi
  IFS= read -r -s -p 'New admin password: ' BADAL_ADMIN_PASSWORD
  printf '\n' >&2
fi

BADAL_ADMIN_PASSWORD="$BADAL_ADMIN_PASSWORD" exec node "$(dirname "$0")/setup-admin.mjs"
