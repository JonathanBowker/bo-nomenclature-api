#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${SUPABASE_URL:?SUPABASE_URL must be set}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:?SUPABASE_SERVICE_ROLE_KEY must be set}"

echo "Resolving inherited terms for leaf domain..."
curl -sS \
  "${BASE_URL}/functions/v1/resolved-terms?domainId=20000000-0000-0000-0000-000000000004&destination=video&locale=en-GB" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"

echo
echo "Resolving constraint set for the same leaf domain..."
curl -sS \
  "${BASE_URL}/functions/v1/resolve-constraints?domainId=20000000-0000-0000-0000-000000000004&destination=video&locale=en-GB" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
