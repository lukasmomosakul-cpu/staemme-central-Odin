'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

type Account = { id: string; name: string; world: string };
type Settings = Record<string, string>;

// Zeitstempel in den Plaenen sind Millisekunden (atMs).
const uhr = (ms: number) =>
  new Date(ms).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit' });

const rest = (ms: number) => {
  const s = Math.max(0, Math.floor((ms - Date.now()) / 1000));
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h > 0 ? `${h} h ${m} min` : `${m} min ${s % 60} s`;
};

function lies<T>(settings: Settings, key: string, fallback: T): T {
  try {
    const raw = settings[key];
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

export default function GodBotPage() {
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [aktiv, setAktiv] = useState<string>('');
  const [settings, setSettings] = useState<Settings>({});
  const [laedt, setLaedt] = useState(true);
  const [stand, setStand] = useState<string>('');
  const [tick, setTick] = useState(0);

  // Restzeiten sekündlich neu berechnen, ohne erneut zu laden.
  useEffect(() => {
    const t = setInterval(() => setTick((x) => x + 1), 1000);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    (async () => {
      if (!supabase) { setLaedt(false); return; }
      const { data: user } = await supabase.auth.getUser();
      if (!user.user) { window.location.href = '/login/'; return; }
      const { data: rows } = await supabase
        .from('game_accounts').select('id,name,world').order('name');
      const list = (rows ?? []) as Account[];
      setAccounts(list);
      if (list.length) setAktiv(list[0].id);
      setLaedt(false);
    })();
  }, []);

  useEffect(() => {
    if (!aktiv || !supabase) return;
    setLaedt(true);
    (async () => {
      const { data } = await supabase!
        .from('godbot_settings').select('skey,value,updated_at').eq('account_id', aktiv);
      const map: Settings = {};
      let neuste = 0;
      for (const r of (data ?? []) as { skey: string; value: string; updated_at: string }[]) {
        map[r.skey] = r.value;
        const t = new Date(r.updated_at).getTime();
        if (t > neuste) neuste = t;
      }
      setSettings(map);
      setStand(neuste ? uhr(neuste) : '');
      setLaedt(false);
    })();
  }, [aktiv]);

  // --- Auswertungen ---------------------------------------------------------
  type Termin = { at: number; coord: string; unit: string; label: string };
  const plan = lies<{ attacks?: { coord?: string; attacks?: { atMs?: number; slowestUnit?: string; label?: string }[] }[] }>(settings, 'tw_tabben_plan', {});
  const termine: Termin[] = [];
  for (const d of plan.attacks ?? []) {
    for (const a of d.attacks ?? []) {
      if (a.atMs) termine.push({ at: a.atMs, coord: d.coord ?? '', unit: a.slowestUnit ?? '', label: a.label ?? '' });
    }
  }
  termine.sort((x, y) => x.at - y.at);
  const offen = termine.filter((t) => t.at > Date.now());

  const doerfer = lies<{ at?: number; villages?: Record<string, { coord?: string; name?: string }> }>(settings, 'tw_tabben_villages', {});
  const dorfListe = Object.entries(doerfer.villages ?? {});

  const prod = lies<{ wood?: number; stone?: number; iron?: number; sum?: number; villageCount?: number }>(settings, 'tw_production_cache', {});
  const aktivitaet = lies<{ at?: number; art?: string; text?: string }[]>(settings, 'tw_aktivitaet', []);
  const instanzen = lies<Record<string, { takte?: number; anfragen?: number; seit?: number }>>(settings, 'tw_instance_registry', {});
  const anfragenGesamt = Object.values(instanzen).reduce((n, i) => n + (i.anfragen ?? 0), 0);

  const zahl = (n?: number) => (n ?? 0).toLocaleString('de-DE');

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">⚔ Teamzentrale Odin</div>
        <nav className="nav">
          <a href="/">Dashboard</a>
          <a className="active" href="/godbot/">GodBot</a>
          <a href="/team/">Team</a>
          <a href="/scripts/">Scripts</a>
        </nav>
      </aside>

      <main className="main">
        <header className="topbar">
          <h1>GodBot</h1>
          {accounts.length > 1 && (
            <select value={aktiv} onChange={(e) => setAktiv(e.target.value)} aria-label="Account">
              {accounts.map((a) => <option key={a.id} value={a.id}>{a.name} · {a.world}</option>)}
            </select>
          )}
        </header>

        {laedt && <p className="permissionNote">Lade Daten…</p>}

        {!laedt && !Object.keys(settings).length && (
          <p className="permissionNote">
            Für diesen Account sind noch keine Daten abgeglichen. Öffne das Spiel einmal
            über den Spiel-Knopf, damit GodBot seine Einstellungen hochlädt.
          </p>
        )}

        {!laedt && !!Object.keys(settings).length && (
          <>
            <p className="permissionNote">Stand: {stand || 'unbekannt'} · {Object.keys(settings).length} Schlüssel abgeglichen</p>

            <section>
              <h2>Kennzahlen</h2>
              <div className="cards">
                <div className="card"><span>Dörfer</span><strong>{dorfListe.length || zahl(prod.villageCount)}</strong></div>
                <div className="card"><span>Offene Termine</span><strong>{offen.length}</strong></div>
                <div className="card"><span>Produktion/h</span><strong>{zahl(prod.sum)}</strong></div>
                <div className="card"><span>Serveranfragen</span><strong>{zahl(anfragenGesamt)}</strong></div>
              </div>
            </section>

            <section>
              <h2>Nächste Termine</h2>
              {offen.length === 0 && <p className="permissionNote">Keine offenen Termine.</p>}
              {offen.length > 0 && (
                <table>
                  <thead><tr><th>Zeit</th><th>in</th><th>Dorf</th><th>Einheit</th></tr></thead>
                  <tbody>
                    {offen.slice(0, 15).map((t, i) => (
                      <tr key={i}>
                        <td>{uhr(t.at)}</td>
                        <td>{rest(t.at)}</td>
                        <td>{t.coord}</td>
                        <td>{t.unit}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </section>

            {aktivitaet.length > 0 && (
              <section>
                <h2>Letzte Aktivität</h2>
                <table>
                  <thead><tr><th>Zeit</th><th>Bereich</th><th>Vorgang</th></tr></thead>
                  <tbody>
                    {[...aktivitaet].reverse().slice(0, 12).map((a, i) => (
                      <tr key={i}>
                        <td>{a.at ? uhr(a.at) : ''}</td>
                        <td>{a.art ?? ''}</td>
                        <td>{a.text ?? ''}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </section>
            )}

            {dorfListe.length > 0 && (
              <section>
                <h2>Dörfer</h2>
                <table>
                  <thead><tr><th>Koordinaten</th><th>Name</th></tr></thead>
                  <tbody>
                    {dorfListe
                      .sort((a, b) => (a[1].coord ?? '').localeCompare(b[1].coord ?? '', 'de', { numeric: true }))
                      .map(([id, d]) => (
                        <tr key={id}><td>{d.coord ?? ''}</td><td>{d.name ?? ''}</td></tr>
                      ))}
                  </tbody>
                </table>
              </section>
            )}
          </>
        )}
        <span hidden>{tick}</span>
      </main>
    </div>
  );
}
