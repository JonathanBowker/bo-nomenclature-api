export type ValidationCandidate = {
  term_id: string;
  domain_id: string;
  canonical_text: string;
  variant_text: string;
  variant_type: string;
  locale_code: string | null;
  copyright_line: string | null;
  match_mode: string;
  validation_pattern: string | null;
  destination_code: string;
  approval_status: string | null;
};

export function groupMatches(rows: ValidationCandidate[]) {
  const byTerm = new Map<string, ValidationCandidate[]>();

  for (const row of rows) {
    const existing = byTerm.get(row.term_id) ?? [];
    existing.push(row);
    byTerm.set(row.term_id, existing);
  }

  return [...byTerm.values()];
}
