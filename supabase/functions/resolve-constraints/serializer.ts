type ConstraintRow = {
  term_id: string;
  canonical_text: string;
  category: string;
  variant_id: string;
  variant_text: string;
  variant_type: string;
  locale_code: string | null;
  copyright_line: string | null;
  match_mode: string;
  validation_pattern: string | null;
  destination_code: string;
  rules: Array<{
    rule_id: string;
    rule_text: string;
    enforcement_level: string;
    priority: number;
  }> | string;
};

type ResolvedRow = {
  term_id: string;
  canonical_text: string;
  inherited_from: string | null;
  overridden_rules: string[] | string | null;
  variants: Array<{
    id: string;
    variantText: string;
    variantType: string;
    locale: string | null;
    destinations: string[];
    copyrightLine: string | null;
  }> | string;
  rules: Array<{
    id: string;
    ruleText: string;
    enforcementLevel: string;
    destinations: string[];
  }> | string;
};

function parseRules(value: ConstraintRow["rules"]) {
  if (Array.isArray(value)) {
    return value;
  }

  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  return [];
}

function parseJsonArray<T>(value: T[] | string | null | undefined): T[] {
  if (Array.isArray(value)) return value;
  if (typeof value === "string") {
    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }
  return [];
}

export function serializeConstraintSet(
  domainId: string,
  destination: string,
  locale: string | undefined,
  rows: ConstraintRow[],
) {
  const byTerm = new Map<string, ConstraintRow[]>();

  for (const row of rows) {
    const existing = byTerm.get(row.term_id) ?? [];
    existing.push(row);
    byTerm.set(row.term_id, existing);
  }

  const items = [...byTerm.values()].map((group) => {
    const first = group[0];
    const rules = parseRules(first.rules);

    return {
      termId: first.term_id,
      canonicalText: first.canonical_text,
      inheritedFrom: null,
      overriddenRules: [],
      variants: group.map((row) => ({
        id: row.variant_id,
        variantText: row.variant_text,
        variantType: row.variant_type,
        locale: row.locale_code,
        destinations: [row.destination_code],
        copyrightLine: row.copyright_line,
      })),
      rules: rules.map((rule) => ({
        id: rule.rule_id,
        ruleText: rule.rule_text,
        enforcementLevel: rule.enforcement_level,
        destinations: [destination],
      })),
    };
  });

  return {
    domainId,
    destination,
    locale: locale ?? null,
    items,
  };
}

export function serializeResolvedTerms(
  domainId: string,
  destination: string,
  rows: ResolvedRow[],
) {
  return {
    domainId,
    destination,
    items: rows.map((row) => ({
      termId: row.term_id,
      canonicalText: row.canonical_text,
      inheritedFrom: row.inherited_from,
      overriddenRules: parseJsonArray<string>(row.overridden_rules),
      variants: parseJsonArray(row.variants),
      rules: parseJsonArray(row.rules),
    })),
  };
}
