const accounts = [
  { name: "SpielerA", world: "Welt 201", status: "Online", device: "PC", attacks: 2 },
  { name: "SpielerB", world: "Welt 205", status: "Online", device: "Laptop", attacks: 0 },
  { name: "SpielerC", world: "Welt 201", status: "Offline", device: "—", attacks: 4 },
];

export default function Dashboard() {
  return (
    <main style={{ fontFamily: "system-ui", padding: 24, maxWidth: 1200, margin: "auto" }}>
      <header style={{ display: "flex", justifyContent: "space-between", alignItems: "center", gap: 16, flexWrap: "wrap" }}>
        <div><h1>⚔️ Stämme Central</h1><p>Team-Zentrale · Odin</p></div>
        <div>🔔 3 &nbsp; 👤 Team Admin</div>
      </header>
      <section style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit,minmax(150px,1fr))", gap: 12, marginTop: 24 }}>
        <Card title="Accounts" value="12" /><Card title="Online" value="8" /><Card title="Angriffe" value="3" /><Card title="Botschutz" value="1" />
      </section>
      <section style={{ marginTop: 32, overflowX: "auto" }}>
        <h2>Aktive Accounts</h2>
        <table style={{ width: "100%", minWidth: 650, borderCollapse: "collapse" }}>
          <thead><tr><th align="left">Account</th><th align="left">Welt</th><th align="left">Status</th><th align="left">Gerät</th><th align="left">Angriffe</th></tr></thead>
          <tbody>{accounts.map(a => <tr key={a.name} style={{ borderTop: "1px solid #ddd" }}><td>{a.name}</td><td>{a.world}</td><td>{a.status === "Online" ? "🟢" : "🔴"} {a.status}</td><td>{a.device}</td><td>{a.attacks}</td></tr>)}</tbody>
        </table>
      </section>
      <section style={{ marginTop: 32 }}><h2>Letzte Ereignisse</h2><ul><li>⚔️ SpielerA — neuer Angriff erkannt</li><li>🟢 SpielerB — Gerät verbunden</li><li>⚠️ SpielerC — Botschutz-Hinweis erkannt</li></ul></section>
      <section style={{ marginTop: 32 }}><h2>Netzwerk</h2><p>Network Profiles sind für die spätere, regelkonforme Egress-Anbindung vorbereitet.</p></section>
    </main>
  );
}
function Card({ title, value }: { title: string; value: string }) { return <div style={{ border: "1px solid #ddd", borderRadius: 12, padding: 18 }}><div>{title}</div><strong style={{ fontSize: 30 }}>{value}</strong></div>; }
