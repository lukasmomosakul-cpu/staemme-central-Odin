'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

type Role = 'Owner' | 'Admin' | 'Player' | 'Observer';
type Member = { id: string; user_id: string; name: string; contact: string; role: Role; status: string; accounts: string[] };
type Account = { id: string; name: string; world: string };

const roleInfo: Record<Role, string> = {
  Owner: 'Vollzugriff auf Team, Rollen und alle Accounts.',
  Admin: 'Teamverwaltung und Vollzugriff auf alle Accounts.',
  Player: 'Nur freigegebene Accounts verwalten.',
  Observer: 'Nur Ansicht, keine Account-Aktionen.'
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
  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [inviteRole, setInviteRole] = useState<Role>('Player');

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
    const loaded: Member[] = (memberRows ?? []).map((m: any) => ({ id: m.id, user_id: m.user_id, name: m.display_name || m.email?.split('@')[0] || 'Mitglied', contact: m.email || '—', role: m.role as Role, status: 'Aktiv', accounts: [] }));
    const permissions = loaded.length ? ((await supabase.from('member_account_permissions').select('member_id, account_id').in('member_id', loaded.map(m => m.id))).data ?? []) : [];
    const accountMap = new Map((accountRows ?? []).map((a: any) => [a.id, a.name]));
    for (const p of permissions) {
      const m = loaded.find(x => x.id === p.member_id); const account = accountMap.get(p.account_id);
      if (m && account) m.accounts.push(account);
    }
    setMembers(loaded); setAccounts((accountRows ?? []) as Account[]); setSelected(0); setLoading(false);
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

  const toggleAccount = async (account: Account) => {
    if (!member || member.role !== 'Player' || !canManage || !supabase) return;
    const has = member.accounts.includes(account.name); setSaving(true);
    const result = has ? await supabase.from('member_account_permissions').delete().eq('member_id', member.id).eq('account_id', account.id) : await supabase.from('member_account_permissions').insert({ member_id: member.id, account_id: account.id });
    setSaving(false);
    if (result.error) { flash(`Berechtigung konnte nicht gespeichert werden: ${result.error.message}`); return; }
    setMembers(all => all.map(m => m.id === member.id ? { ...m, accounts: has ? m.accounts.filter(a => a !== account.name) : [...m.accounts, account.name] } : m));
  };

  const invite = (e: React.FormEvent) => { e.preventDefault(); if (!name.trim() || !contact.trim()) return; setOpen(false); flash('Einladung ist vorbereitet – der sichere Invite-Flow folgt als nächster Schritt.'); setName(''); setContact(''); setInviteRole('Player'); };

  if (loading) return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><div className="card"><p className="muted">Teammitglieder werden geladen…</p></div></main>;
  if (!member) return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><div className="card"><strong>Kein Team gefunden</strong><p className="muted">Melde dich an oder prüfe die Teamzuordnung.</p></div></main>;

  return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><p className="muted">Echte Teammitglieder, Rollen und individuelle Account-Berechtigungen.</p>{notice && <div className="toast">✓ {notice}</div>}
    <div className="teamLayout"><section className="card"><div className="sectionhead"><div><h2>Mitglieder ({members.length})</h2><div className="muted">Deine Rolle: {myRole}</div></div>{canManage && <button className="button" onClick={() => setOpen(true)}>+ Einladen</button>}</div><div className="memberList">{members.map((m,i)=><button key={m.id} className={'memberItem '+(i===selected?'selected':'')} onClick={() => setSelected(i)}><span><strong>{m.name}</strong><small>{m.contact}</small></span><span className="pill">{m.role}</span></button>)}</div></section>
      <section className="card"><div className="sectionhead"><div><h2>{member.name}</h2><div className="muted">{member.contact}</div></div><span className="pill">{member.status}</span></div>
        <label className="field">Rolle<select value={member.role} disabled={!canManage || member.role === 'Owner' || saving} onChange={e => changeRole(e.target.value as Role)}><option value="Owner">Owner</option><option value="Admin">Admin</option><option value="Player">Player</option><option value="Observer">Observer</option></select></label>
        <div className="permissionNote" style={{marginBottom:16}}>{roleInfo[member.role]}</div><h3>Account-Zugriff</h3>{member.role === 'Owner' || member.role === 'Admin' ? <div className="permissionNote">Vollzugriff auf alle {accounts.length} Team-Accounts.</div> : member.role === 'Observer' ? <div className="permissionNote">Nur Ansicht. Keine Account-Aktionen.</div> : accounts.length === 0 ? <div className="permissionNote">Noch keine Team-Accounts vorhanden.</div> : <div className="checkList">{accounts.map(a => <label key={a.id}><span>{a.name}<small style={{display:'block'}}>{a.world}</small></span><input type="checkbox" disabled={!canManage || saving} checked={member.accounts.includes(a.name)} onChange={() => toggleAccount(a)} /></label>)}</div>}
      </section></div>
    {open && <div className="modalBackdrop" onMouseDown={() => setOpen(false)}><div className="modal" role="dialog" aria-modal="true" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2>Mitglied einladen</h2></div><button className="iconButton" onClick={()=>setOpen(false)}>×</button></div><form onSubmit={invite}><label className="field">Name<input value={name} onChange={e=>setName(e.target.value)} placeholder="z. B. Anna" required /></label><label className="field">E-Mail<input type="email" value={contact} onChange={e=>setContact(e.target.value)} placeholder="anna@example.de" required /></label><label className="field">Rolle<select value={inviteRole} onChange={e=>setInviteRole(e.target.value as Role)}><option>Player</option><option>Admin</option><option>Observer</option></select></label><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setOpen(false)}>Abbrechen</button><button className="button">Einladung vorbereiten</button></div></form></div></div>}</main>;
}
