# bo-nomenclature-api

Supabase-backed nomenclature platform for governed brand terminology, validation, and downstream AI workflow consumption.

## Local development

1. Start the local Supabase stack with `supabase start`.
2. Apply migrations and seed data with `supabase db reset`.
3. Serve the Edge Functions with:
   `supabase functions serve validate --env-file .env`
   `supabase functions serve record-approval --env-file .env`
   `supabase functions serve resolve-constraints --env-file .env`
4. Run the end-to-end scripts:
   `tests/e2e/validate-approved-wording.sh`
   `tests/e2e/curate-and-approve-term.sh`
   `tests/e2e/retrieve-constraints-and-validate-output.sh`
   `tests/e2e/resolve-inherited-rules.sh`
5. Run contract and smoke checks:
   `tests/contract/verify-openapi.sh`
   `tests/contract/verify-graphql-schema.sh`
   `tests/edge/run-smoke-tests.sh`

## Structure

- `supabase/migrations/`: schema, policies, views, and SQL helpers
- `supabase/functions/`: edge functions and shared TypeScript helpers
- `supabase/seed.sql`: local seed data
- `tests/`: contract, database, edge, and end-to-end validation scripts
- `specs/001-nomenclature-api/`: spec-kit design artifacts

## Hosted validation

The repository is configured with hosted Supabase credentials in `.env` for remote parser and connectivity checks. Use those only for explicit database validation and keep them out of version control.
