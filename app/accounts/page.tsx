'use client'

import { useState } from 'react'

type Permission = 'Keine' | 'Ansehen' | 'Nutzen' | 'Verwalten'

type Account = {
  name: string
  world: string
  status: string
  device: string
  network: string
  attacks: string
}

const members = [
  ['Team Admin', 'Owner'],
  ['Max', 'Admin'],
  ['Lena', 'Player'],
  ['Tom', 'Observer'],
]

const initialAccounts: Account[] = [
  { name: 'SpielerA', world: 'Welt 201', status: 'Online', device: 'PC', network: 'Profil A', attacks: '2' },
  { name: 'SpielerB', world: 'Welt 205', status: 'Online', device: 'Laptop', network: 'Profil B', attacks: '0' },
  { name: 'SpielerC', world: 'Welt 201', status: 'Offline', device: '—', network: 'Direkt', attacks: '4' },
]

const initialPermissions: Record<string, Record<string, Permission>> = {
  SpielerA: { 'Team Admin': 'Verwalten', Max: 'Nutzen', Lena: 'Keine', Tom: 'Ansehen' },
  SpielerB: { 'Team Admin': 'Verwalten', Max: 'Keine', Lena: 'Nutzen', Tom: 'Ansehen' },
  SpielerC: { 'Team Admin': 'Verwalten', Max: 'Nutzen', Lena: 'Keine', Tom: 'Ansehen' },
}

const permissionOptions: Permission[] = ['Keine', 'Ansehen', 'Nutzen', 'Verwalten']

export default function Accounts() {
  const [accounts, setAccounts] = useState(initialAccounts)
  const [permissions, setPermissions] = useState(initialPermissions)
  const [selected, setSelected] = useState<Account | null>(null)
  const [showAdd, setShowAdd] = useState(false)
  const [newName, setNewName] = useState('')
  const [newWorld, setNewWorld] = useState('')

  function updatePermission(account: string, member: string, value: Permission) {
    setPermissions(current => ({
      ...current,
      [account]: { ...current[account], [member]: value },
    }))
  }

  function addAccount(event: React.FormEvent) {
    event.preventDefault()
    if (!newName.trim() || !newWorld.trim()) return
    const account: Account = {
      name: newName.trim(),
      world: newWorld.trim(),
      status: 'Offline',
      device: '—',
      network: 'Direkt',
      attacks: '0',
    }
    setAccounts(current => [...current, account])
    setPermissions(current => ({
      ...current,
      [account.name]: { 'Team Admin': 'Verwalten', Max: 'Keine', Lena: 'Keine', Tom: 'Ansehen' },
    }))
    setNewName('')
    setNewWorld('')
    setShowAdd(false)
  }

  return (
    <main className="main">
      <div className="eyebrow">Team-Zentrale</div>
      <h1 className="title">Accounts</h1>
      <p className="muted">Alle dem Team zugeordneten Spielaccounts – inklusive individueller Zugriffsrechte.</p>

      <section className="card section">
        <div className="sectionhead">
          <div>
            <h2>Spielaccounts</h2>
            <p className="muted">Tippe auf „Berechtigungen“, um festzulegen, wer welchen Account nutzen darf.</p>
          </div>
          <button className="button" onClick={() => setShowAdd(true)}>+ Account hinzufügen</button>
        </div>

        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>Account</th><th>Welt</th><th>Status</th><th>Gerät</th><th>Netzwerk</th><th>Angriffe</th><th>Zugriff</th></tr></thead>
            <tbody>
              {accounts.map(account => (
                <tr key={account.name}>
                  <td><strong>{account.name}</strong></td>
                  <td>{account.world}</td>
                  <td><span className={'pill ' + (account.status === 'Online' ? 'online' : '')}>{account.status}</span></td>
                  <td>{account.device}</td>
                  <td>{account.network}</td>
                  <td>{account.attacks}</td>
                  <td><button className="secondary" onClick={() => setSelected(account)}>Berechtigungen</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="card section">
        <div className="sectionhead">
          <div><h2>Schnellübersicht</h2><p className="muted">Aktuelle Zugriffsverteilung im Team.</p></div>
        </div>
        <div className="permissionSummary">
          {members.map(([name, role]) => {
            const usable = accounts.filter(a => ['Nutzen', 'Verwalten'].includes(permissions[a.name]?.[name] ?? 'Keine')).length
            return <div className="summaryItem" key={name}><strong>{name}</strong><span>{role}</span><b>{usable} Account{usable === 1 ? '' : 's'}</b></div>
          })}
        </div>
      </section>

      {selected && (
        <div className="modalBackdrop" onMouseDown={event => { if (event.target === event.currentTarget) setSelected(null) }}>
          <div className="modal" role="dialog" aria-modal="true" aria-labelledby="permission-title">
            <div className="modalHead">
              <div><div className="eyebrow">Zugriffsrechte</div><h2 id="permission-title">{selected.name}</h2><p className="muted">{selected.world} · Rechte werden aktuell nur lokal im Demo-Stand gespeichert.</p></div>
              <button className="iconButton" onClick={() => setSelected(null)} aria-label="Schließen">×</button>
            </div>
            <div className="permissionList">
              {members.map(([name, role]) => (
                <div className="permissionRow" key={name}>
                  <div><strong>{name}</strong><span>{role}</span></div>
                  <select className="inlineSelect" value={permissions[selected.name]?.[name] ?? 'Keine'} onChange={event => updatePermission(selected.name, name, event.target.value as Permission)} disabled={role === 'Owner'}>
                    {permissionOptions.map(option => <option key={option}>{option}</option>)}
                  </select>
                </div>
              ))}
            </div>
            <div className="roleHint"><strong>Rechte:</strong> Ansehen = nur Status/Infos · Nutzen = Account verwenden · Verwalten = Zugriff und Account-Einstellungen verwalten.</div>
            <div className="modalActions"><button className="button" onClick={() => setSelected(null)}>Speichern</button></div>
          </div>
        </div>
      )}

      {showAdd && (
        <div className="modalBackdrop" onMouseDown={event => { if (event.target === event.currentTarget) setShowAdd(false) }}>
          <form className="modal" onSubmit={addAccount}>
            <div className="modalHead"><div><div className="eyebrow">Neuer Account</div><h2>Account hinzufügen</h2></div><button type="button" className="iconButton" onClick={() => setShowAdd(false)} aria-label="Schließen">×</button></div>
            <label className="field"><span>Accountname</span><input value={newName} onChange={e => setNewName(e.target.value)} placeholder="z. B. SpielerD" autoFocus /></label>
            <label className="field"><span>Welt</span><input value={newWorld} onChange={e => setNewWorld(e.target.value)} placeholder="z. B. Welt 210" /></label>
            <div className="modalActions"><button type="button" className="secondary" onClick={() => setShowAdd(false)}>Abbrechen</button><button className="button" type="submit">Account anlegen</button></div>
          </form>
        </div>
      )}
    </main>
  )
}
