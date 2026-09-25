'use client';

import { useEffect, useState, type FormEvent } from 'react';
import { supabase } from '../lib/supabase';
import VersionUpdater from '../components/VersionUpdater';
import GameNativeButton from '../components/GameNativeButton';

const APP_VERSION=process.env.NEXT_PUBLIC_APP_VERSION || '?';

type Account = { id:string; name:string; world:string; status:string; loginUsername:string };
type Profile = { id:string; name:string; public_ip:string|null; status:string };
type Credential = { username:string };
// Geraete-Sperre (account_leases, 017): welches Geraet fuehrt welches Konto.
type Lease = { account_id:string; geraet_id:string; geraet_name:string; gemeldet:string };
// Gehalten, solange sich das Geraet mindestens alle 3 Min meldet.
const LEASE_FRIST_MS=180000;
const geraetSymbol=(n:string)=>/^PC\b/.test(n)?'💻':'📱';
const vorText=(ms:number)=>{const s=Math.max(0,Math.round(ms/1000));return s<60?`vor ${s} s`:s<3600?`vor ${Math.round(s/60)} Min`:`vor ${Math.round(s/3600)} Std`;};
const nav: Array<[string,string]> = [['Dashboard','#dashboard'],['Accounts','#accounts'],['Geräte','#devices'],['GodBot','/godbot/'],['Protokoll','/protokoll/'],['Team','/team/'],['Scripts','/scripts/'],['Einstellungen','/einstellungen/']];
const CREDENTIALS_KEY='odin-game-credentials';

export default function Home(){
  const [accounts,setAccounts]=useState<Account[]>([]),[profiles,setProfiles]=useState<Profile[]>([]),[credentials,setCredentials]=useState<Record<string,Credential>>({}),[naechste,setNaechste]=useState<Record<string,{at:number;coord:string}>>({}),[takt,setTakt]=useState(0),[notice,setNotice]=useState(''),[dialogOpen,setDialogOpen]=useState(false),[credentialAccount,setCredentialAccount]=useState<Account|null>(null),[logoutOpen,setLogoutOpen]=useState(false),[authChecked,setAuthChecked]=useState(false),[userEmail,setUserEmail]=useState<string|null>(null),[teamId,setTeamId]=useState<string|null>(null),[loadingData,setLoadingData]=useState(true);
  useEffect(()=>{try{const raw=localStorage.getItem(CREDENTIALS_KEY);if(raw)setCredentials(JSON.parse(raw)||{})}catch{}},[]);
  useEffect(()=>{if(!supabase){setAuthChecked(true);setLoadingData(false);return;}supabase.auth.getSession().then(async({data})=>{const user=data.session?.user;setUserEmail(user?.email??null);setAuthChecked(true);if(user)await loadTeamData(user.id);else setLoadingData(false)});const {data:listener}=supabase.auth.onAuthStateChange((_event,session)=>{const user=session?.user;setUserEmail(user?.email??null);if(user)loadTeamData(user.id);else{setAccounts([]);setTeamId(null);setLoadingData(false)}});return()=>listener.subscription.unsubscribe()},[]);
  // Naechsten offenen Termin je Account aus den abgeglichenen Plaenen lesen.
  const ladeTermine=async(ids:string[])=>{
    if(!ids.length||!supabase)return;
    try{
      const {data:plans}=await supabase.from('godbot_settings').select('account_id,value').eq('skey','tw_tabben_plan').in('account_id',ids);
      const n:Record<string,{at:number;coord:string}>={};
      for(const p of (plans??[]) as {account_id:string;value:string}[]){
        try{
          const v=JSON.parse(p.value) as {attacks?:{coord?:string;attacks?:{atMs?:number}[]}[]};
          let best=Infinity,coord='';
          for(const d of v.attacks??[])for(const x of d.attacks??[]){const t=x.atMs??0;if(t>Date.now()&&t<best){best=t;coord=d.coord??'';}}
          if(best<Infinity)n[p.account_id]={at:best,coord};
        }catch{}
      }
      setNaechste(n);
    }catch{}
  };

  // Welches Geraet fuehrt gerade welches Konto - alle 20 s.
  const [leases,setLeases]=useState<Lease[]>([]);
  useEffect(()=>{
    if(!supabase||!teamId)return;
    const laden=async()=>{try{const {data}=await supabase!.from('account_leases').select('account_id,geraet_id,geraet_name,gemeldet').eq('team_id',teamId);setLeases((data??[]) as Lease[]);}catch{}};
    laden();
    const t=setInterval(laden,20000);
    return()=>clearInterval(t);
  },[teamId]);
  const leaseAktiv=(l:Lease)=>Date.now()-new Date(l.gemeldet).getTime()<LEASE_FRIST_MS;
  const geraetZeile=(id:string)=>{
    const l=leases.find(x=>x.account_id===id);
    if(!l)return <span className="muted" style={{fontSize:11}}>kein Gerät</span>;
    const alt=Date.now()-new Date(l.gemeldet).getTime();
    if(!leaseAktiv(l))return <span className="muted" style={{fontSize:11}} title={l.geraet_name}>frei · zuletzt {l.geraet_name} {vorText(alt)}</span>;
    return <span style={{fontSize:11,color:'#15803d'}} title={`${l.geraet_name} · gemeldet ${vorText(alt)}`}>{geraetSymbol(l.geraet_name)} {l.geraet_name}</span>;
  };

  // Restzeit sekuendlich neu zeichnen, ohne erneut zu laden.
  useEffect(()=>{const t=setInterval(()=>setTakt(x=>x+1),1000);return()=>clearInterval(t)},[]);
  // Plaene alle zwei Minuten auffrischen - abgeschickte Termine fallen so raus.
  useEffect(()=>{
    if(!accounts.length)return;
    const ids=accounts.map(a=>a.id);
    const t=setInterval(()=>ladeTermine(ids),120000);
    return()=>clearInterval(t);
  },[accounts]);

  // Account entfernen. Ohne das fragt der Dienst fuer ungenutzte Accounts
  // dauerhaft Daten ab - drei Abfragen alle fuenf Minuten, rund 860 am Tag.
  const accountLoeschen=async(id:string,name:string)=>{
    if(!supabase||!teamId)return;
    if(!window.confirm(`Account "${name}" wirklich entfernen? Zugehörige GodBot-Einstellungen werden mit gelöscht.`))return;
    const {error}=await supabase.from('game_accounts').delete().eq('id',id).eq('team_id',teamId);
    if(error){action(`Konnte nicht entfernt werden: ${error.message}`);return}
    setAccounts(prev=>prev.filter(a=>a.id!==id));
    action(`${name} entfernt`);
  };

  const loadTeamData=async(userId:string)=>{if(!supabase)return;setLoadingData(true);const {data:membership,error:me}=await supabase.from('team_members').select('team_id').eq('user_id',userId).limit(1).maybeSingle();if(me||!membership){setTeamId(null);setAccounts([]);setLoadingData(false);return;}setTeamId(membership.team_id);const {data:rows}=await supabase.from('game_accounts').select('id,name,world,login_username,created_at').eq('team_id',membership.team_id).order('created_at',{ascending:false});const loadedCredentials:Record<string,Credential>={};(rows??[]).forEach((r:any)=>{if(r.login_username)loadedCredentials[r.id]={username:r.login_username}});if(Object.keys(loadedCredentials).length){setCredentials(prev=>({...prev,...loadedCredentials}));try{localStorage.setItem(CREDENTIALS_KEY,JSON.stringify({...JSON.parse(localStorage.getItem(CREDENTIALS_KEY)||'{}'),...loadedCredentials}))}catch{}}setAccounts((rows??[]).map((r:any)=>({id:r.id,name:r.name,world:r.world,status:'Offline',loginUsername:r.login_username??''})));setLoadingData(false)
    ladeTermine((rows??[]).map((r:any)=>r.id));
  };
  const action=(m:string)=>{setNotice(m);window.setTimeout(()=>setNotice(''),3000)};
  const logout=async()=>{if(supabase){const {error}=await supabase.auth.signOut();if(error){action(`Abmelden fehlgeschlagen: ${error.message}`);return;}}setLogoutOpen(false);action('Erfolgreich abgemeldet.')};
  const saveCredentials=async(e:FormEvent<HTMLFormElement>)=>{e.preventDefault();if(!credentialAccount)return;const data=new FormData(e.currentTarget),username=String(data.get('username')||'').trim(),passwort=String(data.get('password')||'');const next={...credentials};if(username)next[credentialAccount.id]={username};else delete next[credentialAccount.id];
    // Passwort ausschliesslich geraetelokal, verschluesselt im Android-Keystore.
    try{ (window as any).Android?.setGameCredentials?.(credentialAccount.id,username,passwort); }catch{}
    if(supabase){const {error}=await supabase.from('game_accounts').update({login_username:username}).eq('id',credentialAccount.id).eq('team_id',teamId??'');if(error){action(`Zugangsdaten konnten nicht gespeichert werden: ${error.message}`);return;}}setCredentials(next);try{localStorage.setItem(CREDENTIALS_KEY,JSON.stringify(next))}catch{};setAccounts(prev=>prev.map(a=>a.id===credentialAccount.id?{...a,loginUsername:username}:a));setCredentialAccount(null);action(passwort?'Gespeichert. Passwort liegt nur auf diesem Gerät.':'Benutzername gespeichert.')};
  const addAccount=async(e:FormEvent<HTMLFormElement>)=>{e.preventDefault();if(!supabase||!teamId){action('Kein Team verbunden – bitte zuerst anmelden.');return;}const form=e.currentTarget;const data=new FormData(form),name=String(data.get('name')||'').trim(),world=(()=>{const x=String(data.get('world')||'').trim().toLowerCase().replace(/\s|welt/g,'');return /^[0-9]+$/.test(x)?`de${x}`:x;})();if(!name||!world){action('Accountname und Welt sind erforderlich.');return;}const {data:inserted,error}=await supabase.from('game_accounts').insert({team_id:teamId,name,world}).select('id,name,world,login_username').single();if(error||!inserted){action(`Account konnte nicht gespeichert werden: ${error?.message??'Unbekannter Fehler'}`);return;}setAccounts(prev=>[{id:inserted.id,name:inserted.name,world:inserted.world,status:'Offline',loginUsername:inserted.login_username??''},...prev]);setDialogOpen(false);form.reset();action(`${name} wurde dauerhaft zur Teamzentrale Odin hinzugefügt`)};
  
  if(!authChecked)return <main className="authPage"><section className="authCard"><div className="authLogo">⚔</div><div className="eyebrow">TEAMZENTRALE ODIN</div><h1>Laden…</h1><p className="muted">Sitzung wird geprüft.</p></section></main>;
  const goLogin=()=>{window.location.href='/login/';};
  return <div className="shell"><aside className="sidebar"><div className="brand">⚔ Teamzentrale Odin</div><nav className="nav">{nav.map(([x,href],i)=><a className={i===0?'active':''} href={href} key={x}>{x}</a>)}</nav></aside><div style={{flex:1,minWidth:0}}><div className="mobileNav"><strong>⚔ Teamzentrale Odin</strong><span className="muted">v{APP_VERSION}</span></div><main className="main"><header className="top" style={{position:'sticky',top:0,zIndex:30,background:'var(--bg,#fff)',borderBottom:'1px solid rgba(0,0,0,.08)',display:'flex',alignItems:'center',justifyContent:'space-between',gap:12}}><h1 className="title" style={{whiteSpace:'nowrap',margin:0}}>⚔ Teamzentrale Odin</h1><VersionUpdater/></header>{notice&&<div className="toast">✓ {notice}</div>}<section id="accounts" className="section card"><SectionHead title="Accounts" button="+" onClick={teamId?()=>setDialogOpen(true):()=>action('Bitte zuerst anmelden.')}/>{loadingData?<p className="muted">Accounts werden geladen…</p>:accounts.length===0?<div className="empty"><strong>Noch keine Spielaccounts</strong><div className="muted">Füge deinen ersten Account über das + hinzu.</div></div>:<div className="table-wrap"><table className="table"><thead><tr><th>Account</th><th>Welt</th><th>Angemeldet als</th><th>Als Nächstes</th><th>Spiel</th></tr></thead><tbody>{accounts.map(a=><tr key={a.id}><td><strong>{a.name}</strong><br/>{geraetZeile(a.id)}</td><td>{a.world}</td><td>{(credentials[a.id]?.username||a.loginUsername)||<span className="muted">nicht hinterlegt</span>}</td><td>{naechste[a.id]?(()=>{const sek=Math.max(0,Math.floor((naechste[a.id].at-Date.now())/1000));const h=Math.floor(sek/3600),m=Math.floor((sek%3600)/60),ss=sek%60;const rest=h>0?`${h} h ${m} min`:m>0?`${m} min ${ss} s`:`${ss} s`;return <span title={naechste[a.id].coord}><strong style={{color:sek<300?'#b45309':undefined}}>{rest}</strong><br/><span className="muted">{new Date(naechste[a.id].at).toLocaleTimeString('de-DE',{hour:'2-digit',minute:'2-digit',second:'2-digit'})} · {naechste[a.id].coord}</span></span>;})():<span className="muted">kein Termin</span>}</td><td><div className="gameActions"><GameNativeButton accountId={a.id} username={credentials[a.id]?.username||a.loginUsername||''} world={a.world} accounts={accounts.map(x=>({id:x.id,name:x.name,world:x.world,username:credentials[x.id]?.username||x.loginUsername||''}))} teamId={teamId}/><button type="button" className="iconButton smallIcon" onClick={()=>setCredentialAccount(a)} title="Benutzername hinterlegen" aria-label={`Benutzername für ${a.name}`}>🔑</button><button type="button" className="iconButton smallIcon" onClick={()=>accountLoeschen(a.id,a.name)} title="Account entfernen" aria-label={`${a.name} entfernen`}>🗑</button></div></td></tr>)}</tbody></table></div>}</section><section id="devices" className="section card"><SectionHead title="Geräte"/>{(()=>{const aktiv=leases.filter(leaseAktiv);if(!aktiv.length)return <p className="muted">Gerade führt kein Gerät ein Konto. GodBot läuft nur auf dem Gerät, das ein Konto führt – in der App oder am PC mit Odin PC.</p>;const nachGeraet:Record<string,Lease[]>={};for(const l of aktiv)(nachGeraet[l.geraet_id]=nachGeraet[l.geraet_id]||[]).push(l);return <div className="list">{Object.values(nachGeraet).map(ls=>{const neu=Math.max(...ls.map(l=>new Date(l.gemeldet).getTime()));return <div key={ls[0].geraet_id} className="event"><div style={{fontSize:22}}>{geraetSymbol(ls[0].geraet_name)}</div><div><strong>{ls[0].geraet_name||'Gerät'}</strong><div className="muted">{ls.map(l=>{const a=accounts.find(x=>x.id===l.account_id);return a?`${a.name} · ${a.world}`:l.account_id.slice(0,8);}).join(', ')} · gemeldet {vorText(Date.now()-neu)}</div></div></div>;})}</div>;})()}</section><section id="attacks" className="section card"><SectionHead title="Angriffe"/><Alert icon="ℹ️" title="Noch keine Live-Angriffsdaten" text="Die echte Angriffserkennung wird als nächster Schritt angebunden."/></section><section id="bot-protection" className="section card"><SectionHead title="Botschutz"/><Alert icon="ℹ️" title="Noch keine Live-Botschutzdaten" text="Die echte Erkennung wird als nächster Schritt angebunden."/></section><section id="scripts" className="section card"><SectionHead title="Scripts" button="Script-Verwaltung öffnen" onClick={()=>window.location.assign('/scripts/')} /><div className="list"><Row icon="🧩" title="Tampermonkey / GodBot" meta="Zentrale Verwaltung vorbereitet"/><Row icon="🔔" title="Benachrichtigungen" meta="Wird als Nächstes ausgebaut"/></div></section><section id="settings" className="section card"><SectionHead title="Einstellungen"/><div className="settings"><label>Angriffs-Benachrichtigungen <input type="checkbox" defaultChecked/></label><label>Botschutz-Hinweise <input type="checkbox" defaultChecked/></label><label>Desktop Push <input type="checkbox" defaultChecked/></label></div></section></main><footer className="odinFooter" style={{display:'flex',alignItems:'center',justifyContent:'space-between',gap:12,padding:'10px 16px',borderTop:'1px solid rgba(0,0,0,.08)',fontSize:13}}>{userEmail?<><button type="button" className="authStatus loggedIn" style={{maxWidth:'60%',overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap'}} onClick={()=>setLogoutOpen(true)}>Angemeldet · {userEmail}</button><span className="muted">Profil</span></>:<button type="button" className="authStatus loggedOut" onClick={goLogin}>Anmelden</button>}</footer><nav className="bottomNav" aria-label="Mobile Navigation">{[['⌂','Dashboard','/'],['📋','Protokoll','/protokoll/'],['⚙','Einstellungen','/einstellungen/']].map(([icon,label,href])=> <a href={href} key={label}><span>{icon}</span><small>{label}</small></a>)}</nav></div>{dialogOpen&&<div className="modalBackdrop" role="presentation" onMouseDown={()=>setDialogOpen(false)}><div className="modal" role="dialog" aria-modal="true" aria-labelledby="add-account-title" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2 id="add-account-title">Account hinzufügen</h2></div><button type="button" className="iconButton" onClick={()=>setDialogOpen(false)} aria-label="Schließen">×</button></div><form onSubmit={addAccount}><label className="field">Accountname<input name="name" placeholder="z. B. Odin123" required autoFocus/></label><label className="field">Welt<input name="world" placeholder="z. B. de256" required/><span className="muted" style={{fontSize:11}}>Serverkennung wie in der Adresse: de256, en120. Eine reine Zahl wird automatisch zu de… ergänzt.</span></label><label className="field">Zugriff<input name="member" value="Alle Teammitglieder" readOnly/></label><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setDialogOpen(false)}>Abbrechen</button><button type="submit" className="button">Account hinzufügen</button></div></form></div></div>}{credentialAccount&&<div className="modalBackdrop" role="presentation" onMouseDown={()=>setCredentialAccount(null)}><div className="modal" role="dialog" aria-modal="true" aria-labelledby="credential-title" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">{credentialAccount.name} · {credentialAccount.world}</div><h2 id="credential-title">Die Stämme Zugangsdaten</h2></div><button type="button" className="iconButton" onClick={()=>setCredentialAccount(null)} aria-label="Schließen">×</button></div><form onSubmit={saveCredentials}><label className="field">Benutzername<input name="username" autoComplete="username" defaultValue={credentials[credentialAccount.id]?.username||credentialAccount.loginUsername||''} placeholder="Die Stämme Benutzername"/></label><label className="field">Passwort<input name="password" type="password" autoComplete="current-password" placeholder="nur auf diesem Gerät"/></label><div className="permissionNote" style={{marginTop:14}}>Benutzername und Welt werden im Team gespeichert. Das Spielpasswort bleibt <strong>nur auf diesem Gerät</strong>, verschlüsselt über den Android-Schlüsselspeicher – es wird nicht ins Team übertragen und ist für niemanden sonst lesbar. Mit hinterlegtem Passwort meldet der Spiel-Knopf den Account selbst an.</div><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setCredentialAccount(null)}>Abbrechen</button><button type="submit" className="button">Speichern</button></div></form></div></div>}{logoutOpen&&<div className="modalBackdrop" role="presentation" onMouseDown={()=>setLogoutOpen(false)}><div className="modal" role="dialog" aria-modal="true" aria-labelledby="logout-title" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2 id="logout-title">Abmelden</h2></div><button type="button" className="iconButton" onClick={()=>setLogoutOpen(false)} aria-label="Schließen">×</button></div><p className="muted" style={{margin:'0 0 18px'}}>Du bist als <strong>{userEmail}</strong> angemeldet. Möchtest du dich abmelden?</p><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setLogoutOpen(false)}>Abbrechen</button><button type="button" className="button" onClick={logout}>Abmelden</button></div></div></div>}</div>
}
function SectionHead({title,button,onClick}:{title:string;button?:string;onClick?:()=>void}){return <div className="sectionhead"><h2>{title}</h2>{button?<button type="button" className="button" onClick={onClick}>{button}</button>:null}</div>}
function Row({icon,title,meta}:{icon:string;title:string;meta:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{meta}</div></div></div>}
function Alert({icon,title,text}:{icon:string;title:string;text:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{text}</div></div></div>}
