'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import OdinShell from '../../components/OdinShell';

// 04.10.2026: Freischaltung statt Einladungscode (Migration 028).
// Es gibt EIN Hauptteam. Wer sich bei Odin registriert, wartet auf
// Freischaltung; Owner/Admin schalten ihn hier per Klick frei. Er wird
// Mitglied, seine Spielkonten samt GodBot-Daten wandern ins Team.
// Alle Mitglieder sehen alle Konten des Teams.

type Role = 'Owner' | 'Admin' | 'Player' | 'Observer';
type Member = { id: string; user_id: string; name: string; contact: string; role: Role };
type Account = { id: string; name: string; world: string; besitzer: string | null };
type Offen = { user_id: string; email: string; registriert: string; konten: { id: string; name: string; world: string }[] };

const roleInfo: Record<Role, string> = {
  Owner: 'Vollzugriff auf Team, Rollen, Freischaltungen und alle Accounts.',
  Admin: 'Teamverwaltung, Freischaltungen und Vollzugriff auf alle Accounts.',
  Player: 'Vollzugriff auf alle Team-Accounts.',
  Observer: 'Zugriff auf alle Team-Accounts zur Ansicht.'
};
const datum = (s: string) => new Date(s).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });

export default function Team() {
  const [members, setMembers] = useState<Member[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selected, setSelected] = useState(0);
  const [myRole, setMyRole] = useState<Role | ''>('');
  const [imHaupt, setImHaupt] = useState<boolean | null>(null);
  const [teamName, setTeamName] = useState('');
  const [eigene, setEigene] = useState<Account[]>([]);
  const [offen, setOffen] = useState<Offen[]>([]);
  const [rolleNeu, setRolleNeu] = useState<Record<string, Role>>({});
  const [notice, setNotice] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const flash = (message: string, ms = 3000) => { setNotice(message); window.setTimeout(() => setNotice(''), ms); };

  useEffect(() => { load(); }, []);

  const load = async () => {
    if (!supabase) { setLoading(false); return; }
    setLoading(true);
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) { window.location.href = '/login/'; return; }
    const { data: ms } = await supabase.from('team_members').select('team_id, role, teams(name, haupt)').eq('user_id', user.id);
    const liste = (ms ?? []) as any[];
    const haupt = liste.find(m => m.teams?.haupt);
    const m = haupt ?? liste[0];
    if (!m) { setImHaupt(false); setLoading(false); return; }
    setMyRole(m.role as Role);
    setTeamName(m.teams?.name ?? '');

    if (!haupt) {
      // Noch nicht freigeschaltet: nur die eigenen Konten zeigen.
      const { data: k } = await supabase.from('game_accounts').select('id, name, world, besitzer').eq('team_id', m.team_id).order('world');
      setEigene((k ?? []) as Account[]);
      setImHaupt(false); setLoading(false);
      return;
    }

    setImHaupt(true);
    const [{ data: memberRows, error: memberError }, { data: accountRows }] = await Promise.all([
      supabase.rpc('get_team_members', { target_team: m.team_id }),
      supabase.from('game_accounts').select('id, name, world, besitzer').eq('team_id', m.team_id).order('world').order('name'),
    ]);
    if (memberError) { flash(`Teammitglieder konnten nicht geladen werden: ${memberError.message}`, 8000); setLoading(false); return; }
    setMembers((memberRows ?? []).map((r: any) => ({
      id: r.id, user_id: r.user_id,
      name: r.display_name || r.email?.split('@')[0] || 'Mitglied',
      contact: r.email || '—', role: r.role as Role,
    })));
    setAccounts((accountRows ?? []) as Account[]);
    setSelected(0);
    if (m.role === 'Owner' || m.role === 'Admin') await ladeOffen();
    setLoading(false);
  };

  const ladeOffen = async () => {
    if (!supabase) return;
    const { data, error } = await supabase.rpc('freigabe_liste');
    if (error) { flash(`Freischaltungen nicht ladbar: ${error.message}`, 8000); return; }
    setOffen((data ?? []) as Offen[]);
  };

  const freischalten = async (o: Offen) => {
    if (!supabase) return;
    const rolle = rolleNeu[o.user_id] ?? 'Player';
    if (!window.confirm(`${o.email} als ${rolle} freischalten? ${o.konten.length} Spielkonto/-konten wandern samt GodBot-Daten ins Team.`)) return;
    setSaving(true);
    const { data, error } = await supabase.rpc('nutzer_freischalten', { p_user: o.user_id, p_rolle: rolle });
    setSaving(false);
    if (error) { flash(`Nicht freigeschaltet: ${error.message}`, 8000); return; }
    const d: any = data || {};
    flash(`${o.email} freigeschaltet (${d.konten ?? 0} Konto/Konten übernommen). Dort einmal App neu öffnen bzw. Odin PC ab- und wieder anmelden.`, 9000);
    load();
  };

  const canManage = myRole === 'Owner' || myRole === 'Admin';
  const member = members[selected];
  const nameVon = (uid: string | null) => {
    const x = members.find(mm => mm.user_id === uid);
    return x ? x.name : '—';
  };

  const changeRole = async (value: Role) => {
    if (!member || !canManage || member.role === 'Owner' || value === 'Owner' || !supabase) return;
    setSaving(true);
    const { error } = await supabase.rpc('set_team_member_role', { target_member: member.id, new_role: value });
    setSaving(false);
    if (error) { flash(`Rolle konnte nicht geändert werden: ${error.message}`, 8000); return; }
    setMembers(all => all.map(m => m.id === member.id ? { ...m, role: value } : m)); flash('Rolle gespeichert');
  };

  if (loading) return <OdinShell titel="Team" aktiv="Team"><div className="card"><p className="muted">Team wird geladen…</p></div></OdinShell>;

  if (!imHaupt) return <OdinShell titel="Team" aktiv="Team">
    <section className="card">
      <div className="sectionhead"><div><h2>Wartet auf Freischaltung</h2><div className="muted">{teamName}</div></div><span className="pill">ausstehend</span></div>
      <p className="muted">Dein Odin-Zugang ist noch nicht für das Team freigeschaltet. Der Admin sieht dich und deine Konten
        in seiner Liste und schaltet dich per Klick frei. Danach gehören deine Konten automatisch zum Team.</p>
      <h3>Deine Konten ({eigene.length})</h3>
      {eigene.length === 0 ? <p className="muted">Noch keine Spielkonten hinterlegt.</p> :
        <div className="checkList">{eigene.map(a => <label key={a.id}><span>{a.name}<small style={{ display: 'block' }}>{a.world}</small></span><span className="pill">wartet</span></label>)}</div>}
      <div className="permissionNote" style={{ marginTop: 12 }}>Nach der Freischaltung: App einmal neu öffnen bzw. in Odin PC „Abmelden“ und neu anmelden.</div>
      <div className="modalActions"><button type="button" className="button secondary" onClick={load}>Neu prüfen</button></div>
    </section>
  </OdinShell>;

  return <OdinShell titel="Team" aktiv="Team">
    <p className="muted">{teamName} · alle Mitglieder haben Zugriff auf alle {accounts.length} Team-Accounts.</p>
    {notice && <div className="toast">{notice}</div>}

    {canManage && <section className="card" style={{ marginBottom: 16 }}>
      <div className="sectionhead"><div><h2>Freischaltungen ({offen.length})</h2>
        <div className="muted">Alle in Odin registrierten Nutzer, die noch nicht zum Team gehören.</div></div>
        <button type="button" className="button secondary" onClick={ladeOffen}>Aktualisieren</button></div>
      {offen.length === 0 ? <p className="muted">Niemand wartet auf Freischaltung.</p> :
        <div className="checkList">{offen.map(o => <label key={o.user_id} style={{ alignItems: 'flex-start' }}>
          <span><strong>{o.email}</strong>
            <small style={{ display: 'block' }}>registriert {datum(o.registriert)}</small>
            <small style={{ display: 'block' }}>{o.konten.length ? o.konten.map(k => `${k.name} · ${k.world}`).join(', ') : 'noch keine Spielkonten'}</small>
          </span>
          <span style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'flex-end' }}>
            <select value={rolleNeu[o.user_id] ?? 'Player'} onChange={e => setRolleNeu(r => ({ ...r, [o.user_id]: e.target.value as Role }))} style={{ width: 'auto' }}>
              <option>Player</option><option>Admin</option><option>Observer</option>
            </select>
            <button type="button" className="button" disabled={saving} onClick={() => freischalten(o)}>Freischalten</button>
          </span>
        </label>)}</div>}
    </section>}

    <div className="teamLayout">
      <section className="card"><div className="sectionhead"><div><h2>Mitglieder ({members.length})</h2><div className="muted">Deine Rolle: {myRole}</div></div></div>
        <div className="memberList">{members.map((m, i) => <button key={m.id} className={'memberItem ' + (i === selected ? 'selected' : '')} onClick={() => setSelected(i)}>
          <span><strong>{m.name}</strong><small>{m.contact}</small></span><span className="pill">{m.role}</span></button>)}</div>
      </section>
      {member && <section className="card"><div className="sectionhead"><div><h2>{member.name}</h2><div className="muted">{member.contact}</div></div><span className="pill">Aktiv</span></div>
        <label className="field">Rolle<select value={member.role} disabled={!canManage || member.role === 'Owner' || saving} onChange={e => changeRole(e.target.value as Role)}>
          <option value="Owner">Owner</option><option value="Admin">Admin</option><option value="Player">Player</option><option value="Observer">Observer</option></select></label>
        <div className="permissionNote" style={{ marginBottom: 16 }}>{roleInfo[member.role]}</div>
        <h3>Eingebrachte Konten</h3>
        {accounts.filter(a => a.besitzer === member.user_id).length === 0 ? <p className="muted">Keine.</p> :
          <div className="checkList">{accounts.filter(a => a.besitzer === member.user_id).map(a => <label key={a.id}><span>{a.name}<small style={{ display: 'block' }}>{a.world}</small></span><span className="pill">Team</span></label>)}</div>}
      </section>}
    </div>

    <section className="card" style={{ marginTop: 16 }}>
      <div className="sectionhead"><div><h2>Alle Konten im Team ({accounts.length})</h2><div className="muted">Jedes Mitglied kann jedes Konto nutzen.</div></div></div>
      {accounts.length === 0 ? <p className="muted">Noch keine Konten.</p> :
        <div className="checkList">{accounts.map(a => <label key={a.id}><span>{a.name}<small style={{ display: 'block' }}>{a.world}</small></span><span className="muted" style={{ fontSize: 12 }}>von {nameVon(a.besitzer)}</span></label>)}</div>}
    </section>
  </OdinShell>;
}
