import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createSupabaseClient } from "../_shared/client.ts";
import { errorResponse, jsonResponse } from "../_shared/errors.ts";
import { groupMatches, type ValidationCandidate } from "./normalization.ts";
import { ambiguityResponse, approvedResponse, evaluationErrorResponse, missingApprovalResponse, notApprovedResponse } from "./response.ts";
import { textMatchesVariant } from "./patterns.ts";

type ValidationRequest = {
  domainId?: string;
  destination?: string;
  locale?: string;
  candidate?: string;
};

serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  let payload: ValidationRequest;
  try {
    payload = await req.json();
  } catch {
    return errorResponse("Invalid JSON body");
  }

  if (!payload.domainId || !payload.destination || !payload.candidate) {
    return errorResponse("domainId, destination, and candidate are required");
  }

  try {
    const supabase = createSupabaseClient(req);
    const query = supabase
      .from("validation_candidates")
      .select("*")
      .eq("domain_id", payload.domainId)
      .eq("destination_code", payload.destination);

    if (payload.locale) {
      query.or(`locale_code.is.null,locale_code.eq.${payload.locale}`);
    }

    const { data, error } = await query;
    if (error) {
      return errorResponse("Failed to load validation candidates", 500, error.message);
    }

    const matches = (data ?? []).filter((row) =>
      textMatchesVariant(payload.candidate!, row.variant_text, row.match_mode, row.validation_pattern)
    ) as ValidationCandidate[];

    if (matches.length === 0) {
      return jsonResponse({
        outcome: "not_approved",
        candidate: payload.candidate,
        destination: payload.destination,
        matchedTermId: null,
        canonicalText: null,
        prohibitedVariant: null,
        copyrightLine: null,
        ambiguity: [],
        violations: [],
        errors: [`No matching governed term found for "${payload.candidate}".`],
      });
    }

    const grouped = groupMatches(matches);
    if (grouped.length > 1) {
      return jsonResponse({
        candidate: payload.candidate,
        destination: payload.destination,
        ...ambiguityResponse(matches),
      });
    }

    const winningTerm = grouped[0];
    const approvedVariant = winningTerm.find((row) => row.variant_type === "approved");
    const prohibitedMatch = winningTerm.find((row) => row.variant_type === "prohibited");
    const activeApproval = winningTerm.some((row) => row.approval_status === "approved");

    if (!activeApproval) {
      return jsonResponse({
        candidate: payload.candidate,
        destination: payload.destination,
        ...missingApprovalResponse(winningTerm[0].canonical_text, payload.destination),
      });
    }

    if (prohibitedMatch) {
      return jsonResponse({
        candidate: payload.candidate,
        destination: payload.destination,
        ...notApprovedResponse(prohibitedMatch),
      });
    }

    if (!approvedVariant) {
      return jsonResponse({
        candidate: payload.candidate,
        destination: payload.destination,
        ...evaluationErrorResponse("No approved variant exists for the matched term."),
      });
    }

    return jsonResponse({
      candidate: payload.candidate,
      destination: payload.destination,
      ...approvedResponse(approvedVariant),
    });
  } catch (error) {
    return errorResponse("Validation execution failed", 500, String(error));
  }
});
