'use client';

import { useEffect, useState, type FormEvent } from 'react';
import { supabase } from '../lib/supabase';

type Account = { id: string; name: string; world: string; status: string; device: string; member: string; network: string; attacks: number };
const nav = [['Dashboard', '#dashboard'], ['Accounts', '#accounts'], ['Team', '#team'], ['Geräte', '#devices'], ['Angriffe', '#attacks'], ['Botschutz', '#bot-protection'], ['Scripts', '#scripts'], ['Einstellungen', '#settings'], ['Netzwerk', '#network']];

export default function Home() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [notice, setNotice] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [authChecked, setAuthChecked] = useState(false);
  const [teamId, setTeamId] = useState<string | null>(null);
  const [role, setRole] = useState('');
  const [loadingData, setLoadingData] = useState(true);

  useEffect(() => {
    if (!supabase) { setAuthChecked(true); setLoadingData(false); return; }
    supabase.auth.getSession().then(async ({ data }) => {
      const user = data.session?.user;
      setUserEmail(user?.email ?? null);
      setAuthChecked(true);
      if (user) await loadTeamData(user.id);
      else setLoadingData(false);
    });
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      const user = session?.user;
      setUserEmail(user?.email ?? null);
      if (user) loadTeamData(user.id);
      else { setAccounts([]); setTeamId(null); setRole(''); }
    });
    return () => listener.subscription.unsubscribe();
  }, []);

  const loadTeamData = async (userId: string) => {
    if (!supabase || !userId) return;
    setLoadingData(true);
    const { data: membership, error: membershipError } = await supabase
      .from('team_members').select('team_id, role').eq('user_id', userId).limit(1).maybeSingle();
    if (membershipError || !membership) {
      setTeamId(null); setRole(''); setAccounts([]); setLoadingData(false); return;
    }
    setTeamId(membership.team_id); setRole(membership.role);
    const { data: rows } = await supabase.from('game_accounts')
      .select('id, name, world, network_profile_id, created_at').eq('team_id', membership.team_id)
      .order('created_at', { ascending: false });
    const networkIds = (rows ?? []).map((row: any) => row.network_profile_id).filter(Boolean);
    let profiles: any[] = [];
    if (networkIds.length) {
      const { data } = await supabase.from('network_profiles').select('id, name').in('id', networkIds);
      profiles = data ?? [];
    }
    const profileMap = new Map(profiles.map(p => [p.id, p.name]));
    setAccounts((rows ?? []).map((row: any) => ({
      id: row.id, name: row.name, world: row.world, status: 'Offline', device: '—',
      member: roleLabel(membership.role), network: row.network_profile_id ? (profileMap.get(row.network_profile_id) ?? 'Profil') : 'Direkt', attacks: 0
    })));
    setLoadingData(false);
  };

  const action = (message: string) => { setNotice(message); window.setTimeout(() => setNotice(''), 2500); };
  const addAccount = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!supabase || !teamId) return;
    const data = new FormData(event.currentTarget);
    const name = String(data.get('name') || '').trim();
    const world = String(data.get('world') || '').trim();
    if (!name || !world) return;
    const profileName = String(data.get('network') || 'Direkt');
    let networkProfileId: string | null = null;
    if (profileName !== 'Direkt') {
      const { data: profile } = await supabase.from('network_profiles').select('id').eq('team_id', teamId).eq('name', profileName).limit(1).maybeSingle();
      networkProfileId = profile?.id ?? null;
    }
    const { data: inserted, error } = await supabase.from('game_accounts')
      .insert({ team_id: teamId, name, world, network_profile_id: networkProfileId })
      .select('id, name, world, network_profile_id')
      .single();
    if (error || !inserted) { action(`Account konnte nicht gespeichert werden: ${error?.message ?? 'Unbekannter Fehler'}`); return; }

    // Sofort lokal ergänzen, damit der neue Account ohne Seiten-Reload sichtbar wird.
    setAccounts(prev => [{
      id: inserted.id,
      name: inserted.name,
      world: inserted.world,
      status: 'Offline',
      device: '—',
      member: roleLabel(role),
      network: profileName,
      attacks: 0
    }, ...prev]);

    setDialogOpen(false); event.currentTarget.reset();
    action(`${name} wurde dauerhaft zur Teamzentrale Odin hinzugefügt`);
  };
  const logout = async () => { if (supabase) await supabase.auth.signOut(); window.location.href = '/login'; };

  if (!authChecked) return <main className="authPage"><section className="authCard"><div className="authLogo">⚔</div><div className="eyebrow">TEAMZENTRALE ODIN</div><h1>Laden…</h1><p className="muted">Sitzung wird geprüft.</p></section></main>;
  const onlineCount = accounts.filter(a => a.status === 'Online').length;

  return <div className="shell">
    <aside className="sidebar"><div className="brand">⚔ Teamzentrale Odin</div><nav className="nav">{nav.map(([x, href], i) => <a className={i === 0 ? 'active' : ''} href={href} key={x}>{x}</a>)}</nav></aside>
    <div style={{ flex: 1, minWidth: 0 }}><div className="mobileNav"><strong>⚔ Teamzentrale Odin</strong><div style={{display:'flex',gap:8}}><a href="/login" className="mobileAdd" aria-label="Anmelden">↪</a><a href="#accounts" className="mobileAdd" aria-label="Account hinzufügen">＋</a></div></div>
      <main className="main">
        <header className="top"><div><div className="eyebrow">Teamzentrale Odin</div><h1 className="title">Dashboard</h1><div className="muted">{userEmail ? `Angemeldet als ${userEmail}` : 'Noch nicht angemeldet'}</div></div><div className="user">{userEmail ? <><span className="userEmail" title={userEmail}>👤 {userEmail}</span><button className="button secondary" onClick={logout}>Abmelden</button></> : <a className="button" href="/login">Anmelden</a>}</div></header>
        {notice && <div className="toast">✓ {notice}</div>}
        <section id="dashboard" className="grid"><Metric label="Accounts" value={loadingData ? '…' : String(accounts.length)} note={teamId ? 'aus Supabase' : 'kein Team verbunden'}/><Metric label="Online" value={String(onlineCount)} note="aktuell verbunden"/><Metric label="Angriffe" value="0" note="wird als Nächstes live" tone="danger"/><Metric label="Botschutz" value="0" note="wird als Nächstes live" tone="warning"/></section>
        <section id="accounts" className="section card"><SectionHead title="Accounts" button={teamId ? "+ Account hinzufügen" : undefined} onClick={() => setDialogOpen(true)}/>{loadingData ? <p className="muted">Accounts werden geladen…</p> : accounts.length === 0 ? <div className="empty"><strong>Noch keine Spielaccounts</strong><div className="muted">Füge deinen ersten Account hinzu. Er wird dauerhaft in Supabase gespeichert.</div></div> : <div className="table-wrap"><table className="table"><thead><tr><th>Account</th><th>Welt</th><th>Status</th><th>Spieler</th><th>Gerät</th><th>Netzwerk</th><th>Angriffe</th></tr></thead><tbody>{accounts.map(a=><tr key={a.id}><td><strong>{a.name}</strong></td><td>{a.world}</td><td><span className={'pill '+(a.status==='Online'?'online':'')}>{a.status==='Online'?'●':'○'} {a.status}</span></td><td>{a.member}</td><td>{a.device}</td><td>{a.network}</td><td>—</td></tr>)}</tbody></table></div>}</section>
        <section id="team" className="section card"><SectionHead title="Team & Rollen" button="+ Mitglied einladen" onClick={() => action('Einladung vorbereitet')}/><div className="list">{teamId ? <Row icon="👑" title={role || 'Mitglied'} meta={`${role || 'Player'} · aktuell angemeldet`} /> : <Row icon="○" title="Kein Team geladen" meta="Bitte anmelden"/>}</div></section>
        <section id="devices" className="section card"><SectionHead title="Geräte"/><div className="grid"><Mini title="PC" meta="Noch keine aktive Session" status="⚪ Bereit"/><Mini title="iPhone" meta="Mobile Dashboard-Ansicht" status="🟢 Verbunden"/><Mini title="Weitere Geräte" meta="Wird später verwaltet" status="⚪ Bereit"/></div></section>
        <section id="attacks" className="section card"><SectionHead title="Angriffe"/><Alert icon="ℹ️" title="Noch keine Live-Angriffsdaten" text="Die echte Angriffserkennung wird als nächster Schritt angebunden."/></section>
        <section id="bot-protection" className="section card"><SectionHead title="Botschutz"/><Alert icon="ℹ️" title="Noch keine Live-Botschutzdaten" text="Die echte Erkennung wird als nächster Schritt angebunden."/></section>
        <section id="scripts" className="section card"><SectionHead title="Scripts" button="Script verwalten" onClick={() => action('Script-Verwaltung geöffnet')}/><div className="list"><Row icon="✓" title="Angriffserkennung" meta="Vorbereitet · noch nicht live angebunden"/><Row icon="✓" title="Benachrichtigungen" meta="Vorbereitet · noch nicht live angebunden"/><Row icon="○" title="Dorfübersicht" meta="Deaktiviert"/></div></section>
        <section id="settings" className="section card"><SectionHead title="Einstellungen"/><div className="settings"><label>Angriffs-Benachrichtigungen <input type="checkbox" defaultChecked/></label><label>Botschutz-Hinweise <input type="checkbox" defaultChecked/></label><label>Desktop Push <input type="checkbox" defaultChecked/></label></div></section>
        <section id="network" className="section card"><SectionHead title="Netzwerk"/><Alert icon="🌐" title="Account-spezifisches Netzwerk" text="Jeder Spielaccount kann später einem eigenen Network Profile mit fester Egress-IP zugeordnet werden."/><div className="muted" style={{marginTop:12}}>Die Datenstruktur dafür ist bereits vorhanden. Die tatsächliche feste IP-Routing-Schicht wird separat angebunden.</div></section>
      </main>
      <nav className="bottomNav" aria-label="Mobile Navigation">{[['⌂','Dashboard','#dashboard'],['♟','Accounts','#accounts'],['👥','Team','#team'],['⋯','Mehr','#settings']].map(([icon,label,href]) => <a href={href} key={label}><span>{icon}</span><small>{label}</small></a>)}</nav>
    </div>
    {dialogOpen && <div className="modalBackdrop" role="presentation" onMouseDown={() => setDialogOpen(false)}><div className="modal" role="dialog" aria-modal="true" aria-labelledby="add-account-title" onMouseDown={e => e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2 id="add-account-title">Account hinzufügen</h2></div><button className="iconButton" onClick={() => setDialogOpen(false)} aria-label="Schließen">×</button></div><form onSubmit={addAccount}><label className="field">Accountname<input name="name" placeholder="z. B. Odin123" required autoFocus /></label><label className="field">Welt<input name="world" placeholder="z. B. Welt 201" required /></label><label className="field">Spieler<input name="member" value={userEmail ?? ''} readOnly /></label><label className="field">Netzwerkprofil<select name="network" defaultValue="Direkt"><option>Direkt</option><option>Profil A</option><option>Profil B</option></select></label><div className="modalActions"><button type="button" className="button secondary" onClick={() => setDialogOpen(false)}>Abbrechen</button><button type="submit" className="button">Account hinzufügen</button></div></form></div></div>}
  </div>;
}
function roleLabel(role: string){ return role === 'Owner' ? 'Owner' : role === 'Admin' ? 'Admin' : role === 'Observer' ? 'Observer' : 'Player'; }
function Metric({label,value,note,tone}:{label:string,value:string,note:string;tone?:string}){return <div className="card"><div className="muted">{label}</div><div className={'metric '+(tone||'')}>{value}</div><div className="muted">{note}</div></div>}
function SectionHead({title,button,onClick}:{title:string;button?:string;onClick?:()=>void}){return <div className="sectionhead"><h2>{title}</h2>{button?<button className="button" onClick={onClick}>{button}</button>:<span className="muted">Heute</span>}</div>}
function Row({icon,title,meta}:{icon:string;title:string;meta:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{meta}</div></div></div>}
function Mini({title,meta,status}:{title:string;meta:string;status:string}){return <div className="card"><strong>{title}</strong><div className="muted" style={{margin:'6px 0'}}>{meta}</div><span className="pill">{status}</span></div>}
function Alert({icon,title,text}:{icon:string;title:string;text:string}){return <div className="event"><span>{icon}</span><div style={{flex:1}}><strong>{title}</strong><div className="muted">{text}</div></div></div>}
