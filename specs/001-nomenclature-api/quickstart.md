# Quickstart: Nomenclature API

## Purpose

This guide defines the validation scenarios that must work end to end for the first release. It is intended for implementers and reviewers validating the feature, not as production user documentation.

## Prerequisites

- Supabase CLI installed
- Docker available for local Supabase services
- Environment variables configured for Supabase project access
- Supabase migrations applied
- Seed data loaded for one test tenant with:
  - A four-level brand hierarchy
  - One term approved for `video`
  - One prohibited variant for that same term
  - One destination-specific approval with expiry coverage

## Setup

1. Install project dependencies.
2. Start the local Supabase stack with `supabase start`.
3. Apply schema migrations and seed data with `supabase db reset`.
4. Serve the functions `validate`, `record-approval`, and `resolve-constraints` with `supabase functions serve ... --env-file .env`.
5. Confirm the reference dataset is present.

Expected result: local Supabase REST, GraphQL, and Edge Function endpoints are reachable and the reference dataset is queryable.

## Scenario 1: Validate approved wording

1. Submit a validation request for the approved term in the correct destination.
2. Confirm the result is `approved`.
3. Confirm the response includes the approved canonical text and any first-mention copyright guidance.

Reference contract:
- REST: `POST /functions/v1/validate`
- GraphQL: `validateCandidate`

Expected result: the request succeeds and no violation payload is returned.

## Scenario 2: Detect a prohibited variant

1. Submit the prohibited variant for the same domain and destination.
2. Confirm the result is `not_approved`.
3. Confirm the response identifies the matched prohibited variant and returns the approved correction.

Reference contract:
- REST: `POST /functions/v1/validate`
- GraphQL: `validateCandidate`

Expected result: the request succeeds and the correction data matches the seeded approved term.

## Scenario 3: Reject usage for an unapproved destination

1. Submit the approved wording for a destination where no active approval exists.
2. Confirm the result is `not_approved`.
3. Confirm the response explains that the term lacks active approval in the requested destination.

Expected result: destination-specific approval is enforced independently of term existence.

## Scenario 4: Resolve inherited rules

1. Request resolved terms for a leaf domain in the seeded four-level hierarchy.
2. Confirm inherited rules from ancestors are present.
3. Confirm a conflicting leaf-level rule overrides the ancestor rule and that the override is visible in the response.

Reference contract:
- REST: `GET /functions/v1/resolved-terms`
- GraphQL: `resolvedTerms`

Expected result: effective rules are deterministic and explainable.

## Scenario 5: Record approvals and audit history

1. Create or update a term.
2. Record an approval for one destination.
3. Query audit history for the term.
4. Confirm change history includes the term mutation and the approval event.

Reference contract:
- REST: `POST /rest/v1/terms`, `PATCH /rest/v1/terms?id=eq.<term-id>`, `POST /functions/v1/record-approval`, `GET /rest/v1/audit_entries`
- GraphQL: `createTerm`, `updateTerm`, `recordApproval`, `auditEntries`

Expected result: all accepted mutations are attributable and retrievable.

## Scenario 6: Retrieve constraints for AI-governed generation

1. Request the active constraint set for a domain and destination.
2. Confirm the response includes approved terms, prohibited variants, and applicable rules.
3. Use that response as the basis for a generated validation pass.

Reference contract:
- REST: `GET /functions/v1/resolve-constraints`
- GraphQL: `constraintSet`

Expected result: downstream systems receive all required nomenclature guidance without additional lookups.

## Acceptance Commands

The validation flow is expected to cover:

1. Local Supabase startup
2. Database migration
3. Edge Function serve or deploy
4. Seed-data load
5. Contract tests
6. End-to-end tests

Suggested commands:

```bash
supabase start
supabase db reset
supabase functions serve validate --env-file .env
supabase functions serve record-approval --env-file .env
supabase functions serve resolve-constraints --env-file .env
tests/contract/verify-openapi.sh
tests/contract/verify-graphql-schema.sh
tests/e2e/validate-approved-wording.sh
tests/e2e/curate-and-approve-term.sh
tests/e2e/retrieve-constraints-and-validate-output.sh
tests/e2e/resolve-inherited-rules.sh
```

## Exit Criteria

- All six scenarios pass in both local validation and CI.
- Contract tests match the published REST and GraphQL artifacts.
- Audit history is created for every accepted mutation exercised above.
