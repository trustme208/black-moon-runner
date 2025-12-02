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
