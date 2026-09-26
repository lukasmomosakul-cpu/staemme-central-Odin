'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

type Role = 'Owner' | 'Admin' | 'Player' | 'Observer';
type Member = { id: string; user_id: string; name: string; contact: string; role: Role; status: string; accounts: string[] };
type Account = { id: string; name: string; world: string };
type Einladung = { id: string; code: string; rolle: Role; gueltig_bis: string | null; erstellt_at: string };
// gueltig_bis NULL = laeuft nie ab (Migration 020).
const gueltigText = (bis: string | null) => bis ? 'gültig bis ' + new Date(bis).toLocaleString('de-DE') : 'unbegrenzt gültig';

// 27.09.2026: Odin-Konten verknuepfen (Migration 019). Code erzeugen
// (Owner/Admin), Code einloesen (jedes Odin-Konto).
const einladungsLink = (code: string) =>
  (typeof window !== 'undefined' ? window.location.origin : 'https://staemme-central-odin.vercel.app') + '/team?code=' + code;

function Einloesen({ onFertig }: { onFertig: () => void }) {
  const [code, setCode] = useState('');
  const [mitnehmen, setMitnehmen] = useState(true);
  const [laeuft, setLaeuft] = useState(false);
  const [meldung, setMeldung] = useState('');
  useEffect(() => {
    try { const c = new URLSearchParams(window.location.search).get('code'); if (c) setCode(c.toUpperCase()); } catch { }
  }, []);
  const los = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!supabase || !code.trim()) return;
    if (!window.confirm('Beitreten? Deine bisherige Team-Mitgliedschaft endet dabei.' + (mitnehmen ? ' Deine Spielkonten samt GodBot-Einstellungen wandern mit ins neue Team.' : ' Deine Spielkonten bleiben im alten Team zurück.'))) return;
    setLaeuft(true); setMeldung('');
    const { data, error } = await supabase.rpc('einladung_einloesen', { code: code.trim(), konten_mitnehmen: mitnehmen });
    setLaeuft(false);
    if (error) { setMeldung('Nicht eingelöst: ' + error.message); return; }
    const d: any = data || {};
    setMeldung(`Beigetreten als ${d.rolle}. ${d.konten_mitgenommen || 0} Spielkonto/-konten mitgenommen. ` +
      'Wichtig: in der App das Dashboard einmal neu öffnen, in Odin PC „Abmelden“ und neu anmelden.');
    try { window.history.replaceState(null, '', '/team'); } catch { }
    window.setTimeout(onFertig, 2500);
  };
  return <section className="card" style={{ marginTop: 16 }}><h2>Einladungscode einlösen</h2>
    <p className="muted">Mit einem Code aus einem anderen Team verknüpfst du dein Odin-Konto mit diesem Team.</p>
    <form onSubmit={los}><label className="field">Code<input value={code} onChange={e => setCode(e.target.value.toUpperCase())} placeholder="z. B. 19252AC677" required /></label>
      <label className="field" style={{ display: 'flex', gap: 8, alignItems: 'center' }}><input type="checkbox" checked={mitnehmen} onChange={e => setMitnehmen(e.target.checked)} style={{ width: 'auto' }} />Meine Spielkonten mitnehmen</label>
      <div className="modalActions"><button className="button" disabled={laeuft}>{laeuft ? 'Wird eingelöst…' : 'Einlösen'}</button></div></form>
    {meldung && <div className="permissionNote" style={{ marginTop: 12 }}>{meldung}</div>}
  </section>;
}

const roleInfo: Record<Role, string> = {
  Owner: 'Vollzugriff auf Team, Rollen und alle Accounts.',
  Admin: 'Teamverwaltung und Vollzugriff auf alle Accounts.',
  Player: 'Vollzugriff auf alle Team-Accounts.',
  Observer: 'Zugriff auf alle Team-Accounts zur Ansicht.'
};

export default function Team() {
  const [members, setMembers] = useState<Member[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selected, setSelected] = useState(0);
  const [myRole, setMyRole] = useState<Role | ''>('');
  const [open, setOpen] = useState(false);
  const [notice, setNotice] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [inviteRole, setInviteRole] = useState<Role>('Player');
  const [inviteStunden, setInviteStunden] = useState(48);
  const [neuerCode, setNeuerCode] = useState<Einladung | null>(null);
  const [einladungen, setEinladungen] = useState<Einladung[]>([]);

  const flash = (message: string) => { setNotice(message); window.setTimeout(() => setNotice(''), 2500); };

  useEffect(() => { load(); }, []);

  const load = async () => {
    if (!supabase) { setLoading(false); return; }
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { setLoading(false); return; }
    const { data: membership } = await supabase.from('team_members').select('team_id, role').eq('user_id', user.id).limit(1).maybeSingle();
    if (!membership) { setLoading(false); return; }
    setMyRole(membership.role as Role);
    const [{ data: memberRows, error: memberError }, { data: accountRows }] = await Promise.all([
      supabase.rpc('get_team_members', { target_team: membership.team_id }),
      supabase.from('game_accounts').select('id, name, world').eq('team_id', membership.team_id).order('created_at', { ascending: false })
    ]);
    if (memberError) { flash(`Teammitglieder konnten nicht geladen werden: ${memberError.message}`); setLoading(false); return; }
    const allAccounts = (accountRows ?? []) as Account[];
    const loaded: Member[] = (memberRows ?? []).map((m: any) => ({
      id: m.id,
      user_id: m.user_id,
      name: m.display_name || m.email?.split('@')[0] || 'Mitglied',
      contact: m.email || '—',
      role: m.role as Role,
      status: 'Aktiv',
      accounts: allAccounts.map(a => a.name)
    }));
    setMembers(loaded); setAccounts(allAccounts); setSelected(0); setLoading(false);
    if (membership.role === 'Owner' || membership.role === 'Admin') ladeEinladungen(membership.team_id);
  };

  const ladeEinladungen = async (teamId: string) => {
    if (!supabase) return;
    const { data } = await supabase.from('team_einladungen').select('id, code, rolle, gueltig_bis, erstellt_at')
      .eq('team_id', teamId).is('eingeloest_at', null).is('zurueckgezogen_at', null)
      .or('gueltig_bis.is.null,gueltig_bis.gt.' + new Date().toISOString()).order('erstellt_at', { ascending: false });
    setEinladungen((data ?? []) as Einladung[]);
  };

  const zurueckziehen = async (id: string) => {
    if (!supabase) return;
    const { error } = await supabase.rpc('einladung_zurueckziehen', { einladung: id });
    if (error) { flash(`Nicht zurückgezogen: ${error.message}`); return; }
    setEinladungen(all => all.filter(x => x.id !== id)); flash('Einladung zurückgezogen');
  };

  const canManage = myRole === 'Owner' || myRole === 'Admin';
  const member = members[selected];

  const changeRole = async (value: Role) => {
    if (!member || !canManage || member.role === 'Owner' || value === 'Owner' || !supabase) return;
    setSaving(true);
    const { error } = await supabase.rpc('set_team_member_role', { target_member: member.id, new_role: value });
    setSaving(false);
    if (error) { flash(`Rolle konnte nicht geändert werden: ${error.message}`); return; }
    setMembers(all => all.map(m => m.id === member.id ? { ...m, role: value } : m)); flash('Rolle gespeichert');
  };

  const invite = async (e: React.FormEvent) => {
    e.preventDefault(); if (!supabase) return;
    setSaving(true);
    const { data, error } = await supabase.rpc('einladung_erstellen', { rolle: inviteRole, gueltig_stunden: inviteStunden });
    setSaving(false);
    if (error) { flash(`Einladung nicht erstellt: ${error.message}`); return; }
    const row = (Array.isArray(data) ? data[0] : data) as any;
    if (!row) { flash('Einladung nicht erstellt'); return; }
    const neu: Einladung = { id: row.id, code: row.code, rolle: inviteRole, gueltig_bis: row.gueltig_bis ?? null, erstellt_at: new Date().toISOString() };
    setNeuerCode(neu); setEinladungen(all => [neu, ...all]);
  };
  const kopieren = async (text: string) => { try { await navigator.clipboard.writeText(text); flash('Kopiert'); } catch { flash('Kopieren nicht möglich'); } };

  if (loading) return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><div className="card"><p className="muted">Teammitglieder werden geladen…</p></div></main>;
  if (!member) return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><div className="card"><strong>Kein Team gefunden</strong><p className="muted">Melde dich an oder prüfe die Teamzuordnung.</p></div><Einloesen onFertig={load} /></main>;

  return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><p className="muted">Alle Teammitglieder haben Zugriff auf alle Team-Accounts.</p>{notice && <div className="toast">✓ {notice}</div>}
    <div className="teamLayout"><section className="card"><div className="sectionhead"><div><h2>Mitglieder ({members.length})</h2><div className="muted">Deine Rolle: {myRole}</div></div>{canManage && <button className="button" onClick={() => setOpen(true)}>+ Einladen</button>}</div><div className="memberList">{members.map((m,i)=><button key={m.id} className={'memberItem '+(i===selected?'selected':'')} onClick={() => setSelected(i)}><span><strong>{m.name}</strong><small>{m.contact}</small></span><span className="pill">{m.role}</span></button>)}</div></section>
      <section className="card"><div className="sectionhead"><div><h2>{member.name}</h2><div className="muted">{member.contact}</div></div><span className="pill">{member.status}</span></div>
        <label className="field">Rolle<select value={member.role} disabled={!canManage || member.role === 'Owner' || saving} onChange={e => changeRole(e.target.value as Role)}><option value="Owner">Owner</option><option value="Admin">Admin</option><option value="Player">Player</option><option value="Observer">Observer</option></select></label>
        <div className="permissionNote" style={{marginBottom:16}}>{roleInfo[member.role]}</div><h3>Account-Zugriff</h3><div className="permissionNote">Dieses Mitglied hat Zugriff auf alle {accounts.length} Team-Accounts. Individuelle Account-Freigaben sind deaktiviert.</div>{accounts.length > 0 && <div className="checkList" style={{marginTop:12}}>{accounts.map(a => <label key={a.id}><span>{a.name}<small style={{display:'block'}}>{a.world}</small></span><span className="pill">Freigegeben</span></label>)}</div>}
      </section></div>
    {canManage && <section className="card" style={{marginTop:16}}><div className="sectionhead"><div><h2>Offene Einladungen ({einladungen.length})</h2><div className="muted">Wer einen Code einlöst, wird Mitglied dieses Teams.</div></div></div>
      {einladungen.length === 0 ? <p className="muted">Keine offenen Einladungen.</p> : <div className="checkList">{einladungen.map(x => <label key={x.id}><span><strong style={{fontFamily:'monospace',letterSpacing:1}}>{x.code}</strong><small style={{display:'block'}}>{x.rolle} · {gueltigText(x.gueltig_bis)}</small></span><span style={{display:'flex',gap:6}}><button type="button" className="button secondary" onClick={() => kopieren(einladungsLink(x.code))}>Link</button><button type="button" className="button secondary" onClick={() => zurueckziehen(x.id)}>Zurückziehen</button></span></label>)}</div>}
    </section>}
    <Einloesen onFertig={load} />
    {open && <div className="modalBackdrop" onMouseDown={() => setOpen(false)}><div className="modal" role="dialog" aria-modal="true" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2>Mitglied einladen</h2></div><button className="iconButton" onClick={()=>{setOpen(false);setNeuerCode(null);}}>×</button></div>
      {neuerCode ? <div><p className="muted">Code an das andere Odin-Konto geben. Dort unter Team → „Einladungscode einlösen“ eingeben oder den Link öffnen.</p>
        <div style={{fontFamily:'monospace',fontSize:28,letterSpacing:3,textAlign:'center',padding:'12px 0'}}>{neuerCode.code}</div>
        <div className="muted" style={{textAlign:'center'}}>{neuerCode.rolle} · {gueltigText(neuerCode.gueltig_bis)}</div>
        <div className="modalActions"><button type="button" className="button secondary" onClick={()=>kopieren(neuerCode.code)}>Code kopieren</button><button type="button" className="button" onClick={()=>kopieren(einladungsLink(neuerCode.code))}>Link kopieren</button></div></div>
      : <form onSubmit={invite}><label className="field">Rolle<select value={inviteRole} onChange={e=>setInviteRole(e.target.value as Role)}><option>Player</option><option>Admin</option><option>Observer</option></select></label><label className="field">Gültig für<select value={inviteStunden} onChange={e=>setInviteStunden(parseInt(e.target.value,10))}><option value={24}>24 Stunden</option><option value={48}>48 Stunden</option><option value={168}>7 Tage</option><option value={0}>Nie (bis zum Einlösen oder Zurückziehen)</option></select></label><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setOpen(false)}>Abbrechen</button><button className="button" disabled={saving}>Code erzeugen</button></div></form>}</div></div>}</main>;
}
