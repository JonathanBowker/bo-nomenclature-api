#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${SUPABASE_URL:?SUPABASE_URL must be set}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY must be set}"

echo "Fetching constraint set..."
constraint_response="$(curl -sS \
  "${BASE_URL}/functions/v1/resolve-constraints?domainId=20000000-0000-0000-0000-000000000004&destination=video&locale=en-GB" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}")"

echo "${constraint_response}"

echo
echo "Validating generated output with prohibited variant..."
validation_response="$(curl -sS \
  -X POST "${BASE_URL}/functions/v1/validate" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  --data '{"domainId":"20000000-0000-0000-0000-000000000004","destination":"video","candidate":"PricewaterhouseCoopers"}')"

echo "${validation_response}"
