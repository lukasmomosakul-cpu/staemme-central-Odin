'use client';

import { useEffect, useState } from 'react';

const GODBOT_URL = 'https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js';
const STORAGE_KEY = 'odin-script-library';

type ScriptEntry = { id:string; name:string; source:string; enabled:boolean; type:'Tampermonkey'|'Gist'; };
const defaults: ScriptEntry[] = [
  { id:'godbot', name:'GodBot', source:GODBOT_URL, enabled:false, type:'Gist' },
];

export default function ScriptsPage(){
  const [scripts,setScripts]=useState<ScriptEntry[]>(defaults);
  const [url,setUrl]=useState('');
  const [name,setName]=useState('');
  const [message,setMessage]=useState('');

  useEffect(()=>{
    try { const saved=localStorage.getItem(STORAGE_KEY); if(saved) setScripts(JSON.parse(saved)); } catch {}
  },[]);
  const persist=(next:ScriptEntry[])=>{setScripts(next);localStorage.setItem(STORAGE_KEY,JSON.stringify(next));};
  const toggle=(id:string)=>persist(scripts.map(s=>s.id===id?{...s,enabled:!s.enabled}:s));
  const add=()=>{
    const source=url.trim(); if(!source) return;
    try { const parsed=new URL(source); if(parsed.protocol!=='https:') throw new Error();
      const entry={id:crypto.randomUUID(),name:name.trim()||'Tampermonkey Script',source,enabled:false,type:'Tampermonkey' as const};
      persist([...scripts,entry]); setUrl(''); setName(''); setMessage('Script hinzugefügt.');
    } catch { setMessage('Bitte eine gültige HTTPS-URL verwenden.'); }
  };
  return <main style={{minHeight:'100vh',padding:'clamp(10px,3vw,18px)',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}><div style={{maxWidth:900,margin:'0 auto'}}>
    <a href="/" className="muted">← Zur Teamzentrale</a>
    <div className="eyebrow" style={{marginTop:18}}>TEAMZENTRALE ODIN</div>
    <section className="card section" style={{marginTop:14}}><div className="sectionhead"><div><h1 style={{margin:0}}>🧩 Scripts</h1><div className="muted">Tampermonkey-Skripte und externe Script-Quellen zentral verwalten.</div></div><a href="/game" className="button secondary">🎮 Spiel</a></div>
      <div className="event" style={{marginTop:14}}><span>⚠️</span><div><strong>Sicherheitsmodus</strong><div className="muted">Skripte werden hier zunächst nur verwaltet. Odin führt keine fremden Skripte automatisch aus.</div></div></div>
    </section>
    <section className="card section" style={{marginTop:14}}><div className="sectionhead"><h2>Script-Bibliothek</h2><span className="muted">{scripts.length} Einträge</span></div>
      <div className="list">{scripts.map(s=><div className="event" key={s.id}><span>{s.enabled?'🟢':'⚪'}</span><div style={{flex:1,minWidth:0}}><strong>{s.name}</strong><div className="muted" style={{wordBreak:'break-all'}}>{s.type} · {s.source}</div></div><button className={'button '+(s.enabled?'':'secondary')} onClick={()=>toggle(s.id)}>{s.enabled?'Deaktivieren':'Aktivieren'}</button></div>)}</div>
    </section>
    <section className="card section" style={{marginTop:14}}><div className="sectionhead"><h2>Script hinzufügen</h2></div>
      <label>Bezeichnung<input value={name} onChange={e=>setName(e.target.value)} placeholder="z. B. Angriffserkennung" /></label>
      <label style={{marginTop:10}}>HTTPS-Quelle<input value={url} onChange={e=>setUrl(e.target.value)} placeholder="https://…/script.user.js" inputMode="url" autoCapitalize="none" /></label>
      <button className="button" style={{marginTop:12}} onClick={add}>Script speichern</button>{message&&<div className="muted" style={{marginTop:8}}>{message}</div>}
    </section>
  </div></main>;
}
