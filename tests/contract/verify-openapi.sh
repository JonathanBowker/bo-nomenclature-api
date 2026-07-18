#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import yaml
from pathlib import Path

path = Path("specs/001-nomenclature-api/contracts/openapi.yaml")
with path.open() as handle:
    data = yaml.safe_load(handle)

assert "paths" in data and data["paths"], "OpenAPI spec has no paths"
assert "/functions/v1/validate" in data["paths"], "Missing validation endpoint"
assert "/functions/v1/resolve-constraints" in data["paths"], "Missing constraint endpoint"
assert "/functions/v1/resolved-terms" in data["paths"], "Missing resolved-terms endpoint"

print("OpenAPI contract verified:", len(data["paths"]), "paths")
PY
