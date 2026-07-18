export function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

export function errorResponse(message: string, status = 400, details?: unknown) {
  return jsonResponse(
    {
      error: message,
      details,
    },
    status,
  );
}
