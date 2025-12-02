# bootstrap.ps1
# Run from project root (C:\Users\Victus\Desktop\black-moon-runner)
# Executes: create files, install deps, init git

$ErrorActionPreference = "Stop"

Write-Host "Creating project files..."

# helper to write files (ensures folder exists)
function Write-File($path, $content) {
  $dir = Split-Path $path -Parent
  if (!(Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  $content | Out-File -FilePath $path -Encoding utf8 -Force
  Write-Host "  -> $path"
}

# package.json
$pkg = @'
{
  "name": "black-moon-runner",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "compile": "hardhat compile",
    "deploy:testnet": "hardhat run scripts/deploy.js --network cronosTestnet",
    "deploy:mainnet": "hardhat run scripts/deploy.js --network cronosMainnet"
  },
  "dependencies": {
    "axios": "^1.5.0",
    "ethers": "^5.7.2",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "socket.io-client": "^4.7.2",
    "@walletconnect/web3-provider": "^1.8.0",
    "@supabase/supabase-js": "^2.26.0"
  },
  "devDependencies": {
    "dotenv": "^16.3.1",
    "typescript": "^5.8.0",
    "vite": "^6.4.1",
    "hardhat": "2.22.9",
    "@nomiclabs/hardhat-ethers": "^2.1.0",
    "ts-node": "^10.9.1"
  }
}
'@
Write-File -path "./package.json" -content $pkg

# .gitignore
$gi = @'
node_modules
dist
.env
.env.local
.vscode
.DS_Store
*.db
'@
Write-File -path "./.gitignore" -content $gi

# tsconfig.json
$ts = @'
{
  "compilerOptions": {
    "target": "ES2020",
    "useUnknownInCatchVariables": false,
    "lib": ["ES2020", "DOM"],
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "jsx": "react-jsx",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "resolveJsonModule": true,
    "outDir": "dist"
  },
  "include": ["src", "scripts", "hardhat.config.js"]
}
'@
Write-File -path "./tsconfig.json" -content $ts

# index.html
$html = @'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Black Moon Runner</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
      body { margin: 0; background: #0B0B19; color: #fff; font-family: Inter, system-ui, sans-serif; }
    </style>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
'@
Write-File -path "./index.html" -content $html

# vite.config.ts
$vc = @'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: { port: 5173 }
});
'@
Write-File -path "./vite.config.ts" -content $vc

# README.md
$rd = @'
# Black Moon Runner

This repo contains the Black Moon Runner frontend (Vite + React + TypeScript), serverless API routes for Vercel (Supabase-backed), and Hardhat 2 deployment scripts and contracts.

Follow the README sections to set up Supabase, Vercel, and local deploys.
'@
Write-File -path "./README.md" -content $rd

# src/main.tsx
$main = @'
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./styles.css";

const root = createRoot(document.getElementById("root")!);
root.render(<App />);
'@
Write-File -path "./src/main.tsx" -content $main

# src/styles.css
$sty = @'
@import url("https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap");
:root{
  --bg:#0B0B19;
  --accent:#00A3FF;
  --gold:#F0B90B;
}
body{background:var(--bg);font-family:Inter,system-ui,Arial,sans-serif;color:#fff}
button{cursor:pointer}
'@
Write-File -path "./src/styles.css" -content $sty

# src/wallet.ts
$wallet = @'
import { ethers } from "ethers";
import WalletConnectProvider from "@walletconnect/web3-provider";

export const TARGET_NETWORK = {
  chainId: 338,
  hexChainId: "0x152",
  rpc: "https://evm-t3.cronos.org",
  name: "Cronos Testnet"
};

let provider: ethers.providers.Web3Provider | null = null;
let wcProvider: any = null;

export async function connectWithMetaMask() {
  const win = window as any;
  if (!win.ethereum) throw new Error("MetaMask not found");
  try {
    await win.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: TARGET_NETWORK.hexChainId }]
    });
  } catch (err:any) {
    if (err.code === 4902) {
      await win.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
          chainId: TARGET_NETWORK.hexChainId,
          chainName: TARGET_NETWORK.name,
          rpcUrls: [TARGET_NETWORK.rpc],
          nativeCurrency: { name: "TCRO", symbol: "TCRO", decimals: 18 }
        }]
      });
    }
  }
  provider = new ethers.providers.Web3Provider(win.ethereum);
  await provider.send("eth_requestAccounts", []);
  const signer = provider.getSigner();
  const address = await signer.getAddress();
  return { address, signer, provider };
}

export async function connectWithWalletConnect() {
  wcProvider = new WalletConnectProvider({
    rpc: { [TARGET_NETWORK.chainId]: TARGET_NETWORK.rpc },
    chainId: TARGET_NETWORK.chainId,
    qrcode: true
  });
  await wcProvider.enable();
  provider = new ethers.providers.Web3Provider(wcProvider);
  const signer = provider.getSigner();
  const address = await signer.getAddress();
  return { address, signer, provider };
}

export function getProvider() { return provider; }

export async function disconnectWallet() {
  try { if (wcProvider && wcProvider.disconnect) await wcProvider.disconnect(); } catch(e){/*ignore*/ }
  provider = null; wcProvider = null;
}
'@
Write-File -path "./src/wallet.ts" -content $wallet

# src/services/api.ts
$api = @'
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
'@
Write-File -path "./src/services/api.ts" -content $api

# src/components/UIOverlay.tsx
$ui = @'
import React, { useEffect, useState } from "react";
import * as api from "../services/api";

export default function UIOverlay(props: {
  address: string | null,
  username: string | null,
  onConnect: ()=>void,
  onDisconnect: ()=>void,
  leaderboard: any[],
  refreshLeaderboard: ()=>void
}) {
  const { address, username, onConnect, onDisconnect, leaderboard, refreshLeaderboard } = props;
  const [showLb, setShowLb] = useState(false);
  const [showWithdraw, setShowWithdraw] = useState(false);
  const [adminKey, setAdminKey] = useState("");
  const [adminList, setAdminList] = useState<any[]>([]);

  useEffect(()=>{ }, []);

  async function openAdmin() {
    if (!adminKey) return alert("Enter admin key");
    const list = await api.getWithdrawAdmin(adminKey);
    setAdminList(list);
  }

  async function reqWithdraw() {
    if (!address) return alert("Connect first");
    const res = await api.requestWithdraw(address, username || undefined);
    if (res?.success) {
      alert("Withdraw request queued");
      setShowWithdraw(false);
      refreshLeaderboard();
    } else alert(JSON.stringify(res));
  }

  return (
    <div>
      <div style={{position:'absolute', top:10, left:10}}>
        {address ? (
          <div>
            <div>{address}</div>
            <button onClick={onDisconnect}>Disconnect</button>
          </div>
        ) : (
          <button onClick={onConnect}>Connect Wallet</button>
        )}
      </div>

      <div style={{position:'absolute', top:10, right:10}}>
        <button onClick={()=>setShowLb(true)}>Leaderboard</button>
      </div>

      {showLb && (
        <div style={{position:'fixed', inset:0, background:'rgba(0,0,0,0.7)'}}>
          <div style={{margin:'40px auto', maxWidth:720, background:'#0b0b19', padding:20}}>
            <h3>Leaderboard</h3>
            <ol>
              {leaderboard.map((u:any,i:number)=>(
                <li key={i}>{i+1}. {u.username || u.wallet} — score: {u.score}</li>
              ))}
            </ol>
            <button onClick={()=>setShowWithdraw(true)}>Request Withdraw</button>
            <div style={{marginTop:10}}>
              <input placeholder="Admin key" value={adminKey} onChange={e=>setAdminKey(e.target.value)} />
              <button onClick={openAdmin}>Open Admin</button>
            </div>

            <div style={{marginTop:10}}>
              <button onClick={()=>setShowLb(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {showWithdraw && (
        <div style={{position:'fixed', inset:0, background:'rgba(0,0,0,0.7)'}}>
          <div style={{margin:'40px auto', maxWidth:520, background:'#0b0b19', padding:20}}>
            <h4>Request Withdraw (min 10,000)</h4>
            <div>Wallet: {address}</div>
            <div>Username: {username}</div>
            <button onClick={reqWithdraw}>Submit Request</button>
            <button onClick={()=>setShowWithdraw(false)}>Cancel</button>
          </div>
        </div>
      )}

      {adminList.length>0 && (
        <div style={{position:'fixed', bottom:20, left:20, background:'#0b0b19', padding:12}}>
          <h4>Admin Withdraw Queue</h4>
          <ul>
            {adminList.map((r:any)=>(<li key={r.id}>{r.username} {r.wallet} {r.tokens}</li>))}
          </ul>
        </div>
      )}
    </div>
  );
}
'@
Write-File -path "./src/components/UIOverlay.tsx" -content $ui

# src/App.tsx
$app = @'
import React, { useEffect, useState } from "react";
import UIOverlay from "./components/UIOverlay";
import { connectWithMetaMask, connectWithWalletConnect, disconnectWallet } from "./wallet";
import * as api from "./services/api";

export default function App(){
  const [address, setAddress] = useState<string|null>(null);
  const [username, setUsername] = useState<string|null>(null);
  const [leaderboard, setLeaderboard] = useState<any[]>([]);

  useEffect(()=>{ refreshLeaderboard(); },[]);

  async function refreshLeaderboard(){
    try {
      const lb = await api.getLeaderboard();
      setLeaderboard(lb);
    } catch(e){ console.error(e); }
  }

  async function onConnect(){
    try {
      const r = await connectWithMetaMask().catch(()=>connectWithWalletConnect());
      setAddress(r.address);
      // fetch user profile
      const u = await api.getUser(r.address);
      if (u && u.username) setUsername(u.username);
    } catch(e:any){
      alert("connect failed: "+(e.message||e));
    }
  }

  async function onDisconnect(){
    await disconnectWallet();
    setAddress(null);
    setUsername(null);
  }

  return (
    <div>
      <div style={{padding:20}}>
        <h1>Black Moon Runner</h1>
        <p>Game placeholder. Connect wallet to use leaderboard & withdraw.</p>
      </div>

      <UIOverlay
        address={address}
        username={username}
        onConnect={onConnect}
        onDisconnect={onDisconnect}
        leaderboard={leaderboard}
        refreshLeaderboard={refreshLeaderboard}
      />
    </div>
  );
}
'@
Write-File -path "./src/App.tsx" -content $app

# contracts
$bmns = @'
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 contract BMNToken is ERC20, Ownable {
     constructor(uint256 initialSupply) ERC20("BlackMoon", "BMN") {
         if (initialSupply > 0) { _mint(msg.sender, initialSupply); }
     }
     function mint(address to, uint256 amount) external onlyOwner { _mint(to, amount); }
 }
'@
Write-File -path "./contracts/BMNToken.sol" -content $bmns

$profile = @'
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
 contract ProfileRegistry {
     mapping(address => string) private _usernameOf;
     mapping(string => address) private _ownerOfUsername;
     address public owner;
     event UsernameSet(address indexed user, string username);
     modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
     constructor() { owner = msg.sender; }
     function usernameOf(address user) external view returns (string memory) { return _usernameOf[user]; }
     function ownerOfUsername(string calldata username) external view returns (address) { return _ownerOfUsername[username]; }
     function setUsername(string calldata username) external {
         require(bytes(username).length >= 2, "username too short");
         require(_ownerOfUsername[username] == address(0), "username taken");
         string memory prev = _usernameOf[msg.sender];
         if (bytes(prev).length != 0) { delete _ownerOfUsername[prev]; }
         _usernameOf[msg.sender] = username;
         _ownerOfUsername[username] = msg.sender;
         emit UsernameSet(msg.sender, username);
     }
     function adminRemoveUsername(address user) external onlyOwner {
         string memory prev = _usernameOf[user];
         if (bytes(prev).length != 0) {
             delete _ownerOfUsername[prev];
             delete _usernameOf[user];
         }
     }
 }
'@
Write-File -path "./contracts/ProfileRegistry.sol" -content $profile

$pool = @'
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 contract WithdrawalPool is Ownable {
     IERC20 public immutable token;
     mapping(address => uint256) public lastWithdrawAt;
     uint256 public cooldownSeconds = 3600;
     uint256 public withdrawCap = 1000 * 1e18;
     event Withdraw(address indexed user, uint256 amount);
     constructor(address tokenAddr) { token = IERC20(tokenAddr); }
     function setCooldown(uint256 s) external onlyOwner { cooldownSeconds = s; }
     function setCap(uint256 cap) external onlyOwner { withdrawCap = cap; }
     function withdraw(uint256 amount) external {
         require(amount > 0, "zero");
         require(amount <= withdrawCap, "exceeds cap");
         require(block.timestamp >= lastWithdrawAt[msg.sender] + cooldownSeconds, "cooldown");
         lastWithdrawAt[msg.sender] = block.timestamp;
         require(token.transfer(msg.sender, amount), "transfer failed");
         emit Withdraw(msg.sender, amount);
     }
     function rescue(address to, uint256 amount) external onlyOwner { require(token.transfer(to, amount), "transfer failed"); }
 }
'@
Write-File -path "./contracts/WithdrawalPool.sol" -content $pool

# hardhat config (v2 / ethers v5)
$hh = @'
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.19",
  networks: {
    cronosTestnet: {
      url: process.env.RPC_TESTNET || "https://evm-t3.cronos.org",
      chainId: 338,
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : []
    },
    cronosMainnet: {
      url: process.env.RPC_MAINNET || "https://evm.cronos.org",
      chainId: 25,
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : []
    }
  }
};
'@
Write-File -path "./hardhat.config.js" -content $hh

# scripts/deploy.js (ethers v5 / hardhat v2)
$deploy = @'
async function main() {
  const hre = require("hardhat");
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const BMN = await ethers.getContractFactory("BMNToken");
  const initialSupply = ethers.utils.parseUnits("1000000", 18);
  const bmn = await BMN.deploy(initialSupply);
  await bmn.deployed();
  console.log("BMNToken:", bmn.address);

  const Profile = await ethers.getContractFactory("ProfileRegistry");
  const profile = await Profile.deploy();
  await profile.deployed();
  console.log("ProfileRegistry:", profile.address);

  const Pool = await ethers.getContractFactory("WithdrawalPool");
  const pool = await Pool.deploy(bmn.address);
  await pool.deployed();
  console.log("WithdrawalPool:", pool.address);

  const tx = await bmn.transfer(pool.address, ethers.utils.parseUnits("50000", 18));
  await tx.wait();
  console.log("Funded pool with 50,000 BMN");

  console.log("Done.");
}

main().catch((e)=>{ console.error(e); process.exit(1); });
'@
Write-File -path "./scripts/deploy.js" -content $deploy

# api folder (vercel)
$apiSup = @'
import { createClient } from "@supabase/supabase-js";

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) throw new Error("Missing SUPABASE env vars");

export const supabaseAdmin = createClient(url, key, { auth: { persistSession: false } });
'@
Write-File -path "./api/_supabase.ts" -content $apiSup

$apiUser = @'
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
'@
Write-File -path "./api/user.ts" -content $apiUser

$apiBoard = @'
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
'@
Write-File -path "./api/leaderboard.ts" -content $apiBoard

$apiWithdraw = @'
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
'@
Write-File -path "./api/withdrawals.ts" -content $apiWithdraw

# .env.example
$env = @'
# Vercel / Frontend
VITE_PROFILE_REGISTRY_ADDR=
VITE_BMN_TOKEN_ADDR=
VITE_WITHDRAWAL_POOL_ADDR=

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=anon-key-optional
SUPABASE_SERVICE_ROLE_KEY=service-role-key

# Admin key for API admin actions (set in Vercel)
ADMIN_KEY=replace-with-strong-secret

# Hardhat (for local deploy only)
DEPLOYER_PRIVATE_KEY=0xYOUR_PRIVATE_KEY_LOCAL
RPC_TESTNET=https://evm-t3.cronos.org
RPC_MAINNET=https://evm.cronos.org
'@
Write-File -path "./.env.example" -content $env

Write-Host "Files created. Installing dependencies (this may take a while)..."

# run npm install
$installCmd = "npm install"
$proc = Start-Process -FilePath "npm" -ArgumentList "install" -NoNewWindow -Wait -PassThru

if ($proc.ExitCode -ne 0) {
  Write-Host "npm install failed; retrying with --legacy-peer-deps..."
  $proc2 = Start-Process -FilePath "npm" -ArgumentList "install --legacy-peer-deps" -NoNewWindow -Wait -PassThru
  if ($proc2.ExitCode -ne 0) {
    Write-Host "npm install failed again. Please inspect output. Exiting."
    exit 1
  } else {
    Write-Host "npm install succeeded with --legacy-peer-deps."
  }
} else {
  Write-Host "npm install completed successfully."
}

# init git if not already
if (!(Test-Path ".git")) {
  git init | Out-Null
}

git add .
git commit -m "Initial project scaffold" | Out-Null

Write-Host "`nBootstrap complete."
Write-Host "Next steps (manual):"
Write-Host "  1) Create a GitHub repo at https://github.com/new named: trustme208/black-moon-runner"
Write-Host "  2) Add remote:"
Write-Host "       git remote add origin https://github.com/trustme208/black-moon-runner.git"
Write-Host "       git branch -M main"
Write-Host "       git push -u origin main"
Write-Host "     Use your GitHub username and a Personal Access Token (repo scope) as the password if prompted."
Write-Host "  3) Create a Supabase project and run the SQL schema (see README or earlier instructions)."
Write-Host "  4) Deploy to Vercel: connect your GitHub repo and set env vars SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ADMIN_KEY."
Write-Host "`nIf you want I can output the exact SQL for Supabase and the curl commands to test endpoints."
