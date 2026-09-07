const accounts = [
  { name: 'SpielerA', world: 'Welt 201', status: 'Online', device: 'PC', attacks: 2, network: 'Profil A' },
  { name: 'SpielerB', world: 'Welt 205', status: 'Online', device: 'Laptop', attacks: 0, network: 'Profil B' },
  { name: 'SpielerC', world: 'Welt 201', status: 'Offline', device: '—', attacks: 4, network: 'Direkt' }
];

const nav = [
  ['Dashboard', '/'], ['Accounts', '/accounts'], ['Team', '/team'], ['Geräte', '/devices'],
  ['Angriffe', '/attacks'], ['Botschutz', '/bot-protection'], ['Scripts', '/scripts'],
  ['Einstellungen', '/settings'], ['Netzwerk', '/network']
];

export default function Home() {
  return <div className="shell"><aside className="sidebar"><div className="brand">⚔ Stämme Central</div><nav className="nav">{nav.map(([x, href], i) => <a className={i === 0 ? 'active' : ''} href={href} key={x}>{x}</a>)}</nav></aside><div style={{ flex: 1 }}><div className="mobileNav"><strong>⚔ Stämme Central</strong><span>☰</span></div><main className="main"><header className="top"><div><div className="eyebrow">Team-Zentrale / Übersicht</div><h1 className="title">Dashboard</h1><div className="muted">Guten Morgen, Team Admin</div></div><div className="user">👤 Team Admin</div></header><section className="grid"><Metric label="Accounts" value="12" note="im Team"/><Metric label="Online" value="8" note="aktuell verbunden"/><Metric label="Angriffe" value="3" note="offen" tone="danger"/><Metric label="Botschutz" value="1" note="Aufmerksamkeit nötig" tone="warning"/></section><section className="section card"><div className="sectionhead"><h2>Aktive Accounts</h2><span className="pill">Live</span></div><table className="table"><thead><tr><th>Account</th><th>Welt</th><th>Status</th><th>Gerät</th><th>Netzwerk</th><th>Angriffe</th></tr></thead><tbody>{accounts.map(a => <tr key={a.name}><td><strong>{a.name}</strong></td><td>{a.world}</td><td><span className={'pill ' + (a.status === 'Online' ? 'online' : '')}>{a.status === 'Online' ? '●' : '○'} {a.status}</span></td><td>{a.device}</td><td>{a.network}</td><td>{a.attacks ? `⚔ ${a.attacks}` : '—'}</td></tr>)}</tbody></table></section><section className="section card"><div className="sectionhead"><h2>Letzte Ereignisse</h2><span className="muted">Heute</span></div><Event icon="⚔️" text="SpielerA — neuer Angriff erkannt" time="vor 2 Min."/><Event icon="🟢" text="SpielerB — Gerät verbunden" time="vor 7 Min."/><Event icon="⚠️" text="SpielerC — Botschutz-Hinweis erkannt" time="vor 13 Min."/><Event icon="👥" text="Max wurde dem Team hinzugefügt" time="vor 31 Min."/></section></main></div></div>;
}
function Metric({ label, value, note, tone }: { label: string; value: string; note: string; tone?: string }) { return <div className="card"><div className="muted">{label}</div><div className={'metric ' + (tone || '')}>{value}</div><div className="muted">{note}</div></div>; }
function Event({ icon, text, time }: { icon: string; text: string; time: string }) { return <div className="event"><span>{icon}</span><div style={{ flex: 1 }}>{text}</div><span className="muted">{time}</span></div>; }
