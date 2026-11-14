// Run on a schedule using a server-side Supabase service-role JWT.
// Deletes expired message attachments through Storage API before deleting message rows.
const corsHeaders = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  const url = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !serviceKey) return new Response(JSON.stringify({ error: "Missing server configuration" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  const auth = req.headers.get("Authorization") || "";
  if (auth !== `Bearer ${serviceKey}`) return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  const headers = { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, "Content-Type": "application/json" };
  try {
    const expiredRes = await fetch(`${url}/rest/v1/chat_messages?select=id,attachment_path&expires_at=lt.${encodeURIComponent(new Date().toISOString())}&limit=500`, { headers });
    if (!expiredRes.ok) throw new Error(`Read expired messages failed: ${await expiredRes.text()}`);
    const expired = await expiredRes.json() as { id: string; attachment_path: string | null }[];
    if (!expired.length) return new Response(JSON.stringify({ deleted: 0 }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
    const paths = expired.map(x => x.attachment_path).filter((x): x is string => !!x);
    if (paths.length) {
      const removeRes = await fetch(`${url}/storage/v1/object/super-k-chat`, { method: "DELETE", headers, body: JSON.stringify({ prefixes: paths }) });
      if (!removeRes.ok) throw new Error(`Storage cleanup failed: ${await removeRes.text()}`);
    }
    const ids = expired.map(x => x.id);
    const deleteRes = await fetch(`${url}/rest/v1/chat_messages?id=in.(${ids.join(",")})`, { method: "DELETE", headers: { ...headers, Prefer: "return=minimal" } });
    if (!deleteRes.ok) throw new Error(`Message cleanup failed: ${await deleteRes.text()}`);
    return new Response(JSON.stringify({ deleted: ids.length, files: paths.length }), { headers: { ...corsHeaders, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }), { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }
});
