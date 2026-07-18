#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${SUPABASE_URL:?SUPABASE_URL must be set}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY must be set}"

call() {
  local method="$1"
  local url="$2"
  local data="${3:-}"
  if [[ -n "$data" ]]; then
    curl -sS -X "$method" "$url" \
      -H "Content-Type: application/json" \
      -H "apikey: ${SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
      --data "$data"
  else
    curl -sS -X "$method" "$url" \
      -H "apikey: ${SERVICE_ROLE_KEY}" \
      -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
  fi
}

echo "Smoke: validate"
call POST "${BASE_URL}/functions/v1/validate" '{"domainId":"20000000-0000-0000-0000-000000000004","destination":"video","candidate":"PwC"}'
echo
echo
echo "Smoke: record approval"
call POST "${BASE_URL}/functions/v1/record-approval" '{"termId":"30000000-0000-0000-0000-000000000001","destination":"social","status":"approved","comment":"smoke test approval"}'
echo
echo
echo "Smoke: resolve constraints"
call GET "${BASE_URL}/functions/v1/resolve-constraints?domainId=20000000-0000-0000-0000-000000000004&destination=video&locale=en-GB"
echo
