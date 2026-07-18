#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path

path = Path("specs/001-nomenclature-api/contracts/graphql-schema.graphql")
schema = path.read_text()

required = [
    "type Query",
    "resolvedTerms(",
    "constraintSet(",
    "type ResolvedTerm",
    "type ConstraintSet",
]

for marker in required:
    if marker not in schema:
        raise SystemExit(f"Missing GraphQL marker: {marker}")

print("GraphQL schema verified:", path)
PY
