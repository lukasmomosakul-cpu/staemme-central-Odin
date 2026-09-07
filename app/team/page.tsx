'use client';

import { useState } from 'react';

type Role = 'Owner' | 'Admin' | 'Player' | 'Observer';
type Member = { name: string; contact: string; role: Role; status: string; accounts: string[] };
const initialMembers: Member[] = [
  { name: 'Team Admin', contact: 'admin@team', role: 'Owner', status: 'Aktiv', accounts: ['Alle Accounts'] },
  { name: 'Max', contact: 'max@team', role: 'Admin', status: 'Aktiv', accounts: ['Alle Accounts'] },
  { name: 'Lena', contact: 'lena@team', role: 'Player', status: 'Aktiv', accounts: ['SpielerA', 'SpielerC'] },
  { name: 'Tom', contact: 'tom@team', role: 'Observer', status: 'Einladung offen', accounts: [] }
];
const allAccounts = ['SpielerA', 'SpielerB', 'SpielerC'];

export default function Team() {
  const [members, setMembers] = useState<Member[]>(initialMembers);
  const [selected, setSelected] = useState(0);
  const [open, setOpen] = useState(false);
  const [notice, setNotice] = useState('');
  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [role, setRole] = useState<Role>('Player');
  const member = members[selected];
  const invite = (e: React.FormEvent) => { e.preventDefault(); if (!name.trim() || !contact.trim()) return; setMembers(m => [...m, { name: name.trim(), contact: contact.trim(), role, status: 'Einladung offen', accounts: [] }]); setName(''); setContact(''); setRole('Player'); setOpen(false); flash('Einladung wurde vorbereitet'); };
  const flash = (message: string) => { setNotice(message); window.setTimeout(() => setNotice(''), 2500); };
  const toggle = (account: string) => setMembers(all => all.map((m,i) => i === selected ? { ...m, accounts: m.accounts.includes(account) ? m.accounts.filter(a => a !== account) : [...m.accounts, account] } : m));
  const changeRole = (value: Role) => { if (member.role === 'Owner') return; setMembers(all => all.map((m,i) => i === selected ? { ...m, role: value } : m)); };
  return <main className="main"><div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><p className="muted">Mitglieder, Rollen und individuelle Account-Berechtigungen.</p>{notice && <div className="toast">✓ {notice}</div>}
    <div className="teamLayout"><section className="card"><div className="sectionhead"><h2>Mitglieder ({members.length})</h2><button className="button" onClick={() => setOpen(true)}>+ Einladen</button></div><div className="memberList">{members.map((m,i)=><button key={`${m.contact}-${i}`} className={'memberItem '+(i===selected?'selected':'')} onClick={() => setSelected(i)}><span><strong>{m.name}</strong><small>{m.contact}</small></span><span className="pill">{m.role}</span></button>)}</div></section>
    <section className="card"><div className="sectionhead"><div><h2>{member.name}</h2><div className="muted">Berechtigungen</div></div><span className="pill">{member.status}</span></div><label className="field">Rolle<select value={member.role} disabled={member.role === 'Owner'} onChange={e => changeRole(e.target.value as Role)}><option>Owner</option><option>Admin</option><option>Player</option><option>Observer</option></select></label><h3>Account-Zugriff</h3>{member.role === 'Owner' || member.role === 'Admin' ? <div className="permissionNote">Vollzugriff auf alle Team-Accounts.</div> : member.role === 'Observer' ? <div className="permissionNote">Nur Ansicht. Keine Account-Aktionen.</div> : <div className="checkList">{allAccounts.map(a => <label key={a}><span>{a}</span><input type="checkbox" checked={member.accounts.includes(a)} onChange={() => toggle(a)} /></label>)}</div>}<button className="button" style={{marginTop:18}} onClick={() => flash('Berechtigungen gespeichert')}>Änderungen speichern</button></section></div>
    {open && <div className="modalBackdrop" onMouseDown={() => setOpen(false)}><div className="modal" role="dialog" aria-modal="true" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2>Mitglied einladen</h2></div><button className="iconButton" onClick={()=>setOpen(false)}>×</button></div><form onSubmit={invite}><label className="field">Name<input value={name} onChange={e=>setName(e.target.value)} placeholder="z. B. Anna" required /></label><label className="field">E-Mail / Kontakt<input value={contact} onChange={e=>setContact(e.target.value)} placeholder="anna@example.de" required /></label><label className="field">Rolle<select value={role} onChange={e=>setRole(e.target.value as Role)}><option>Player</option><option>Admin</option><option>Observer</option></select></label><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setOpen(false)}>Abbrechen</button><button className="button">Einladung vorbereiten</button></div></form></div></div>}</main>;
}
