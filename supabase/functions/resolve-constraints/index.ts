import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createSupabaseClient } from "../_shared/client.ts";
import { errorResponse, jsonResponse } from "../_shared/errors.ts";
import { serializeConstraintSet, serializeResolvedTerms } from "./serializer.ts";

serve(async (req) => {
  if (req.method !== "GET") {
    return errorResponse("Method not allowed", 405);
  }

  const url = new URL(req.url);
  const domainId = url.searchParams.get("domainId");
  const destination = url.searchParams.get("destination");
  const locale = url.searchParams.get("locale") ?? undefined;
  const resolvedOnly = url.pathname.endsWith("/resolved-terms");

  if (!domainId || !destination) {
    return errorResponse("domainId and destination are required");
  }

  try {
    const supabase = createSupabaseClient(req);
    let query = supabase
      .from(resolvedOnly ? "resolved_term_sets" : "domain_constraint_sets")
      .select("*")
      .eq("domain_id", domainId)
      .eq("destination_code", destination);

    if (locale) {
      query = query.or(`locale_code.is.null,locale_code.eq.${locale}`);
    }

    const { data, error } = await query.order("canonical_text", { ascending: true });

    if (error) {
      return errorResponse("Failed to load constraint set", 500, error.message);
    }

    if (resolvedOnly) {
      return jsonResponse(serializeResolvedTerms(domainId, destination, data ?? []));
    }

    return jsonResponse(serializeConstraintSet(domainId, destination, locale, data ?? []));
  } catch (error) {
    return errorResponse("Constraint resolution failed", 500, String(error));
  }
});
