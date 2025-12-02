import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabaseAdmin } from "./_supabase";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    if (req.method === "GET") {
      const wallet = (req.query.wallet || "").toString().toLowerCase();
      if (!wallet) return res.status(400).json({ error: "wallet required" });
      const { data } = await supabaseAdmin.from("users").select("*").eq("wallet", wallet).limit(1);
      return res.json(data?.[0] ?? null);
    }

    if (req.method === "POST") {
      const body: any = req.body || {};
      const wallet = (body.wallet || "").toLowerCase();
      if (!wallet) return res.status(400).json({ error: "wallet required" });
      const payload: any = { wallet, username: body.username || null };
      if (typeof body.score !== "undefined") payload.score = body.score;
      if (typeof body.tokens !== "undefined") payload.tokens = body.tokens;
      const { data, error } = await supabaseAdmin.from("users").upsert(payload, { onConflict: "wallet" }).select().limit(1);
      if (error) throw error;
      return res.json(data?.[0]);
    }

    return res.status(405).json({ error: "method not allowed" });
  } catch (e:any) {
    console.error(e);
    return res.status(500).json({ error: e.message || String(e) });
  }
}
