const API = "";

export async function getLeaderboard() {
  const res = await fetch(`${API}/api/leaderboard`);
  if (!res.ok) throw new Error("Leaderboard fetch failed");
  return res.json();
}

export async function getUser(wallet: string) {
  const res = await fetch(`${API}/api/user?wallet=${wallet}`);
  return res.ok ? res.json() : null;
}

export async function upsertUser(payload: any) {
  const res = await fetch(`${API}/api/user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  return res.json();
}

export async function requestWithdraw(wallet: string, username?:string) {
  const res = await fetch(`${API}/api/withdrawals`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ wallet, username })
  });
  return res.json();
}

export async function getWithdrawPublic() {
  const res = await fetch(`${API}/api/withdrawals`);
  return res.json();
}

export async function getWithdrawAdmin(adminKey: string) {
  const res = await fetch(`${API}/api/withdrawals`, { headers: { "x-admin-key": adminKey } });
  return res.json();
}

export async function processWithdraw(id:string, action:'APPROVE'|'REJECT', adminKey:string) {
  const res = await fetch(`${API}/api/withdrawals`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", "x-admin-key": adminKey },
    body: JSON.stringify({ id, action })
  });
  return res.json();
}
