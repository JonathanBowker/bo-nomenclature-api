import type { ValidationCandidate } from "./normalization.ts";

export function approvedResponse(match: ValidationCandidate) {
  return {
    outcome: "approved",
    matchedTermId: match.term_id,
    canonicalText: match.canonical_text,
    prohibitedVariant: null,
    copyrightLine: match.copyright_line,
    ambiguity: [],
    violations: [],
    errors: [],
  };
}

export function notApprovedResponse(match: ValidationCandidate) {
  return {
    outcome: "not_approved",
    matchedTermId: match.term_id,
    canonicalText: match.canonical_text,
    prohibitedVariant: match.variant_text,
    copyrightLine: match.copyright_line,
    ambiguity: [],
    violations: [
      {
        span: match.variant_text,
        ruleId: null,
        message: `Variant "${match.variant_text}" is not approved for ${match.destination_code}.`,
        suggestedCanonicalText: match.canonical_text,
      },
    ],
    errors: [],
  };
}

export function missingApprovalResponse(canonicalText: string, destination: string) {
  return {
    outcome: "not_approved",
    matchedTermId: null,
    canonicalText,
    prohibitedVariant: null,
    copyrightLine: null,
    ambiguity: [],
    violations: [
      {
        span: canonicalText,
        ruleId: null,
        message: `No active approval exists for destination ${destination}.`,
        suggestedCanonicalText: canonicalText,
      },
    ],
    errors: [],
  };
}

export function ambiguityResponse(matches: ValidationCandidate[]) {
  return {
    outcome: "ambiguous",
    matchedTermId: null,
    canonicalText: null,
    prohibitedVariant: null,
    copyrightLine: null,
    ambiguity: matches.map((match) => ({
      termId: match.term_id,
      canonicalText: match.canonical_text,
      domainId: match.domain_id,
    })),
    violations: [],
    errors: [],
  };
}

export function evaluationErrorResponse(message: string) {
  return {
    outcome: "evaluation_error",
    matchedTermId: null,
    canonicalText: null,
    prohibitedVariant: null,
    copyrightLine: null,
    ambiguity: [],
    violations: [],
    errors: [message],
  };
}
