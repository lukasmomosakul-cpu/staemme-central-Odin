'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

export default function GamePage() {
  const [email, setEmail] = useState<string | null>(null);
  const [world, setWorld] = useState('');
  const [accountName, setAccountName] = useState('');
  const [notice, setNotice] = useState('');

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getSession().then(({ data }) => setEmail(data.session?.user?.email ?? null));
  }, []);

  const save = () => {
    setNotice('Verbindungseinstellungen vorbereitet. Die read-only Spielanbindung kommt im nächsten Integrationsschritt.');
  };

  return (
    <main style={{minHeight:'100vh',padding:'20px',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}>
      <div style={{maxWidth:760,margin:'0 auto'}}>
        <a href="/" className="muted">← Zur Teamzentrale</a>
        <div className="eyebrow" style={{marginTop:28}}>TEAMZENTRALE ODIN</div>
        <h1>Spielanbindung</h1>
        <p className="muted">Read-only Verbindung zu Die Stämme. Zuerst holen wir sichere Spielinformationen in Odin, bevor wir Automatisierung anbinden.</p>

        <section className="card section">
          <div className="sectionhead"><h2>Verbindung</h2><span className="pill">Vorbereitung</span></div>
          <div className="settings" style={{display:'grid',gap:14}}>
            <label>Stämme-Welt<input value={world} onChange={e=>setWorld(e.target.value)} placeholder="z. B. Welt 201" /></label>
            <label>Odin-Account<input value={accountName} onChange={e=>setAccountName(e.target.value)} placeholder="Name des Spielaccounts" /></label>
          </div>
          <button className="button" style={{marginTop:16}} onClick={save}>Verbindung vorbereiten</button>
          {notice && <div className="toast" style={{marginTop:12}}>✓ {notice}</div>}
        </section>

        <section className="card section">
          <div className="sectionhead"><h2>Was Odin aus dem Spiel lesen wird</h2><span className="pill online">Read-only</span></div>
          <div className="list">
            <div className="event"><span>🌍</span><div><strong>Welt & Server</strong><div className="muted">aktuelle Welt, Host und Spielseite</div></div></div>
            <div className="event"><span>👤</span><div><strong>Spielaccount</strong><div className="muted">aktuell eingeloggter Spielaccount und Session-Status</div></div></div>
            <div className="event"><span>🏰</span><div><strong>Dörfer</strong><div className="muted">Dorfname, Koordinaten und relevante Übersichtsdaten</div></div></div>
            <div className="event"><span>⚔️</span><div><strong>Angriffe</strong><div className="muted">eingehende/ausgehende Angriffsereignisse für Benachrichtigungen</div></div></div>
            <div className="event"><span>🛡️</span><div><strong>Botschutz-Signale</strong><div className="muted">nur Status/Erkennung, kein Umgehen oder automatisches Lösen von Schutzmaßnahmen</div></div></div>
          </div>
        </section>

        <section className="card section">
          <div className="sectionhead"><h2>Technik</h2></div>
          <p className="muted">Die erste Integration wird über ein eigenes Tampermonkey-Userscript im Browser des Spielers laufen. Das Script liest die sichtbaren Spielinformationen und überträgt nur die für Odin freigegebenen Daten. Zugangsdaten des Spiels werden nicht in Odin gespeichert.</p>
          <div className="event"><span>🔒</span><div><strong>Keine Spielpasswörter in Odin</strong><div className="muted">Die Verbindung wird später über einen kurzlebigen Integrations-Token pro Spielaccount abgesichert.</div></div></div>
        </section>

        {!email && <p className="muted" style={{marginTop:18}}>Bitte zuerst in der Teamzentrale anmelden.</p>}
      </div>
    </main>
  );
}
