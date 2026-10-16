'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { EINHEIT, GEBAEUDE, type KontoBild, spanne, uhrzeit, versionAelter, zahl } from './dashDaten';

const APP_VERSION = process.env.NEXT_PUBLIC_APP_VERSION || '';

const ZUSTAND: Record<KontoBild['zustand'], { text: string; klasse: string }> = {
  botschutz: { text: 'Botschutz', klasse: 'rot' },
  arbeitet: { text: 'GodBot arbeitet', klasse: 'gruen' },
  ruht: { text: 'ruht', klasse: 'grau' },
  unbekannt: { text: 'keine Daten', klasse: 'grau' },
};

export function ZustandPunkt({ bild }: { bild: KontoBild }) {
  const z = ZUSTAND[bild.zustand];
  return <span className={`dashDot ${z.klasse}`} title={z.text} aria-label={z.text} />;
}

// Kurzzeile im zugeklappten Kopf: Punkte und Rang.
export function KontoKurz({ bild }: { bild: KontoBild }) {
  const s = bild.stats;
  if (!s || s.points == null) return null;
  return <span className="dashKurz">{zahl(s.points)} P.{s.rank ? ` · Rang ${zahl(s.rank)}` : ''}</span>;
}

const ART: Record<string, string> = { botschutz: 'Botschutz', attack: 'Angriff', farm: 'Farmen', bau: 'Bau',
  truppen: 'Truppen', raubzug: 'Raubzug', support: 'Unterstützung', rohstoffe: 'Rohstoffe' };
const artText = (a: string) => ART[a] ?? (a ? a[0].toUpperCase() + a.slice(1) : '');

// Wie alt darf ein Wert sein, bevor er als veraltet markiert wird?
function Alter({ at, grenzeMin }: { at?: number | null; grenzeMin: number }) {
  if (!at) return <span className="muted"> · Stand unbekannt</span>;
  const alt = Date.now() - at > grenzeMin * 60000;
  return <span className={alt ? 'dashWarn' : 'muted'}> · Stand {spanne(at)}{alt ? ' (veraltet)' : ''}</span>;
}

function Balken({ werte, beschriftung, max, farbe = '#2563eb', hoehe = 54 }:
  { werte: number[]; beschriftung?: string[]; max?: number; farbe?: string; hoehe?: number }) {
  const m = Math.max(1, max ?? Math.max(...werte, 1));
  const b = 100 / Math.max(1, werte.length);
  return (
    <svg viewBox={`0 0 100 ${hoehe}`} preserveAspectRatio="none" style={{ width: '100%', height: hoehe, display: 'block', marginTop: 6 }}>
      {werte.map((v, i) => {
        const h = (v / m) * (hoehe - 2);
        return <rect key={i} x={i * b + b * 0.12} y={hoehe - h} width={b * 0.76} height={h} fill={farbe} rx={0.6}>
          <title>{(beschriftung?.[i] ? beschriftung[i] + ': ' : '') + zahl(v)}</title>
        </rect>;
      })}
    </svg>
  );
}

// Ausfuehrliche Werte nur fuer die AUFGEKLAPPTE Karte (eigene Abfrage je
// Minute) - Produktion und Raubzug-Slots sind bei grossen Konten 50-70 KB.
type Detail = {
  prod: { wood?: number; stone?: number; iron?: number; sum?: number; villageCount?: number; at?: number } | null;
  farm: { current?: number; max?: number; isUnlimited?: boolean; fetchedAt?: number } | null;
  slots: Record<string, { slots?: Record<string, { locked?: boolean; busy?: boolean; returnTime?: number | null }> }>;
  cov: { at: number; coverage?: number; sent?: number }[];
  loopAn: boolean;
  anfragen: { t: number; n: number; seiten: number }[];
};
function useKontoDetail(id: string) {
  const [d, setD] = useState<Detail | null>(null);
  useEffect(() => {
    if (!supabase || !id) return;
    let aus = false;
    const lies = <T,>(m: Record<string, string>, k: string, f: T): T => { try { return m[k] ? JSON.parse(m[k]) as T : f; } catch { return f; } };
    const laden = async () => {
      try {
        const { data } = await supabase!.from('godbot_settings').select('skey,value').eq('account_id', id)
          .in('skey', ['tw_production_cache', 'tw_farm_value', 'tw_scavenge_slots', 'tw_scavenge_coverage_log', 'tw_loop_active']);
        const m: Record<string, string> = {};
        for (const r of (data ?? []) as { skey: string; value: string }[]) m[r.skey] = r.value;
        const seit = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
        const { data: ev } = await supabase!.from('app_events').select('message,created_at').eq('account_id', id)
          .like('message', 'Spielserver %').gte('created_at', seit).order('created_at', { ascending: true }).limit(500);
        const anfragen: Detail['anfragen'] = [];
        for (const e of (ev ?? []) as { message: string; created_at: string }[]) {
          const x = /(\d+) Anfragen, (\d+) Seitenaufrufe/.exec(e.message);
          if (x) anfragen.push({ t: new Date(e.created_at).getTime(), n: Number(x[1]), seiten: Number(x[2]) });
        }
        const loopRoh = (m['tw_loop_active'] ?? '').replace(/"/g, '');
        if (!aus) setD({
          prod: lies(m, 'tw_production_cache', null), farm: lies(m, 'tw_farm_value', null),
          slots: lies(m, 'tw_scavenge_slots', {}), cov: lies(m, 'tw_scavenge_coverage_log', []),
          loopAn: loopRoh === '1' || loopRoh === 'true', anfragen,
        });
      } catch { /* naechster Takt */ }
    };
    laden();
    const t = setInterval(laden, 60000);
    return () => { aus = true; clearInterval(t); };
  }, [id]);
  return d;
}

function Zeile({ label, children }: { label: string; children: React.ReactNode }) {
  return <div className="accRow"><span className="accLabel">{label}</span><div>{children}</div></div>;
}

export function KontoDetails({ bild, kontoId }: { bild: KontoBild; kontoId: string }) {
  const [dorfOffen, setDorfOffen] = useState<string | null>(null);
  const [alleEreignisse, setAlleEreignisse] = useState(false);
  const det = useKontoDetail(kontoId);
  const viele = bild.doerfer.length > 6;
  const [listeOffen, setListeOffen] = useState(false);
  const z = ZUSTAND[bild.zustand];
  const alt = bild.version && APP_VERSION && versionAelter(bild.version, APP_VERSION);
  return (
    <>
      <Zeile label="Status">
        <span className={`dashChip ${z.klasse}`}>{z.text}</span>
        {bild.gemeldetAt ? <span className="muted"> · gemeldet {spanne(bild.gemeldetAt)}</span> : null}
        {bild.version ? <span className={alt ? 'dashWarn' : 'muted'}> · App {bild.version}{alt ? ` (aktuell ${APP_VERSION})` : ''}</span> : null}
        {bild.botschutzSeit ? <div className="dashWarn">Botschutz seit {uhrzeit(bild.botschutzSeit)} - von Hand lösen.</div> : null}
        {bild.schalter.length ? <div className="dashChips">{bild.schalter.map(s =>
          <span key={s.name} className={`dashChip ${s.an ? 'an' : 'aus'}`}>{s.name}</span>)}</div> : null}
      </Zeile>

      <Zeile label="Farmen">
        {bild.farm ? <>
          <strong>{bild.farm.gesendet} Angriff(e)</strong>
          <span className="muted"> · letzter Lauf {uhrzeit(bild.farm.at)} ({spanne(bild.farm.at)})</span>
          {bild.farm.fehler ? <span className="dashWarn"> · mit Fehler</span> : null}
          {bild.naechstFarm && bild.naechstFarm > Date.now()
            ? <div className="muted">nächster Lauf {uhrzeit(bild.naechstFarm)} ({spanne(bild.naechstFarm)})</div> : null}
        </> : <span className="muted">noch kein GodBot-Farm-Lauf</span>}
      </Zeile>

      {bild.stats && (bild.stats.loot_res != null || bild.stats.loot_vil != null) ? (
        <Zeile label="Rangliste">
          {zahl(bild.stats.points)} Punkte{bild.stats.rank ? ` · Rang ${zahl(bild.stats.rank)}` : ''}
          <div className="muted">erfarmt {zahl(bild.stats.loot_res)} Rohstoffe · {zahl(bild.stats.loot_vil)} Dörfer geplündert
            </div><Alter at={bild.stats.at} grenzeMin={150} />
        </Zeile>
      ) : null}

      {det?.prod && det.prod.sum != null ? (
        <Zeile label="Produktion">
          <strong>{zahl(det.prod.sum)} / Std</strong>
          <span className="muted"> · Holz {zahl(det.prod.wood)} · Lehm {zahl(det.prod.stone)} · Eisen {zahl(det.prod.iron)}</span>
          <div><Alter at={det.prod.at} grenzeMin={12 * 60} /></div>
        </Zeile>
      ) : null}

      {det?.farm && det.farm.current != null ? (
        <Zeile label="Farmlimit">
          {zahl(det.farm.current)}{det.farm.isUnlimited ? <span className="muted"> · unbegrenzt</span> : <span className="muted"> von {zahl(det.farm.max)}</span>}
          <Alter at={det.farm.fetchedAt} grenzeMin={6 * 60} />
        </Zeile>
      ) : null}

      {det && (Object.keys(det.slots).length || det.cov.length) ? (() => {
        let frei = 0, belegt = 0, gesperrt = 0, naechste = 0;
        for (const v of Object.values(det.slots)) for (const sl of Object.values(v.slots ?? {})) {
          if (sl.locked) gesperrt++; else if (sl.busy) { belegt++; const r = (sl.returnTime ?? 0) * 1000;
            if (r > Date.now() && (!naechste || r < naechste)) naechste = r; } else frei++;
        }
        const letzte = det.cov.slice(-24);
        const schnitt = letzte.length ? letzte.reduce((n, c) => n + (c.coverage ?? 0), 0) / letzte.length : null;
        const tag = Date.now() - 86400000;
        return (
          <Zeile label="Raubzug">
            <span className={`dashChip ${det.loopAn ? 'an' : 'aus'}`}>{det.loopAn ? 'an' : 'aus'}</span>
            <span className="muted"> {frei} frei · {belegt} belegt · {gesperrt} gesperrt</span>
            {naechste ? <div className="muted">nächste Rückkehr {uhrzeit(naechste)} ({spanne(naechste)})</div> : null}
            {schnitt != null ? <div className="muted">Ø Abdeckung {Math.round(schnitt)} % · {det.cov.filter(c => c.at > tag).length} Läufe in 24 Std</div> : null}
          </Zeile>
        );
      })() : null}

      {det && det.anfragen.length ? (() => {
        const stunden = Array.from({ length: 24 }, (_, i) => {
          const ende = Date.now() - (23 - i) * 3600000;
          return { von: ende - 3600000, bis: ende, n: 0, s: 0 };
        });
        for (const x of det.anfragen) for (const st of stunden) if (x.t > st.von && x.t <= st.bis) { st.n += x.n; st.s += x.seiten; }
        const summe = stunden.reduce((n, st) => n + st.n, 0), seiten = stunden.reduce((n, st) => n + st.s, 0);
        return (
          <Zeile label="Spielserver">
            <strong>{zahl(summe)} Anfragen</strong><span className="muted"> · {zahl(seiten)} Seitenaufrufe · 24 Std</span>
            <Balken werte={stunden.map(st => st.n)} beschriftung={stunden.map(st => new Date(st.bis).getHours() + ' Uhr')} />
          </Zeile>
        );
      })() : null}


      {bild.autokat ? (
        <Zeile label="Auto-Kat">
          {bild.autokat.beschuss || bild.autokat.spaeher
            ? <>{bild.autokat.beschuss} Beschuss · {bild.autokat.spaeher} Späher unterwegs</>
            : <span className="muted">nichts unterwegs</span>}
        </Zeile>
      ) : null}

      <Zeile label={`Dörfer (${bild.doerfer.length})`}>
        {bild.doerfer.length === 0 ? <span className="muted">noch keine Dorfdaten</span> : <>
          {viele ? <div className="dashSumme">
            <div className="dashTruppen">{bild.truppenGesamt.map(([u, n]) =>
              <span key={u} className="dashTrupp"><b>{zahl(n)}</b> {EINHEIT[u] ?? u}</span>)}</div>
            <div className="muted dashGrund">Summe aller Dörfer{bild.truppenAt ? ` · Stand ${uhrzeit(bild.truppenAt)}` : ''}</div>
            <button type="button" className="dashMehr" onClick={() => setListeOffen(o => !o)} aria-expanded={listeOffen}>
              {listeOffen ? 'Dörfer ausblenden' : `Alle ${bild.doerfer.length} Dörfer anzeigen`}</button>
          </div> : null}
          {!viele || listeOffen ? <div className="dashDoerfer">
            {bild.doerfer.map(d => {
              const auf = dorfOffen === d.id || bild.doerfer.length === 1;
              return (
                <div key={d.id} className="dashDorf">
                  <button type="button" className="dashDorfKopf" onClick={() => setDorfOffen(auf ? null : d.id)}
                    aria-expanded={auf} disabled={bild.doerfer.length === 1}>
                    {d.coord ? <span className="dashCoord">{d.coord}</span> : null}<strong>{d.name}</strong>
                    {!auf && d.truppen.length ? <span className="muted dashKurzTrupp"> · {d.truppen.slice(0, 3).map(([u, n]) => `${zahl(n)} ${EINHEIT[u] ?? u}`).join(' · ')}</span> : null}
                  </button>
                  {auf ? <div className="dashDorfBody">
                    <div className="dashTruppen">
                      {d.truppen.length ? d.truppen.map(([u, n]) =>
                        <span key={u} className="dashTrupp"><b>{zahl(n)}</b> {EINHEIT[u] ?? u}</span>)
                        : <span className="muted">keine Truppendaten</span>}
                    </div>
                    {d.bau ? <div><span className="accLabel">Bau</span> {uhrzeit(d.bau.at)} <span className="muted">({spanne(d.bau.at)})</span>
                      {d.vorlage ? <span className="muted"> · Vorlage „{d.vorlage}“</span> : null}
                      <div className="muted dashGrund">{d.bau.grund}</div></div> : null}
                    {d.rekrut.length ? <div><span className="accLabel">Rekrutierung</span>
                      {d.rekrut.map(r => <div key={r.geb} className="muted dashGrund">
                        {GEBAEUDE[r.geb] ?? r.geb}: {uhrzeit(r.at)} – {r.grund}</div>)}</div> : null}
                  </div> : null}
                </div>
              );
            })}
          </div> : null}
          {!viele && bild.truppenAt ? <div className="muted dashGrund">Truppen Stand {uhrzeit(bild.truppenAt)}</div> : null}
        </>}
      </Zeile>

      {bild.aktivitaet.length ? (
        <Zeile label="Ereignisse">
          {(alleEreignisse ? bild.aktivitaet : bild.aktivitaet.slice(0, 4)).map((a, i) => <div key={i} className="dashGrund">
            <span className="muted">{uhrzeit(a.at)}</span> {a.art ? <b>{artText(a.art)}</b> : null} {a.text}</div>)}
          {bild.aktivitaet.length > 4 ? <button type="button" className="dashMehr" style={{ marginTop: 6 }}
            onClick={() => setAlleEreignisse(x => !x)}>{alleEreignisse ? 'weniger' : `alle ${bild.aktivitaet.length} anzeigen`}</button> : null}
        </Zeile>
      ) : null}
    </>
  );
}
