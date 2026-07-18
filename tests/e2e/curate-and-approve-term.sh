#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${SUPABASE_URL:?SUPABASE_URL must be set}"
ANON_KEY="${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY must be set}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY must be set}"

term_payload='{
  "tenant_id":"10000000-0000-0000-0000-000000000001",
  "domain_id":"20000000-0000-0000-0000-000000000004",
  "canonical_text":"Brand Oracle Concierge",
  "category":"service_name",
  "approval_state":"draft",
  "source_reference":"guideline:concierge-name"
}'

echo "Creating term via REST..."
term_response="$(curl -sS \
  -X POST "${BASE_URL}/rest/v1/terms" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "Prefer: return=representation" \
  --data "${term_payload}")"

echo "${term_response}"
term_id="$(TERM_RESPONSE="${term_response}" python3 - <<'PY'
import json, os
payload = json.loads(os.environ["TERM_RESPONSE"])
row = payload[0] if isinstance(payload, list) else payload
print(row["id"])
PY
)"

echo
echo "Recording approval via Edge Function..."
approval_response="$(curl -sS \
  -X POST "${BASE_URL}/functions/v1/record-approval" \
  -H "Content-Type: application/json" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H "x-audit-reason: Initial social approval" \
  --data "{\"termId\":\"${term_id}\",\"destination\":\"social\",\"status\":\"approved\",\"comment\":\"Approved for launch social assets\"}")"

echo "${approval_response}"

echo
echo "Reading audit history..."
curl -sS \
  "${BASE_URL}/rest/v1/audit_entries?entity_type=eq.approvals&limit=5" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
