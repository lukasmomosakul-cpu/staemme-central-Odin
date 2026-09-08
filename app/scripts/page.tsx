'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

const GODBOT_URL = 'https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js';
const STORAGE_KEY = 'odin-script-library';

type ScriptEntry = { id:string; name:string; source:string; enabled:boolean; type:'Tampermonkey'|'Gist'; };
const defaultScript=():ScriptEntry => ({ id:crypto.randomUUID(), name:'GodBot', source:GODBOT_URL, enabled:true, type:'Gist' });

export default function ScriptsPage(){
  const [scripts,setScripts]=useState<ScriptEntry[]>([]);
  const [url,setUrl]=useState('');
  const [name,setName]=useState('');
  const [message,setMessage]=useState('');
  const [ready,setReady]=useState(false);

  useEffect(()=>{
    let cancelled=false;
    const load=async()=>{
      if(!supabase){setScripts([defaultScript()]);setReady(true);return;}
      const {data:{session}}=await supabase.auth.getSession();
      const user=session?.user;
      if(!user){setScripts([defaultScript()]);setReady(true);return;}
      const {data:membership}=await supabase.from('team_members').select('team_id').eq('user_id',user.id).limit(1).maybeSingle();
      if(!membership){setScripts([defaultScript()]);setReady(true);return;}
      const {data:rows}=await supabase.from('scripts').select('id,name,source_url,enabled,type').eq('team_id',membership.team_id).order('created_at',{ascending:true});
      if(cancelled)return;
      if(rows&&rows.length){
        const mapped=rows.map((r:any)=>({id:r.id,name:r.name,source:r.source_url,enabled:!!r.enabled,type:r.type==='Gist'?'Gist':'Tampermonkey'} as ScriptEntry));
        setScripts(mapped);
        try{localStorage.setItem(STORAGE_KEY,JSON.stringify(mapped))}catch{}
      }else{
        const seed=defaultScript();
        const {data:inserted}=await supabase.from('scripts').insert({id:seed.id,team_id:membership.team_id,name:seed.name,description:'GodBot',type:seed.type,source_url:seed.source,download_url:seed.source,enabled:true,created_by:user.id}).select('id,name,source_url,enabled,type').single();
        const next=inserted?[{id:inserted.id,name:inserted.name,source:inserted.source_url,enabled:inserted.enabled,type:'Gist' as const}]:[seed];
        setScripts(next);try{localStorage.setItem(STORAGE_KEY,JSON.stringify(next))}catch{}
      }
      setReady(true);
    };
    load();
    return()=>{cancelled=true};
  },[]);

  const persistLocal=(next:ScriptEntry[])=>{setScripts(next);try{localStorage.setItem(STORAGE_KEY,JSON.stringify(next))}catch{}};
  const toggle=async(id:string)=>{
    const current=scripts.find(s=>s.id===id); if(!current)return;
    const enabled=!current.enabled; persistLocal(scripts.map(s=>s.id===id?{...s,enabled}:s));
    if(supabase) await supabase.from('scripts').update({enabled}).eq('id',id);
  };
  const add=async()=>{
    const source=url.trim(); if(!source)return;
    try{
      const parsed=new URL(source); if(parsed.protocol!=='https:')throw new Error();
      const entry={id:crypto.randomUUID(),name:name.trim()||'Tampermonkey Script',source,enabled:false,type:'Tampermonkey' as const};
      let saved=entry;
      if(supabase){
        const {data:{session}}=await supabase.auth.getSession();
        const user=session?.user;
        const {data:membership}=user?await supabase.from('team_members').select('team_id').eq('user_id',user.id).limit(1).maybeSingle():{data:null};
        if(membership){
          const {data:inserted,error}=await supabase.from('scripts').insert({id:entry.id,team_id:membership.team_id,name:entry.name,type:entry.type,source_url:entry.source,download_url:entry.source,enabled:false,created_by:user!.id}).select('id,name,source_url,enabled,type').single();
          if(error)throw error;
          saved={id:inserted.id,name:inserted.name,source:inserted.source_url,enabled:inserted.enabled,type:'Tampermonkey'};
        }
      }
      persistLocal([...scripts,saved]);setUrl('');setName('');setMessage('Script dauerhaft gespeichert.');
    }catch(error:any){setMessage(error?.message||'Bitte eine gültige HTTPS-URL verwenden.');}
  };

  if(!ready)return <main style={{minHeight:'100vh',padding:'clamp(10px,3vw,18px)',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}><div style={{maxWidth:900,margin:'0 auto'}}><div className="eyebrow">TEAMZENTRALE ODIN</div><p className="muted">Scripts werden geladen…</p></div></main>;
  return <main style={{minHeight:'100vh',padding:'clamp(10px,3vw,18px)',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}><div style={{maxWidth:900,margin:'0 auto'}}>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}><a href="/" className="muted">← Zur Teamzentrale</a><span className="muted">Odin v0.10.0</span></div>
    <div className="eyebrow" style={{marginTop:18}}>TEAMZENTRALE ODIN</div>
    <section className="card section" style={{marginTop:14}}><div className="sectionhead"><div><h1 style={{margin:0}}>🧩 Scripts</h1><div className="muted">Scripts werden jetzt teamweit in Supabase gespeichert und beim Öffnen des Spiels an die native WebView übergeben.</div></div><a href="/game" className="button secondary">🎮 Spiel</a></div>
      <div className="event" style={{marginTop:14}}><span>🟢</span><div><strong>Ausführung aktiviert</strong><div className="muted">Aktivierte HTTPS-Scripts werden von Odin im Spiel-WebView geladen. GodBot ist standardmäßig aktiviert.</div></div></div>
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
