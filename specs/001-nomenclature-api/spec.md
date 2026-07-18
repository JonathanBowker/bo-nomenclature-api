# Feature Specification: Nomenclature API

**Feature Branch**: `001-nomenclature-api`

**Created**: 2026-07-18

**Status**: Draft

**Input**: User description: "A queryable, versioned, auditable store of brand nomenclature - canonical forms, approved and prohibited variants, validation patterns, copyright lines, worked examples - organised as a domain hierarchy and exposed for machine consumption by agencies, content workflows, and generative AI pipelines."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Validate approved wording (Priority: P1)

An agency copywriter or connected workflow needs to confirm whether wording used in a piece of content matches the approved brand term for a specific destination. The system returns whether the wording is acceptable, the approved form, any prohibited variant that was matched, and any first-mention copyright text that must accompany the approved usage.

**Why this priority**: This is the smallest saleable unit of value. It lets agencies and workflow tools prevent incorrect brand usage before publication.

**Independent Test**: Load one brand's nomenclature, submit one known-approved wording and one known-prohibited wording for the same destination, and confirm the results differ correctly while returning the approved form and any required usage guidance.

**Acceptance Scenarios**:

1. **Given** a term whose approved form is "PwC" for destination `video`, **When** a caller validates "PwC" for `video`, **Then** the response reports the wording as approved and returns any required copyright text.
2. **Given** the same term, **When** a caller validates "PricewaterhouseCoopers" for `video`, **Then** the response reports the wording as not approved, identifies the prohibited variant matched, and returns "PwC" as the correction.
3. **Given** a term approved for `video` but not approved for `print`, **When** a caller validates that term for `print`, **Then** the response reports that the term is not approved for that destination.

---

### User Story 2 - Curate and approve nomenclature (Priority: P2)

A brand manager maintains the nomenclature for a brand or sub-brand. They create terms, define approved and prohibited variants, add validation guidance, attach correct and incorrect examples, and formally approve usage for named destinations. Every change remains attributable to the person who made it.

**Why this priority**: The catalogue must be maintainable by the business team that owns brand standards. Without this workflow, the validation capability cannot be expanded or governed over time.

**Independent Test**: Create a term, add a variant and usage guidance, approve it for one destination, and confirm the approval and change history are both present and attributable.

**Acceptance Scenarios**:

1. **Given** a draft term, **When** a brand manager approves it for `social` with a comment, **Then** the approval record includes actor, timestamp, destination scope, and comment, and the term becomes available for validation in `social` only.
2. **Given** an approved term, **When** any field is edited, **Then** the change history records the affected record, action, actor, timestamp, and before and after values.
3. **Given** an approval with an expiry date that has passed, **When** a caller validates the term for that destination, **Then** the term is not treated as currently approved.

---

### User Story 3 - Govern generated content (Priority: P2)

A content generation workflow retrieves the active nomenclature constraints for a chosen domain before creating copy, uses those constraints while generating, and validates the output against the same approved rules before release.

**Why this priority**: This extends the product from lookup into governance. It supports AI-assisted content creation while keeping brand naming controlled.

**Independent Test**: Retrieve the constraint set for a domain, run content containing a deliberately prohibited variant through validation, and confirm the violation is detected with the correct approved replacement.

**Acceptance Scenarios**:

1. **Given** a domain with active nomenclature, **When** a workflow requests constraints for that domain and destination, **Then** it receives the approved forms, prohibited variants, and validation guidance needed to govern generated output.
2. **Given** generated copy containing a prohibited variant, **When** the copy is submitted for validation, **Then** each violation is returned with the offending text span, the rule violated, the approved correction, and the source term.

---

### User Story 4 - Resolve inherited brand rules (Priority: P3)

A caller needs the effective naming rules for a deeply nested brand entity, such as a venue inside a property inside a parent brand. The system resolves inherited rules from the top of the hierarchy down to the requested entity, with the most specific rule taking precedence.

**Why this priority**: Large portfolio brands rely on inheritance and overrides, but smaller brands can still use the product without this complexity. It expands market coverage without blocking initial value.

**Independent Test**: Create a four-level hierarchy, define a conflicting rule at two levels, resolve the effective rule set at the leaf, and confirm the more specific rule wins while non-conflicting inherited rules remain present.

**Acceptance Scenarios**:

1. **Given** a four-level brand hierarchy, **When** a caller resolves rules for a leaf-level entity, **Then** the response includes both directly owned rules and inherited rules from its ancestors.
2. **Given** an ancestor rule and a conflicting descendant rule, **When** resolution runs, **Then** the descendant rule takes precedence and the response indicates that an inherited rule was overridden.

### Edge Cases

- A candidate string matches more than one term inside the caller's requested scope.
- A caller requests validation for a destination that is not recognized.
- A term is approved for a destination but a higher-level approval required for inheritance is no longer active.
- A variant is approved in one part of the hierarchy and prohibited in another.
- The same concept has different approved wording by locale or market.
- A term is removed after approvals and historical changes already reference it.
- Unicode, diacritics, or non-Latin scripts appear in approved wording or variants.
- Case, hyphenation, punctuation, and whitespace differences affect matching.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST store nomenclature domains in a hierarchy with parent-child relationships, a name, and a domain type.
- **FR-002**: System MUST store terms within a domain, including an approved form, category, and current approval state.
- **FR-003**: System MUST store multiple variants for a term and classify each variant as approved, prohibited, regional, or equivalent approved wording.
- **FR-004**: System MUST store validation guidance for terms and variants and reject invalid guidance before it can affect production validation.
- **FR-005**: System MUST store correct and incorrect worked examples for a term, including any destination scope and explanatory caption needed by business users.
- **FR-006**: System MUST store conditional usage rules for a term, including the destinations they apply to and the severity of enforcement.
- **FR-007**: System MUST store approval records as first-class records containing the term, actor, timestamp, destination scope, status, comment, and optional expiry.
- **FR-008**: System MUST record an immutable audit entry for every create, update, and delete operation affecting nomenclature records, including actor, timestamp, action, and before and after values where applicable.
- **FR-009**: Users MUST be able to validate a candidate string for a named destination and receive an explicit approved or not-approved result, including the approved correction when applicable.
- **FR-010**: Users MUST be able to retrieve the effective rule set for a domain or term, including inherited rules from ancestor domains with descendant rules taking precedence.
- **FR-011**: Users MUST be able to retrieve a domain's active nomenclature constraints in a form suitable for downstream workflow and AI-governance use.
- **FR-012**: Users MUST be able to read and update nomenclature data through the platform's supported machine-consumption access modes.
- **FR-013**: System MUST prevent a term from being treated as approved for a destination unless a corresponding approval record exists.
- **FR-014**: System MUST treat approvals whose expiry date has passed as inactive for validation and resolution purposes.
- **FR-015**: System MUST preserve approval and audit history even after the referenced term is removed from active use.
- **FR-016**: System MUST maintain a provenance link from each term back to its originating guideline or source record when one exists.
- **FR-017**: System MUST authenticate callers and restrict read and write access to the domains they are entitled to manage or query.
- **FR-018**: System MUST support locale-specific or market-specific approved wording for the same concept.
- **FR-019**: System MUST return an explicit ambiguity result when a candidate string resolves to more than one term within the caller's requested scope.
- **FR-020**: System MUST fail safely when validation guidance cannot be evaluated, returning a clear validation error rather than an indeterminate result.

### Key Entities *(include if feature involves data)*

- **Domain**: A node in the brand hierarchy, such as a master brand, property, venue, category, or experience. Domains define inheritance boundaries for nomenclature rules.
- **Term**: A named concept governed within a domain. A term carries the approved wording, category, approval state, and optional provenance back to a source guideline.
- **Variant**: An alternative expression of a term. Variants capture approved, prohibited, equivalent, or regional wording along with destination and locale scope.
- **Example**: A worked demonstration attached to a term that shows correct or incorrect usage for training, curation, or validation support.
- **Rule**: A conditional usage constraint attached to a term, including destination scope and enforcement severity.
- **Approval**: A formal sign-off record that authorizes a term for a destination or context and records actor, timing, comment, and optional expiry.
- **Audit Entry**: An immutable historical record of a change to nomenclature data, including what changed, when it changed, and who changed it.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 95% of single-term validation requests return a result within 2 seconds from the caller's perspective.
- **SC-002**: 95% of hierarchical rule-resolution requests across a four-level brand tree return a result within 3 seconds from the caller's perspective.
- **SC-003**: The product can represent the complete nomenclature of a complex multi-level brand portfolio without requiring structural redesign during initial rollout.
- **SC-004**: The same product can support a single-domain brand with no unnecessary mandatory data entry for unused hierarchy levels or rule types.
- **SC-005**: 100% of accepted create, update, and delete actions on nomenclature records produce a retrievable audit entry during acceptance verification.
- **SC-006**: A brand manager can create, document, and approve a new term for one destination in under 5 minutes without engineering support.
- **SC-007**: In a seeded validation set containing deliberate prohibited usages, at least 95% of violations are identified with the correct approved correction.
- **SC-008**: A new consumer team can integrate basic validation into an existing workflow within 1 working day using the published product guidance alone.

## Assumptions

- This feature governs approved naming and prohibited naming. Broader tone, grammar, and stylistic guidance are out of scope for this first release.
- The nomenclature store remains the runtime source of truth even when terms are initially imported from an external brand-guidance source.
- Callers provide the destination context for each validation request; no implicit destination is assumed.
- Worked examples may reference externally managed assets rather than storing binary files directly inside the nomenclature product.
- Visual or multimodal compliance checking is a downstream capability that consumes this feature's outputs rather than part of the first release.
- The first release serves machine consumers such as agencies, workflow tools, and AI pipelines rather than providing a full end-user publishing interface.
