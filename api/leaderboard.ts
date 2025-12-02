import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabaseAdmin } from "./_supabase";

export default async function handler(_: VercelRequest, res: VercelResponse) {
  try {
    const { data, error } = await supabaseAdmin.from("users").select("wallet,username,score,tokens").order("score", { ascending: false }).limit(50);
    if (error) throw error;
    return res.json(data || []);
  } catch (e:any) {
    console.error(e);
    return res.status(500).json({ error: e.message || String(e) });
  }
}
