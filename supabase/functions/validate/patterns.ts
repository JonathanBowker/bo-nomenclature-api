export function normalizeCandidate(input: string) {
  return input.normalize("NFKC").trim();
}

export function matchesPattern(candidate: string, pattern: string | null, mode: string) {
  if (!pattern) {
    if (mode === "case_insensitive") {
      return candidate.toLowerCase() === candidate;
    }
    return false;
  }

  const regex = new RegExp(pattern);
  return regex.test(candidate);
}

export function textMatchesVariant(candidate: string, variantText: string, matchMode: string, pattern: string | null) {
  const normalizedCandidate = normalizeCandidate(candidate);
  const normalizedVariant = normalizeCandidate(variantText);

  switch (matchMode) {
    case "exact":
      return normalizedCandidate === normalizedVariant;
    case "case_insensitive":
      return normalizedCandidate.toLowerCase() === normalizedVariant.toLowerCase();
    case "normalized":
      return normalizedCandidate.replace(/\s+/g, " ") === normalizedVariant.replace(/\s+/g, " ");
    case "pattern":
      return matchesPattern(candidate, pattern, matchMode);
    default:
      return normalizedCandidate === normalizedVariant;
  }
}
