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
                <li key={i}>{i+1}. {u.username || u.wallet} â€” score: {u.score}</li>
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
