'use client';

import { useState, type ReactNode } from 'react';

const accounts = [
  { name: 'SpielerA', world: 'Welt 201', status: 'Online', device: 'PC', member: 'Max', network: 'Profil A', attacks: 2 },
  { name: 'SpielerB', world: 'Welt 205', status: 'Online', device: 'Laptop', member: 'Lukas', network: 'Profil B', attacks: 0 },
  { name: 'SpielerC', world: 'Welt 201', status: 'Offline', device: '—', member: 'Max', network: 'Direkt', attacks: 4 }
];
const nav = [['Dashboard', '#dashboard'], ['Accounts', '#accounts'], ['Team', '#team'], ['Geräte', '#devices'], ['Angriffe', '#attacks'], ['Botschutz', '#bot-protection'], ['Scripts', '#scripts'], ['Einstellungen', '#settings'], ['Netzwerk', '#network']];

export default function Home() {
  const [notice, setNotice] = useState('');
  const action = (message: string) => { setNotice(message); window.setTimeout(() => setNotice(''), 2500); };
  return <div className="shell">
    <aside className="sidebar"><div className="brand">⚔ Stämme Central</div><nav className="nav">{nav.map(([x, href], i) => <a className={i === 0 ? 'active' : ''} href={href} key={x}>{x}</a>)}</nav></aside>
    <div style={{ flex: 1 }}><div className="mobileNav"><strong>⚔ Stämme Central</strong><span>☰</span></div>
      <main className="main">
        <header className="top"><div><div className="eyebrow">Team-Zentrale / Odin</div><h1 className="title">Dashboard</h1><div className="muted">Guten Morgen, Team Admin</div></div><div className="user">👤 Team Admin</div></header>
        {notice && <div className="toast">✓ {notice}</div>}
        <section id="dashboard" className="grid"><Metric label="Accounts" value="12" note="im Team"/><Metric label="Online" value="8" note="aktuell verbunden"/><Metric label="Angriffe" value="3" note="offen" tone="danger"/><Metric label="Botschutz" value="1" note="Aufmerksamkeit nötig" tone="warning"/></section>
        <section id="accounts" className="section card"><SectionHead title="Accounts" button="+ Account hinzufügen" onClick={() => action('Account-Dialog vorbereitet')}/><table className="table"><thead><tr><th>Account</th><th>Welt</th><th>Status</th><th>Spieler</th><th>Gerät</th><th>Netzwerk</th><th>Angriffe</th></tr></thead><tbody>{accounts.map(a=><tr key={a.name}><td><strong>{a.name}</strong></td><td>{a.world}</td><td><span className={'pill '+(a.status==='Online'?'online':'')}>{a.status==='Online'?'●':'○'} {a.status}</span></td><td>{a.member}</td><td>{a.device}</td><td>{a.network}</td><td>{a.attacks ? `⚔ ${a.attacks}` : '—'}</td></tr>)}</tbody></table></section>
        <section id="team" className="section card"><SectionHead title="Team & Rollen" button="+ Mitglied einladen" onClick={() => action('Einladung vorbereitet')}/><div className="list"><Row icon="👑" title="Team Admin" meta="Owner · Vollzugriff"/><Row icon="🎮" title="Max" meta="Player · Accounts A, C"/><Row icon="🎮" title="Lukas" meta="Player · Account B"/><Row icon="👁" title="Beobachter" meta="Observer · Nur Ansicht"/></div></section>
        <section id="devices" className="section card"><SectionHead title="Geräte"/><div className="grid"><Mini title="PC" meta="Max · SpielerA" status="🟢 Online"/><Mini title="Laptop" meta="Lukas · SpielerB" status="🟢 Online"/><Mini title="Handy" meta="Max · keine Session" status="⚪ Bereit"/></div></section>
        <section id="attacks" className="section card"><SectionHead title="Angriffe"/><Alert icon="⚔️" title="SpielerA · Dorf 123|456" text="Angriff erkannt · 04:32:17 verbleibend"/><Alert icon="⚔️" title="SpielerC · Dorf 124|456" text="Angriff erkannt · 08:14:52 verbleibend"/><Alert icon="ℹ️" title="Keine weiteren neuen Angriffe" text="Die Übersicht wird später live aktualisiert."/></section>
        <section id="bot-protection" className="section card"><SectionHead title="Botschutz"/><Alert icon="⚠️" title="SpielerC · Welt 201" text="Botschutz-Hinweis erkannt · Aktion erforderlich"/></section>
        <section id="scripts" className="section card"><SectionHead title="Scripts" button="Script verwalten" onClick={() => action('Script-Verwaltung geöffnet')}/><div className="list"><Row icon="✓" title="Angriffserkennung" meta="v1.4.2 · aktiviert · genehmigt"/><Row icon="✓" title="Benachrichtigungen" meta="v3.0.1 · aktiviert · genehmigt"/><Row icon="○" title="Dorfübersicht" meta="v2.1.0 · deaktiviert"/></div></section>
        <section id="settings" className="section card"><SectionHead title="Einstellungen"/><div className="settings"><label>Angriffs-Benachrichtigungen <input type="checkbox" defaultChecked/></label><label>Botschutz-Hinweise <input type="checkbox" defaultChecked/></label><label>Desktop Push <input type="checkbox" defaultChecked/></label></div></section>
        <section id="network" className="section card"><SectionHead title="Netzwerk"/><Alert icon="🌐" title="Network Profile A" text="Account SpielerA · Status: bereit · Egress: abstrahiert"/><Alert icon="🌐" title="Network Profile B" text="Account SpielerB · Status: bereit · Egress: abstrahiert"/><div className="muted" style={{marginTop:12}}>Die Netzwerk-Schicht ist für spätere regelkonforme Egress-Anbindungen vorbereitet.</div></section>
        <section className="section card"><SectionHead title="Letzte Ereignisse"/><Event icon="⚔️" text="SpielerA — neuer Angriff erkannt" time="vor 2 Min."/><Event icon="🟢" text="SpielerB — Gerät verbunden" time="vor 7 Min."/><Event icon="⚠️" text="SpielerC — Botschutz-Hinweis erkannt" time="vor 13 Min."/><Event icon="👥" text="Max wurde dem Team hinzugefügt" time="vor 31 Min."/></section>
      </main>
    </div>
  </div>;
}
function Metric({label,value,note,tone}:{label:string,value:string,note:string,tone?:string}){return <div className="card"><div className="muted">{label}</div><div className={'metric '+(tone||'')}>{value}</div><div className="muted">{note}</div></div>}
function SectionHead({title,button,onClick}:{title:string;button?:string;onClick?:()=>void}){return <div className="sectionhead"><h2>{title}</h2>{button?<button className="button" onClick={onClick}>{button}</button>:<span className="muted">Heute</span>}</div>}
function Row({icon,title,meta}:{icon:string;title:string;meta:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{meta}</div></div></div>}
function Mini({title,meta,status}:{title:string;meta:string;status:string}){return <div className="card"><strong>{title}</strong><div className="muted" style={{margin:'6px 0'}}>{meta}</div><span className="pill">{status}</span></div>}
function Alert({icon,title,text}:{icon:string;title:string;text:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{text}</div></div></div>}
function Event({icon,text,time}:{icon:string;text:string;time:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}>{text}</div><span className="muted">{time}</span></div>}
