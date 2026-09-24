'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import OdinShell from '../../components/OdinShell';

// Live-Statistik je Konto. Quelle sind ausschliesslich Daten, die schon
// ankommen: GodBots abgeglichene Werte (godbot_settings) und die Zeilen des
// Spielserver-Zaehlers der App (app_events). Alle 30 Sekunden neu geladen.

type Konto = { id: string; name: string | null; world: string | null };
type Werte = Record<string, { value: string; updated_at: string }>;

function lies<T>(w: Werte, key: string, fallback: T): T {
  try { const r = w[key]?.value; return r ? (JSON.parse(r) as T) : fallback; } catch { return fallback; }
}
const zahl = (n?: number | null) => (n == null || Number.isNaN(n) ? '–' : Math.round(n).toLocaleString('de-DE'));
const uhr = (ms?: number | null) => (ms ? new Date(ms).toLocaleString('de-DE',
  { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' }) : '–');
const vor = (ms?: number | null) => {
  if (!ms) return '–';
  const m = Math.round((Date.now() - ms) / 60000);
  return m < 1 ? 'gerade eben' : m < 60 ? `vor ${m} Min` : `vor ${Math.round(m / 60)} Std`;
};

// Einfaches Balkendiagramm ohne Bibliothek.
function Balken({ werte, beschriftung, max, farbe = '#2563eb', hoehe = 70 }:
  { werte: number[]; beschriftung?: string[]; max?: number; farbe?: string; hoehe?: number }) {
  const m = Math.max(1, max ?? Math.max(...werte, 1));
  const b = 100 / Math.max(1, werte.length);
  return (
    <svg viewBox={`0 0 100 ${hoehe}`} preserveAspectRatio="none" style={{ width: '100%', height: hoehe }}>
      {werte.map((v, i) => {
        const h = (v / m) * (hoehe - 2);
        return <rect key={i} x={i * b + b * 0.1} y={hoehe - h} width={b * 0.8} height={h} fill={farbe}>
          <title>{(beschriftung?.[i] ? beschriftung[i] + ': ' : '') + zahl(v)}</title>
        </rect>;
      })}
    </svg>
  );
}

export default function StatistikSeite() {
  const [konten, setKonten] = useState<Konto[]>([]);
  const [aktiv, setAktiv] = useState('');
  const [w, setW] = useState<Werte>({});
  const [anfragen, setAnfragen] = useState<{ t: number; n: number; seiten: number }[]>([]);
  const [geladen, setGeladen] = useState(0);

  useEffect(() => {
    (async () => {
      if (!supabase) return;
      const { data } = await supabase.from('game_accounts').select('id,name,world').order('name');
      const l = (data ?? []) as Konto[];
      setKonten(l);
      if (l.length) setAktiv(l[0].id);
    })();
  }, []);

  useEffect(() => {
    if (!aktiv || !supabase) return;
    let aus = false;
    const laden = async () => {
      const { data } = await supabase!.from('godbot_settings').select('skey,value,updated_at')
        .eq('account_id', aktiv)
        .in('skey', ['tw_stats_cache', 'tw_production_cache', 'tw_farm_value', 'tw_scavenge_slots',
          'tw_scavenge_coverage_log', 'tw_aktivitaet', 'tw_loop_active', 'tw_next_recheck_at']);
      const map: Werte = {};
      for (const r of (data ?? []) as { skey: string; value: string; updated_at: string }[]) map[r.skey] = r;
      const seit = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
      const { data: ev } = await supabase!.from('app_events').select('message,created_at')
        .eq('account_id', aktiv).like('message', 'Spielserver %').gte('created_at', seit)
        .order('created_at', { ascending: true }).limit(500);
      const a: { t: number; n: number; seiten: number }[] = [];
      for (const e of (ev ?? []) as { message: string; created_at: string }[]) {
        const m = /(\d+) Anfragen, (\d+) Seitenaufrufe/.exec(e.message);
        if (m) a.push({ t: new Date(e.created_at).getTime(), n: Number(m[1]), seiten: Number(m[2]) });
      }
      if (aus) return;
      setW(map); setAnfragen(a); setGeladen(Date.now());
    };
    laden();
    const t = setInterval(laden, 30000);
    return () => { aus = true; clearInterval(t); };
  }, [aktiv]);

  // --- Auswertung ----------------------------------------------------------
  const stats = lies<{ at?: number; points?: number; rank?: number; loot_res?: number; loot_vil?: number; scavenge?: number }>(w, 'tw_stats_cache', {});
  const prod = lies<{ wood?: number; stone?: number; iron?: number; sum?: number; villageCount?: number; speed?: number; at?: number }>(w, 'tw_production_cache', {});
  const farm = lies<{ current?: number; max?: number; isUnlimited?: boolean; fetchedAt?: number }>(w, 'tw_farm_value', {});
  const akt = lies<{ at: number; art?: string; text?: string }[]>(w, 'tw_aktivitaet', []);
  const cov = lies<{ at: number; coverage?: number; sent?: number; waves?: number }[]>(w, 'tw_scavenge_coverage_log', []);
  const slots = lies<Record<string, { slots?: Record<string, { locked?: boolean; busy?: boolean; returnTime?: number | null }> }>>(w, 'tw_scavenge_slots', {});
  // GodBot schreibt "1" (frueher auch "true").
  const loopRoh = (w['tw_loop_active']?.value ?? '').replace(/"/g, '');
  const loopAn = loopRoh === '1' || loopRoh === 'true';

  let frei = 0, belegt = 0, gesperrt = 0, naechste = 0;
  for (const d of Object.values(slots)) for (const s of Object.values(d.slots ?? {})) {
    if (s.locked) gesperrt++; else if (s.busy) { belegt++; const r = (s.returnTime ?? 0) * 1000;
      if (r > Date.now() && (!naechste || r < naechste)) naechste = r; } else frei++;
  }
  const covLetzte = cov.slice(-24);
  const covSchnitt = covLetzte.length ? covLetzte.reduce((n, c) => n + (c.coverage ?? 0), 0) / covLetzte.length : null;
  const tag = Date.now() - 24 * 3600 * 1000;
  const laeufe24 = cov.filter(c => c.at > tag).length;

  // Anfragen je Stunde (letzte 24 Std). Eine Zeile deckt ~10 Min ab und wird
  // der Stunde zugeordnet, in der sie geschrieben wurde.
  const stunden = Array.from({ length: 24 }, (_, i) => {
    const ende = Date.now() - (23 - i) * 3600 * 1000;
    return { von: ende - 3600 * 1000, bis: ende, n: 0, s: 0 };
  });
  for (const x of anfragen) for (const s of stunden) if (x.t > s.von && x.t <= s.bis) { s.n += x.n; s.s += x.seiten; }
  const anf24 = stunden.reduce((n, s) => n + s.n, 0);
  const seiten24 = stunden.reduce((n, s) => n + s.s, 0);

  const bot = akt.filter(a => a.art === 'botschutz');
  const botErkannt7 = bot.filter(a => a.at > Date.now() - 7 * 86400000 && /erkannt/i.test(a.text ?? '')).length;

  const k = konten.find(x => x.id === aktiv);

  return (
    <OdinShell titel="Statistik" aktiv="Statistik">
      <section className="section card">
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          {konten.length > 1 ? (
            <select value={aktiv} onChange={e => setAktiv(e.target.value)} aria-label="Konto">
              {konten.map(x => <option key={x.id} value={x.id}>{x.name || x.id.slice(0, 8)} · {x.world || '–'}</option>)}
            </select>
          ) : <strong>{k ? `${k.name ?? ''} · ${k.world ?? ''}` : 'Kein Konto'}</strong>}
          <span className="pill">{loopAn ? '🟢 Raubzug an' : '⚪ Raubzug aus'}</span>
          <span className="muted">aktualisiert {geladen ? new Date(geladen).toLocaleTimeString('de-DE') : '–'} · alle 30 s</span>
        </div>
      </section>

      <section className="section grid">
        <div className="card"><div className="muted">Punkte</div><div className="metric">{zahl(stats.points)}</div>
          <div className="muted">Rang {zahl(stats.rank)} · {vor(stats.at)}</div></div>
        <div className="card"><div className="muted">Produktion / Std</div><div className="metric">{zahl(prod.sum)}</div>
          <div className="muted">{zahl(prod.villageCount)} Dörfer · {vor(prod.at)}</div></div>
        <div className="card"><div className="muted">Farmwert</div><div className="metric">{zahl(farm.current)}</div>
          <div className="muted">{farm.isUnlimited ? 'unbegrenzt' : `von ${zahl(farm.max)}`} · {vor(farm.fetchedAt)}</div></div>
        <div className="card"><div className="muted">Raubzug-Abdeckung</div>
          <div className="metric">{covSchnitt == null ? '–' : `${Math.round(covSchnitt)} %`}</div>
          <div className="muted">Ø letzte {covLetzte.length} Läufe · {laeufe24} in 24 Std</div></div>
      </section>

      <section className="section grid">
        <div className="card"><div className="muted">Holz / Lehm / Eisen je Std</div>
          <div style={{ fontWeight: 700, marginTop: 6 }}>{zahl(prod.wood)} / {zahl(prod.stone)} / {zahl(prod.iron)}</div>
          <div className="muted">Weltgeschwindigkeit {prod.speed ? prod.speed.toFixed(2) : '–'}</div></div>
        <div className="card"><div className="muted">Beute (Ressourcen / Dörfer)</div>
          <div style={{ fontWeight: 700, marginTop: 6 }}>{zahl(stats.loot_res)} / {zahl(stats.loot_vil)}</div>
          <div className="muted">Raubzug gesamt {zahl(stats.scavenge)}</div></div>
        <div className="card"><div className="muted">Raubzug-Slots</div>
          <div style={{ fontWeight: 700, marginTop: 6 }}>{frei} frei · {belegt} belegt · {gesperrt} gesperrt</div>
          <div className="muted">nächste Rückkehr {naechste ? uhr(naechste) : '–'}</div></div>
        <div className="card"><div className="muted">Botschutz (7 Tage)</div>
          <div className="metric">{botErkannt7}</div>
          <div className="muted">{bot.length ? `zuletzt ${vor(bot[bot.length - 1].at)}` : 'keine Einträge'}</div></div>
      </section>

      <section className="section card">
        <h2>Anfragen an den Spielserver – letzte 24 Std</h2>
        <div className="muted">{zahl(anf24)} Anfragen, davon {zahl(seiten24)} volle Seitenaufrufe · je Balken eine Stunde</div>
        <Balken werte={stunden.map(s => s.n)} beschriftung={stunden.map(s => new Date(s.bis).getHours() + ' Uhr')} />
        <Balken werte={stunden.map(s => s.s)} farbe="#f59e0b" hoehe={30} max={Math.max(...stunden.map(s => s.n), 1)} />
        <div className="muted">blau: alle Anfragen · orange: volle Seitenaufrufe (meist du beim Spielen)</div>
      </section>

      <section className="section card">
        <h2>Raubzug-Läufe</h2>
        <div className="muted">Abdeckung der letzten {covLetzte.length} Läufe (Balken = Prozent der Dörfer versorgt)</div>
        <Balken werte={covLetzte.map(c => c.coverage ?? 0)} max={100} farbe="#16a34a"
                beschriftung={covLetzte.map(c => `${uhr(c.at)} · ${c.sent ?? 0} Wellen`)} />
      </section>

      <section className="section card">
        <h2>Letzte Ereignisse</h2>
        {akt.slice(-15).reverse().map((a, i) => (
          <div key={i} className="event">
            <span className="pill">{a.art ?? '–'}</span>
            <div style={{ minWidth: 0 }}><div>{a.text ?? ''}</div><div className="muted">{uhr(a.at)}</div></div>
          </div>
        ))}
        {!akt.length && <div className="muted">Noch keine Ereignisse abgeglichen.</div>}
      </section>
    </OdinShell>
  );
}
