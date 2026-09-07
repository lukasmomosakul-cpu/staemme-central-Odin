'use client';

import { useState } from 'react';

type Member = { name: string; contact: string; role: string; status: string };
const initialMembers: Member[] = [
  { name: 'Team Admin', contact: 'admin@team', role: 'Owner', status: 'Aktiv' },
  { name: 'Max', contact: 'max@team', role: 'Admin', status: 'Aktiv' },
  { name: 'Lena', contact: 'lena@team', role: 'Player', status: 'Aktiv' },
  { name: 'Tom', contact: 'tom@team', role: 'Observer', status: 'Einladung offen' }
];

export default function Team() {
  const [members, setMembers] = useState<Member[]>(initialMembers);
  const [open, setOpen] = useState(false);
  const [notice, setNotice] = useState('');
  const [name, setName] = useState('');
  const [contact, setContact] = useState('');
  const [role, setRole] = useState('Player');

  function invite(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim() || !contact.trim()) return;
    setMembers(m => [...m, { name: name.trim(), contact: contact.trim(), role, status: 'Einladung offen' }]);
    setName(''); setContact(''); setRole('Player'); setOpen(false); setNotice('Einladung wurde vorbereitet');
    window.setTimeout(() => setNotice(''), 2500);
  }

  return <main className="main">
    <div className="eyebrow">Organisation / Team</div><h1 className="title">Team</h1><p className="muted">Mitglieder, Rollen und Zugriffsverwaltung der Teamzentrale Odin.</p>
    {notice && <div className="toast">✓ {notice}</div>}
    <section className="card section"><div className="sectionhead"><h2>Mitglieder ({members.length})</h2><button className="button" onClick={() => setOpen(true)}>+ Mitglied einladen</button></div>
      <div className="table-wrap"><table className="table"><thead><tr><th>Name</th><th>Kontakt</th><th>Rolle</th><th>Status</th></tr></thead><tbody>{members.map((m,i)=><tr key={`${m.contact}-${i}`}><td><strong>{m.name}</strong></td><td>{m.contact}</td><td><select className="inlineSelect" value={m.role} disabled={m.role === 'Owner'} onChange={e => setMembers(all => all.map((x,j)=>j===i?{...x,role:e.target.value}:x))}><option>Owner</option><option>Admin</option><option>Player</option><option>Observer</option></select></td><td>{m.status}</td></tr>)}</tbody></table></div>
    </section>
    <section className="card section"><h2>Rollen & Zugriff</h2><div className="roleGrid"><div><strong>Owner</strong><p className="muted">Vollzugriff, Teamverwaltung und Sicherheit.</p></div><div><strong>Admin</strong><p className="muted">Accounts, Geräte, Scripts und Einstellungen.</p></div><div><strong>Player</strong><p className="muted">Arbeiten mit freigegebenen Accounts.</p></div><div><strong>Observer</strong><p className="muted">Nur Ansicht, keine Änderungen.</p></div></div></section>
    {open && <div className="modalBackdrop" onMouseDown={() => setOpen(false)}><div className="modal" role="dialog" aria-modal="true" onMouseDown={e=>e.stopPropagation()}><div className="modalHead"><div><div className="eyebrow">Teamzentrale Odin</div><h2>Mitglied einladen</h2></div><button className="iconButton" onClick={()=>setOpen(false)}>×</button></div><form onSubmit={invite}><label className="field">Name<input value={name} onChange={e=>setName(e.target.value)} placeholder="z. B. Anna" required /></label><label className="field">E-Mail / Kontakt<input value={contact} onChange={e=>setContact(e.target.value)} placeholder="anna@example.de" required /></label><label className="field">Rolle<select value={role} onChange={e=>setRole(e.target.value)}><option>Player</option><option>Admin</option><option>Observer</option></select></label><div className="modalActions"><button type="button" className="button secondary" onClick={()=>setOpen(false)}>Abbrechen</button><button className="button">Einladung vorbereiten</button></div></form></div></div>}
  </main>;
}
