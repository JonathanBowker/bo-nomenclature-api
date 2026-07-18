# Data Model: Nomenclature API

## Overview

The data model centers on hierarchical brand domains, governed terms, controlled variants, approval facts, and immutable audit history. All user-visible validation and resolution behavior is derived from these records.

## Supabase Design Notes

- All governed tables live in Postgres and are managed by Supabase migrations.
- Tenant scoping is enforced with row-level security policies rather than application-only checks.
- `auth.users` is the identity source for authenticated actors; domain-specific roles are mapped in project tables.
- Custom workflows return shaped responses through Edge Functions and SQL views.

## Entities

### Domain

**Purpose**: Represents a node in the brand hierarchy and defines the inheritance boundary for terms and rules.

**Fields**:
- `id`: Unique identifier
- `tenant_id`: Owning customer or organizational scope
- `parent_id`: Optional reference to parent domain
- `name`: Display name
- `slug`: Stable machine-readable name
- `domain_type`: Classification such as brand, property, venue, category, or experience
- `status`: Active or inactive
- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

**Relationships**:
- One domain may have many child domains
- One domain may own many terms

**Validation Rules**:
- `slug` must be unique within a tenant
- `parent_id` must reference a domain in the same tenant
- Hierarchy cycles are forbidden
- Row-level security must restrict visibility to callers mapped to the same tenant

### TenantMembership

**Purpose**: Maps authenticated Supabase users to tenant scope and authorization level.

**Fields**:
- `id`
- `tenant_id`
- `user_id`: References Supabase auth identity
- `role`: Brand manager, reviewer, read-only consumer, service consumer
- `created_at`

**Relationships**:
- Belongs to one tenant

**Validation Rules**:
- A user may only hold one active role record per tenant

### Term

**Purpose**: Represents a governed concept or named item within a domain.

**Fields**:
- `id`
- `tenant_id`
- `domain_id`
- `canonical_text`: Current approved wording
- `category`: Business-defined classification
- `approval_state`: Derived summary state for convenience, backed by approvals
- `source_reference`: Optional provenance pointer to upstream guideline content
- `notes`: Optional curation notes
- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

**Relationships**:
- Belongs to one domain
- Has many variants
- Has many examples
- Has many rules
- Has many approvals
- Has many audit entries indirectly through mutations

**Validation Rules**:
- `canonical_text` is required
- `canonical_text` must be unique within a domain and locale scope once active
- Row-level security must prevent cross-tenant reads and writes

### Variant

**Purpose**: Captures alternative surface forms and their governance meaning.

**Fields**:
- `id`
- `term_id`
- `variant_text`
- `variant_type`: Approved, prohibited, equivalent, or regional
- `locale_code`: Optional locale or market scope
- `copyright_line`: Optional first-mention text
- `match_mode`: Exact, case-insensitive, normalized, or pattern-based
- `validation_pattern`: Optional stored pattern guidance
- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

**Relationships**:
- Belongs to one term
- Has many destination scopes through `variant_destinations`

**Validation Rules**:
- `variant_text` is required
- `validation_pattern` must pass safe compilation before activation
- At least one effective destination must exist before a variant can be used in validation

### VariantDestination

**Purpose**: Scopes a variant to one or more destinations.

**Fields**:
- `id`
- `variant_id`
- `destination_code`
- `is_primary`

**Relationships**:
- Belongs to one variant

**Validation Rules**:
- Each `destination_code` may appear once per variant

### Example

**Purpose**: Stores correct and incorrect worked examples for business guidance and downstream validation support.

**Fields**:
- `id`
- `term_id`
- `example_type`: Correct or incorrect
- `caption`
- `content_text`: Optional inline textual example
- `asset_url`: Optional external asset reference
- `destination_code`: Optional destination scope
- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

**Relationships**:
- Belongs to one term

**Validation Rules**:
- At least one of `content_text` or `asset_url` is required

### Rule

**Purpose**: Stores conditional guidance that affects how a term may be used.

**Fields**:
- `id`
- `term_id`
- `rule_text`
- `enforcement_level`: Hard, warning, informational
- `priority`: Numeric ordering within the same term
- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

**Relationships**:
- Belongs to one term
- Has many destination scopes through `rule_destinations`

**Validation Rules**:
- `rule_text` is required
- `enforcement_level` must be one of the allowed values

### RuleDestination

**Purpose**: Scopes a rule to one or more destinations.

**Fields**:
- `id`
- `rule_id`
- `destination_code`

### Approval

**Purpose**: Immutable sign-off record authorizing or revoking a term for a destination.

**Fields**:
- `id`
- `term_id`
- `destination_code`
- `status`: Approved, revoked, expired, superseded
- `comment`
- `effective_at`
- `expires_at`: Optional
- `actor_id`
- `created_at`

**Relationships**:
- Belongs to one term

**Validation Rules**:
- An approval event cannot be edited after creation
- Active approval for a destination is derived from the latest non-superseded approval event whose expiry has not passed
- Approval writes must occur through controlled workflows so audit logging and permission checks cannot be bypassed

### AuditEntry

**Purpose**: Immutable history of every create, update, and delete affecting governed records.

**Fields**:
- `id`
- `tenant_id`
- `entity_type`
- `entity_id`
- `action`: Create, update, delete
- `actor_id`
- `occurred_at`
- `before_snapshot`: Optional structured snapshot
- `after_snapshot`: Optional structured snapshot
- `reason`: Optional business reason
- `request_id`: Optional correlation value

**Relationships**:
- Logically references any mutable governed entity

**Validation Rules**:
- `after_snapshot` is required for create
- `before_snapshot` is required for delete
- Both snapshots are required for update

## Derived Views

### EffectiveTermApproval

Computed view that returns whether a term is currently approved for a destination based on the latest approval facts and expiry windows.

### ResolvedConstraintSet

Computed view or service response that merges:
- Term and variant data attached directly to the requested domain
- Inherited domain terms and rules from ancestors
- Descendant overrides applied last
- Active approvals and locale filters

### TenantAuthorizedDomainView

Computed view limiting visible domains to the authenticated caller's tenant memberships and role scope.

### ValidationResult

Computed response object returned by validation workflows with:
- Requested input
- Resolved scope
- Outcome: approved, not approved, ambiguous, or evaluation error
- Matched term or candidate terms
- Corrected approved form when applicable
- Supporting rule hits, destination status, and copyright guidance

## State Transitions

### Term Lifecycle

1. Draft term created
2. Variants, examples, and rules attached
3. Approval recorded for one or more destinations
4. Term becomes actively governed for approved destinations
5. Approval may later be revoked, superseded, or expired
6. Term may be removed from active catalog while historical approvals and audits remain

### Approval Lifecycle

1. Approval event created
2. Approval becomes active at `effective_at`
3. Approval remains active until superseded, revoked, or expired
4. Later approval event for same term and destination supersedes prior active interpretation

## Indexing Guidance

- Index `domain(tenant_id, parent_id)`
- Index `term(domain_id, canonical_text)`
- Index `variant(term_id, variant_type, locale_code)`
- Index destination scope join tables by their foreign key plus `destination_code`
- Index `approval(term_id, destination_code, effective_at desc)`
- Index audit entries by `entity_type`, `entity_id`, and `occurred_at desc`
- Index `tenant_membership(tenant_id, user_id, role)`
