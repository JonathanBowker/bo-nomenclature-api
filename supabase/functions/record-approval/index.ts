import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createSupabaseClient } from "../_shared/client.ts";
import { errorResponse, jsonResponse } from "../_shared/errors.ts";

type ApprovalRequest = {
  termId?: string;
  destination?: string;
  status?: "approved" | "revoked";
  comment?: string;
  effectiveAt?: string;
  expiresAt?: string | null;
};

serve(async (req) => {
  if (req.method !== "POST") {
    return errorResponse("Method not allowed", 405);
  }

  let payload: ApprovalRequest;
  try {
    payload = await req.json();
  } catch {
    return errorResponse("Invalid JSON body");
  }

  if (!payload.termId || !payload.destination || !payload.status) {
    return errorResponse("termId, destination, and status are required");
  }

  try {
    const supabase = createSupabaseClient(req);

    const { data, error } = await supabase.rpc("record_term_approval", {
      input_term_id: payload.termId,
      input_destination_code: payload.destination,
      input_status: payload.status,
      input_comment: payload.comment ?? null,
      input_effective_at: payload.effectiveAt ?? new Date().toISOString(),
      input_expires_at: payload.expiresAt ?? null,
    });

    if (error) {
      return errorResponse("Failed to record approval", 400, error.message);
    }

    return jsonResponse(data, 201);
  } catch (error) {
    return errorResponse("Approval workflow failed", 500, String(error));
  }
});
