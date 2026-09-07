'use client';

import { useState, type FormEvent } from 'react';

type Account = { name: string; world: string; status: string; device: string; member: string; network: string; attacks: number };
const initialAccounts: Account[] = [
  { name: 'SpielerA', world: 'Welt 201', status: 'Online', device: 'PC', member: 'Max', network: 'Profil A', attacks: 2 },
  { name: 'SpielerB', world: 'Welt 205', status: 'Online', device: 'Laptop', member: 'Lukas', network: 'Profil B', attacks: 0 },
  { name: 'SpielerC', world: 'Welt 201', status: 'Offline', device: '—', member: 'Max', network: 'Direkt', attacks: 4 }
];
const nav = [['Dashboard', '#dashboard'], ['Accounts', '#accounts'], ['Team', '#team'], ['Geräte', '#devices'], ['Angriffe', '#attacks'], ['Botschutz', '#bot-protection'], ['Scripts', '#scripts'], ['Einstellungen', '#settings'], ['Netzwerk', '#network']];

export default function Home() {
  const [accounts, setAccounts] = useState<Account[]>(initialAccounts);
  const [notice, setNotice] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const action = (message: string) => { setNotice(message); window.setTimeout(() => setNotice(''), 2500); };
  const addAccount = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const name = String(data.get('name') || '').trim();
    const world = String(data.get('world') || '').trim();
    const member = String(data.get('member') || 'Max');
    const network = String(data.get('network') || 'Direkt');
    if (!name || !world) return;
    setAccounts(current => [...current, { name, world, status: 'Offline', device: '—', member, network, attacks: 0 }]);
    setDialogOpen(false);
    action(`${name} wurde zur Teamzentrale Odin hinzugefügt`);
  };
  return <div className="shell">
    <aside className="sidebar"><div className="brand">⚔ Teamzentrale Odin</div><nav className="nav">{nav.map(([x, href], i) => <a className={i === 0 ? 'active' : ''} href={href} key={x}>{x}</a>)}</nav></aside>
    <div style={{ flex: 1, minWidth: 0 }}><div className="mobileNav"><strong>⚔ Teamzentrale Odin</strong><a href="#accounts" className="mobileAdd" aria-label="Account hinzufügen">＋</a></div>
      <main className="main">
        <header className="top"><div><div className="eyebrow">Teamzentrale Odin</div><h1 className="title">Dashboard</h1><div className="muted">Guten Morgen, Team Admin</div></div><div className="user">👤 Team Admin</div></header>
        {notice && <div className="toast">✓ {notice}</div>}
        <section id="dashboard" className="grid"><Metric label="Accounts" value={String(accounts.length + 9)} note="im Team"/><Metric label="Online" value="8" note="aktuell verbunden"/><Metric label="Angriffe" value="3" note="offen" tone="danger"/><Metric label="Botschutz" value="1" note="Aufmerksamkeit nötig" tone="warning"/></section>
        <section id="accounts" className="section card"><SectionHead title="Accounts" button="+ Account hinzufügen" onClick={() => setDialogOpen(true)}/><div className="table-wrap"><table className="table"><thead><tr><th>Account</th><th>Welt</th><th>Status</th><th>Spieler</th><th>Gerät</th><th>Netzwerk</th><th>Angriffe</th></tr></thead><tbody>{accounts.map(a=><tr key={a.name}><td><strong>{a.name}</strong></td><td>{a.world}</td><td><span className={'pill '+(a.status==='Online'?'online':'')}>{a.status==='Online'?'●':'○'} {a.status}</span></td><td>{a.member}</td><td>{a.device}</td><td>{a.network}</td><td>{a.attacks ? `⚔ ${a.attacks}` : '—'}</td></tr>)}</tbody></table></div></section>
        <section id="team" className="section card"><SectionHead title="Team & Rollen" button="+ Mitglied einladen" onClick={() => action('Einladung vorbereitet')}/><div className="list"><Row icon="👑" title="Team Admin" meta="Owner · Vollzugriff"/><Row icon="🎮" title="Max" meta="Player · Accounts A, C"/><Row icon="🎮" title="Lukas" meta="Player · Account B"/><Row icon="👁" title="Beobachter" meta="Observer · Nur Ansicht"/></div></section>
        <section id="devices" className="section card"><SectionHead title="Geräte"/><div className="grid"><Mini title="PC" meta="Max · SpielerA" status="🟢 Online"/><Mini title="Laptop" meta="Lukas · SpielerB" status="🟢 Online"/><Mini title="Handy" meta="Max · keine Session" status="⚪ Bereit"/></div></section>
        <section id="attacks" className="section card"><SectionHead title="Angriffe"/><Alert icon="⚔️" title="SpielerA · Dorf 123|456" text="Angriff erkannt · 04:32:17 verbleibend"/><Alert icon="⚔️" title="SpielerC · Dorf 124|456" text="Angriff erkannt · 08:14:52 verbleibend"/><Alert icon="ℹ️" title="Keine weiteren neuen Angriffe" text="Die Übersicht wird später live aktualisiert."/></section>
        <section id="bot-protection" className="section card"><SectionHead title="Botschutz"/><Alert icon="⚠️" title="SpielerC · Welt 201" text="Botschutz-Hinweis erkannt · Aktion erforderlich"/></section>
        <section id="scripts" className="section card"><SectionHead title="Scripts" button="Script verwalten" onClick={() => action('Script-Verwaltung geöffnet')}/><div className="list"><Row icon="✓" title="Angriffserkennung" meta="v1.4.2 · aktiviert · genehmigt"/><Row icon="✓" title="Benachrichtigungen" meta="v3.0.1 · aktiviert · genehmigt"/><Row icon="○" title="Dorfübersicht" meta="v2.1.0 · deaktiviert"/></div></section>
        <section id="settings" className="section card"><SectionHead title="Einstellungen"/><div className="settings"><label>Angriffs-Benachrichtigungen <input type="checkbox" defaultChecked/></label><label>Botschutz-Hinweise <input type="checkbox" defaultChecked/></label><label>Desktop Push <input type="checkbox" defaultChecked/></label></div></section>
        <section id="network" className="section card"><SectionHead title="Netzwerk"/><Alert icon="🌐" title="Network Profile A" text="Account SpielerA · Status: bereit · Egress: abstrahiert"/><Alert icon="🌐" title="Network Profile B" text="Account SpielerB · Status: bereit · Egress: abstrahiert"/><div className="muted" style={{marginTop:12}}>Die Netzwerk-Schicht ist für spätere regelkonforme Egress-Anbindungen vorbereitet.</div></section>
        <section className="section card"><SectionHead title="Letzte Ereignisse"/><Event icon="⚔️" text="SpielerA — neuer Angriff erkannt" time="vor 2 Min."/><Event icon="🟢" text="SpielerB — Gerät verbunden" time="vor 7 Min."/><Event icon="⚠️" text="SpielerC — Botschutz-Hinweis erkannt" time="vor 13 Min."/><Event icon="👥" text="Max wurde dem Team hinzugefügt" time="vor 31 Min."/></section>
      </main>
      <nav className="bottomNav" aria-label="Mobile Navigation">{[['⌂','Dashboard','#dashboard'],['♟','Accounts','#accounts'],['👥','Team','#team'],['⋯','Mehr','#settings']].map(([icon,label,href]) => <a href={href} key={label}><span>{icon}</span><small>{label}</small></a>)}</nav>
    </div>
    {dialogOpen && <div className="modalBackdrop" role="presentation" onMouseDown={() => setDialogOpen(false)}><div className="modal" role="dialog" aria-modal="true" aria-labelledby="add-account-title" onMouseDown={e => e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2 id="add-account-title">Account hinzufügen</h2></div><button className="iconButton" onClick={() => setDialogOpen(false)} aria-label="Schließen">×</button></div><form onSubmit={addAccount}><label className="field">Accountname<input name="name" placeholder="z. B. Odin123" required autoFocus /></label><label className="field">Welt<input name="world" placeholder="z. B. Welt 201" required /></label><label className="field">Spieler<select name="member" defaultValue="Max"><option>Max</option><option>Lukas</option><option>Team Admin</option></select></label><label className="field">Netzwerkprofil<select name="network" defaultValue="Direkt"><option>Direkt</option><option>Profil A</option><option>Profil B</option></select></label><div className="modalActions"><button type="button" className="button secondary" onClick={() => setDialogOpen(false)}>Abbrechen</button><button type="submit" className="button">Account hinzufügen</button></div></form></div></div>}
  </div>;
}
function Metric({label,value,note,tone}:{label:string,value:string,note:string;tone?:string}){return <div className="card"><div className="muted">{label}</div><div className={'metric '+(tone||'')}>{value}</div><div className="muted">{note}</div></div>}
function SectionHead({title,button,onClick}:{title:string;button?:string;onClick?:()=>void}){return <div className="sectionhead"><h2>{title}</h2>{button?<button className="button" onClick={onClick}>{button}</button>:<span className="muted">Heute</span>}</div>}
function Row({icon,title,meta}:{icon:string;title:string;meta:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{meta}</div></div></div>}
function Mini({title,meta,status}:{title:string;meta:string;status:string}){return <div className="card"><strong>{title}</strong><div className="muted" style={{margin:'6px 0'}}>{meta}</div><span className="pill">{status}</span></div>}
function Alert({icon,title,text}:{icon:string;title:string;text:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{text}</div></div></div>}
function Event({icon,text,time}:{icon:string;text:string;time:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}>{text}</div><span className="muted">{time}</span></div>}
