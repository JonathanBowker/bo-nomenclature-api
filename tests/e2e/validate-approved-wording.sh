#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${SUPABASE_URL:-http://127.0.0.1:54321}"
ANON_KEY="${SUPABASE_ANON_KEY:-}"

if [[ -z "${ANON_KEY}" ]]; then
  echo "SUPABASE_ANON_KEY must be set"
  exit 1
fi

approved_response="$(curl -sS \
  -X POST "${BASE_URL}/functions/v1/validate" \
  -H "Content-Type: application/json" \
  -H "apikey: ${ANON_KEY}" \
  --data '{"domainId":"20000000-0000-0000-0000-000000000004","destination":"video","candidate":"PwC"}')"

echo "Approved response:"
echo "${approved_response}"

prohibited_response="$(curl -sS \
  -X POST "${BASE_URL}/functions/v1/validate" \
  -H "Content-Type: application/json" \
  -H "apikey: ${ANON_KEY}" \
  --data '{"domainId":"20000000-0000-0000-0000-000000000004","destination":"video","candidate":"PricewaterhouseCoopers"}')"

echo
echo "Prohibited response:"
echo "${prohibited_response}"
