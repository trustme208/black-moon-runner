import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabaseAdmin } from "./_supabase";

const ADMIN_KEY = process.env.ADMIN_KEY || "";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    if (req.method === "GET") {
      const provided = (req.headers["x-admin-key"] || "").toString();
      if (provided === ADMIN_KEY) {
        const { data, error } = await supabaseAdmin.from("withdrawals").select("*").order("requested_at", { ascending: true });
        if (error) throw error;
        return res.json(data);
      }
      const { data, error } = await supabaseAdmin.from("withdrawals").select("username,tokens,requested_at").eq("status","PENDING").order("requested_at",{ ascending:false }).limit(20);
      if (error) throw error;
      return res.json((data||[]).map((r:any)=>({ username: r.username, tokens: r.tokens, requestedAt: r.requested_at })));
    }

    if (req.method === "POST") {
      const { wallet, username } = req.body || {};
      if (!wallet) return res.status(400).json({ error: "wallet required" });
      const userRes = await supabaseAdmin.from("users").select("tokens").eq("wallet", wallet).limit(1);
      const user = userRes.data?.[0];
      const userTokens = Number(user?.tokens || 0);
      if (userTokens < 10000) return res.status(400).json({ error: "insufficient tokens", tokens: userTokens });
      const { data, error } = await supabaseAdmin.from("withdrawals").insert({ wallet, username, tokens: userTokens }).select().limit(1);
      if (error) throw error;
      await supabaseAdmin.from("users").update({ tokens: 0 }).eq("wallet", wallet);
      return res.json({ success: true, id: data?.[0]?.id });
    }

    if (req.method === "PUT") {
      const provided = (req.headers["x-admin-key"] || "").toString();
      if (provided !== ADMIN_KEY) return res.status(403).json({ error: "admin required" });
      const { id, action } = req.body || {};
      if (!id || !action) return res.status(400).json({ error: "id & action required" });

      if (action === "APPROVE") {
        const { error } = await supabaseAdmin.from("withdrawals").update({ status: "APPROVED", processed_at: new Date().toISOString() }).eq("id", id);
        if (error) throw error;
        return res.json({ success: true, id, status: "APPROVED" });
      } else {
        const wq = await supabaseAdmin.from("withdrawals").select("wallet,tokens").eq("id", id).limit(1);
        const row = wq.data?.[0];
        if (!row) return res.status(404).json({ error: "not found" });
        const { error: updErr } = await supabaseAdmin.from("users").update({ tokens: Number(row.tokens) }).eq("wallet", row.wallet);
        if (updErr) throw updErr;
        const { error: e2 } = await supabaseAdmin.from("withdrawals").update({ status: "REJECTED", processed_at: new Date().toISOString() }).eq("id", id);
        if (e2) throw e2;
        return res.json({ success: true, id, status: "REJECTED" });
      }
    }

    return res.status(405).json({ error: "method not allowed" });
  } catch (e:any) {
    console.error(e);
    return res.status(500).json({ error: e.message || String(e) });
  }
}
