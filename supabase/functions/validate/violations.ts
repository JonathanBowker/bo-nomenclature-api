export function prohibitedVariantViolation(
  variantText: string,
  destination: string,
  canonicalText: string,
) {
  return {
    span: variantText,
    ruleId: null,
    message: `Variant "${variantText}" is not approved for ${destination}.`,
    suggestedCanonicalText: canonicalText,
  };
}

export function missingApprovalViolation(
  canonicalText: string,
  destination: string,
) {
  return {
    span: canonicalText,
    ruleId: null,
    message: `No active approval exists for destination ${destination}.`,
    suggestedCanonicalText: canonicalText,
  };
}
