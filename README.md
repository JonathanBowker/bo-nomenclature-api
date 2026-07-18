# bo-nomenclature-api

Supabase-backed nomenclature platform for governed brand terminology, validation, and downstream AI workflow consumption.

## Local development

1. Start the local Supabase stack with `supabase start`.
2. Apply migrations with `supabase db reset`.
3. Serve the validation function with `supabase functions serve validate --env-file .env`.
4. Run the MVP acceptance script with `tests/e2e/validate-approved-wording.sh`.

## Structure

- `supabase/migrations/`: schema, policies, views, and SQL helpers
- `supabase/functions/`: edge functions and shared TypeScript helpers
- `supabase/seed.sql`: local seed data
- `tests/`: contract, database, edge, and end-to-end validation scripts
- `specs/001-nomenclature-api/`: spec-kit design artifacts
