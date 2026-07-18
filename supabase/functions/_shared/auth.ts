export function getAuthHeaders(req: Request): Headers {
  const headers = new Headers();
  const auth = req.headers.get("Authorization");
  const apikey = req.headers.get("apikey");

  if (auth) headers.set("Authorization", auth);
  if (apikey) headers.set("apikey", apikey);

  return headers;
}
