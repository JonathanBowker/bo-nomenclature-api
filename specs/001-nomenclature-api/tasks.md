# Tasks: Nomenclature API

**Input**: Design documents from `/specs/001-nomenclature-api/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: No standalone test-first task track is generated because the feature spec does not explicitly require TDD. Validation and acceptance execution are still included through contract, quickstart, and end-to-end implementation tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g. US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the Supabase project structure and local development workflow

- [X] T001 Create the Supabase project skeleton in `supabase/config.toml`, `supabase/migrations/.gitkeep`, `supabase/functions/.gitkeep`, `tests/contract/.gitkeep`, `tests/database/.gitkeep`, `tests/edge/.gitkeep`, and `tests/e2e/.gitkeep`
- [X] T002 Configure local Supabase development settings in `supabase/config.toml`
- [X] T003 [P] Add repository-level environment template and local setup notes in `.env.example` and `README.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the core schema, access control, shared SQL utilities, and deployment scaffolding that all user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create the base schema migration for tenants, memberships, domains, terms, variants, examples, rules, approvals, and audit entries in `supabase/migrations/20260718_0001_base_schema.sql`
- [X] T005 [P] Add indexes, uniqueness rules, and hierarchy integrity constraints from the data model in `supabase/migrations/20260718_0002_constraints_and_indexes.sql`
- [X] T006 [P] Implement tenant membership, role mapping, and row-level security policies in `supabase/migrations/20260718_0003_rls_policies.sql`
- [X] T007 [P] Add shared SQL helper functions for current-tenant resolution, approval-state derivation, and audit snapshot formatting in `supabase/migrations/20260718_0004_shared_functions.sql`
- [X] T008 Implement immutable audit capture triggers for governed tables in `supabase/migrations/20260718_0005_audit_triggers.sql`
- [X] T009 [P] Add generated REST and GraphQL supporting views for resolved reads and audit access in `supabase/migrations/20260718_0006_api_views.sql`
- [X] T010 [P] Create a representative seed dataset for one tenant, four-level hierarchy, approved terms, prohibited variants, and approval expiry cases in `supabase/seed.sql`
- [X] T011 Create shared Edge Function utilities for auth context, Supabase clients, and error shaping in `supabase/functions/_shared/auth.ts`, `supabase/functions/_shared/client.ts`, and `supabase/functions/_shared/errors.ts`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Validate approved wording (Priority: P1) 🎯 MVP

**Goal**: Let a caller validate wording for a destination and receive approval status, corrections, ambiguity results, and usage guidance

**Independent Test**: Seed one brand, validate one approved term and one prohibited variant for the same destination, and confirm the outcomes, correction, and usage guidance differ correctly

### Implementation for User Story 1

- [X] T012 [P] [US1] Create SQL read models for active approvals, destination-scoped variants, and validation candidates in `supabase/migrations/20260718_0007_validation_views.sql`
- [X] T013 [P] [US1] Implement safe pattern evaluation and candidate normalization helpers in `supabase/functions/validate/patterns.ts` and `supabase/functions/validate/normalization.ts`
- [X] T014 [US1] Implement the validation orchestration function in `supabase/functions/validate/index.ts`
- [X] T015 [US1] Add structured validation response shaping for approved, not-approved, ambiguous, and evaluation-error outcomes in `supabase/functions/validate/response.ts`
- [X] T016 [US1] Align the validation function contract and payload examples with the implementation in `specs/001-nomenclature-api/contracts/openapi.yaml` and `specs/001-nomenclature-api/contracts/graphql-schema.graphql`
- [X] T017 [US1] Add a manual validation runner for the MVP acceptance flow in `tests/e2e/validate-approved-wording.sh`

**Checkpoint**: User Story 1 should be fully functional and testable independently as the MVP

---

## Phase 4: User Story 2 - Curate and approve nomenclature (Priority: P2)

**Goal**: Let brand managers create and maintain governed terms, variants, rules, examples, and approval records with attributable history

**Independent Test**: Create a term, add a variant and example, record an approval for one destination, then confirm the approval and audit trail are both retrievable

### Implementation for User Story 2

- [X] T018 [P] [US2] Add write-protection policies and role-specific mutation rules for brand managers in `supabase/migrations/20260718_0008_manager_write_policies.sql`
- [X] T019 [P] [US2] Implement approval-state write guards and expiry handling SQL routines in `supabase/migrations/20260718_0009_approval_rules.sql`
- [X] T020 [P] [US2] Implement the controlled approval workflow Edge Function in `supabase/functions/record-approval/index.ts`
- [X] T021 [US2] Add mutation-safe audit enrichment for term, variant, example, rule, and approval writes in `supabase/migrations/20260718_0010_mutation_audit_enrichment.sql`
- [X] T022 [US2] Define curated CRUD request examples and approval workflow examples in `specs/001-nomenclature-api/contracts/openapi.yaml`
- [X] T023 [US2] Add a curation and approval acceptance runner in `tests/e2e/curate-and-approve-term.sh`

**Checkpoint**: User Stories 1 and 2 should both work independently, with governed writes producing audit history

---

## Phase 5: User Story 3 - Govern generated content (Priority: P2)

**Goal**: Provide active constraint sets for downstream generation workflows and support post-generation validation against the same governed rules

**Independent Test**: Retrieve a domain constraint set, run generated text containing a prohibited variant through validation, and confirm the returned violation identifies the offending text and approved correction

### Implementation for User Story 3

- [X] T024 [P] [US3] Create SQL views for active constraint-set assembly across terms, variants, rules, and locale scope in `supabase/migrations/20260718_0011_constraint_set_views.sql`
- [X] T025 [P] [US3] Implement constraint serialization helpers for AI-governance consumers in `supabase/functions/resolve-constraints/serializer.ts`
- [X] T026 [US3] Implement the constraint retrieval Edge Function in `supabase/functions/resolve-constraints/index.ts`
- [X] T027 [US3] Add generated-content violation shaping shared by constraint retrieval and validation in `supabase/functions/validate/violations.ts`
- [X] T028 [US3] Update contract artifacts with constraint-set examples and downstream consumer expectations in `specs/001-nomenclature-api/contracts/openapi.yaml` and `specs/001-nomenclature-api/contracts/graphql-schema.graphql`
- [X] T029 [US3] Add an AI-governance acceptance runner in `tests/e2e/retrieve-constraints-and-validate-output.sh`

**Checkpoint**: User Story 3 should support independent constraint retrieval and generated-content governance on top of US1 foundations

---

## Phase 6: User Story 4 - Resolve inherited brand rules (Priority: P3)

**Goal**: Resolve effective rules and terms across a hierarchical brand tree with explicit descendant precedence and override visibility

**Independent Test**: Seed a four-level hierarchy, define conflicting ancestor and descendant rules, resolve the leaf scope, and confirm the descendant rule wins while inherited non-conflicting rules remain present

### Implementation for User Story 4

- [X] T030 [P] [US4] Add recursive hierarchy traversal and precedence SQL routines in `supabase/migrations/20260718_0012_hierarchy_resolution.sql`
- [X] T031 [P] [US4] Create resolved-term and override-explanation views for domain queries in `supabase/migrations/20260718_0013_resolved_term_views.sql`
- [X] T032 [US4] Extend the constraint resolution Edge Function to emit inheritance provenance and overridden rule metadata in `supabase/functions/resolve-constraints/index.ts`
- [X] T033 [US4] Align resolved-term GraphQL and REST response shapes with override metadata in `specs/001-nomenclature-api/contracts/openapi.yaml` and `specs/001-nomenclature-api/contracts/graphql-schema.graphql`
- [X] T034 [US4] Add a hierarchy resolution acceptance runner in `tests/e2e/resolve-inherited-rules.sh`

**Checkpoint**: All user stories should now be independently functional, including large-brand hierarchy resolution

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Finish delivery hardening, documentation, and end-to-end validation across all stories

- [X] T035 [P] Document local Supabase startup, migration, function serving, and acceptance execution in `README.md`
- [X] T036 [P] Add contract verification scripts for REST and GraphQL artifacts in `tests/contract/verify-openapi.sh` and `tests/contract/verify-graphql-schema.sh`
- [X] T037 Add database acceptance verification for audit coverage, approval expiry, and RLS isolation in `tests/database/acceptance-checks.sql`
- [X] T038 Add Edge Function smoke checks for validate, resolve-constraints, and record-approval in `tests/edge/run-smoke-tests.sh`
- [X] T039 Run the full quickstart validation flow and capture any required updates in `specs/001-nomenclature-api/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - blocks all user stories
- **User Stories (Phase 3+)**: Depend on Foundational completion
- **Polish (Phase 7)**: Depends on completion of the user stories included in the release

### User Story Dependencies

- **User Story 1 (P1)**: Starts after Foundational completion and is the MVP slice
- **User Story 2 (P2)**: Starts after Foundational completion and builds on shared governance tables, but remains independently testable from US1
- **User Story 3 (P2)**: Starts after Foundational completion and reuses US1 validation behavior plus constraint retrieval views
- **User Story 4 (P3)**: Starts after Foundational completion and extends shared hierarchy logic used by earlier stories

### Within Each User Story

- SQL views and helper files before Edge Function orchestration
- Edge Function orchestration before contract alignment and acceptance runner tasks
- Acceptance runner task completes the story checkpoint

### Parallel Opportunities

- T003 can run alongside T002 after T001
- T005, T006, T007, T009, and T010 can run in parallel after T004
- T012 and T013 can run in parallel for US1
- T018, T019, and T020 can run in parallel for US2 after foundational work
- T024 and T025 can run in parallel for US3
- T030 and T031 can run in parallel for US4
- T035, T036, and T038 can run in parallel during polish

---

## Parallel Example: User Story 1

```bash
Task: "Create SQL read models for active approvals, destination-scoped variants, and validation candidates in supabase/migrations/20260718_0007_validation_views.sql"
Task: "Implement safe pattern evaluation and candidate normalization helpers in supabase/functions/validate/patterns.ts and supabase/functions/validate/normalization.ts"
```

## Parallel Example: User Story 2

```bash
Task: "Add write-protection policies and role-specific mutation rules for brand managers in supabase/migrations/20260718_0008_manager_write_policies.sql"
Task: "Implement approval-state write guards and expiry handling SQL routines in supabase/migrations/20260718_0009_approval_rules.sql"
Task: "Implement the controlled approval workflow Edge Function in supabase/functions/record-approval/index.ts"
```

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. Validate the MVP using `tests/e2e/validate-approved-wording.sh`

### Incremental Delivery

1. Ship US1 as the first external validation slice
2. Add US2 to enable governed business curation and approval
3. Add US3 for AI-governance consumers
4. Add US4 for advanced hierarchical brands

### Parallel Team Strategy

1. One engineer owns schema and RLS completion through Phase 2
2. After Phase 2:
   - Engineer A: US1 validation flow
   - Engineer B: US2 curation and approval flow
   - Engineer C: US3 constraint retrieval, then US4 hierarchy resolution

---

## Notes

- [P] tasks touch separate files or independent implementation units
- [US#] labels map directly to the user stories in `spec.md`
- Each user story ends with an explicit acceptance runner task for independent validation
- The recommended first release scope is User Story 1 only
