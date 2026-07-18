import { createClient } from "npm:@supabase/supabase-js@2";

export function createSupabaseClient(req: Request) {
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

  if (!url || !anonKey) {
    throw new Error("SUPABASE_URL and SUPABASE_ANON_KEY must be set");
  }

  const headers = new Headers();
  const auth = req.headers.get("Authorization");
  const apikey = req.headers.get("apikey");

  if (auth) headers.set("Authorization", auth);
  if (apikey) headers.set("apikey", apikey);

  return createClient(url, anonKey, {
    global: {
      headers: Object.fromEntries(headers.entries()),
    },
  });
}
