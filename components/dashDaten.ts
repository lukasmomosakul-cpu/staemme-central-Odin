'use client';

// 16.10.2026 - Teamuebersicht im Dashboard.
//
// Quelle sind ausschliesslich Werte, die GodBot ohnehin in godbot_settings
// abgleicht. Es geht KEINE Anfrage an den Spielserver: eine einzige
// Supabase-Abfrage fuer alle Konten des Teams, jede Minute neu. Lesen darf
// jedes Teammitglied (RLS "members can read godbot settings").

import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export const DASH_KEYS = [
  'tw_odin_steuerstand', 'tw_godfarm_stand', 'tw_stats_cache',
  'tw_tabben_villages', 'tw_village_dir', 'tw_tabben_raw_troops', 'tw_truppen_stand',
  'tw_build_next_at', 'tw_build_plans', 'tw_recruit_next_at',
  'tw_bot_alert_state', 'tw_botschutz_aufnahme_at', 'tw_aktivitaet', 'tw_autokat_stand',
];

type Zeile = { value: string; updated_at: string };
export type KontoWerte = Record<string, Zeile>;
export type DashDaten = Record<string, KontoWerte>;

export function useDashDaten(ids: string[]) {
  const [daten, setDaten] = useState<DashDaten>({});
  const [geladenAt, setGeladenAt] = useState(0);
  const schluessel = ids.join(',');
  useEffect(() => {
    if (!supabase || !ids.length) return;
    let aus = false;
    const laden = async () => {
      try {
        const { data } = await supabase!.from('godbot_settings')
          .select('account_id,skey,value,updated_at')
          .in('account_id', ids).in('skey', DASH_KEYS);
        const m: DashDaten = {};
        for (const r of (data ?? []) as { account_id: string; skey: string; value: string; updated_at: string }[]) {
          (m[r.account_id] = m[r.account_id] || {})[r.skey] = { value: r.value, updated_at: r.updated_at };
        }
        if (!aus) { setDaten(m); setGeladenAt(Date.now()); }
      } catch { /* naechster Takt */ }
    };
    laden();
    const t = setInterval(laden, 60000);
    return () => { aus = true; clearInterval(t); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [schluessel]);
  return { daten, geladenAt };
}

function lies<T>(w: KontoWerte | undefined, key: string, fallback: T): T {
  try { const r = w?.[key]?.value; return r ? (JSON.parse(r) as T) : fallback; } catch { return fallback; }
}

export const EINHEIT: Record<string, string> = {
  spear: 'Speer', sword: 'Schwert', axe: 'Axt', archer: 'Bogen', spy: 'Späher', light: 'LKav',
  marcher: 'BBogen', heavy: 'SKav', ram: 'Ramme', catapult: 'Kata', knight: 'Paladin', snob: 'AG',
};
const EINHEIT_REIHE = ['axe', 'light', 'marcher', 'ram', 'catapult', 'snob', 'spear', 'sword', 'archer', 'heavy', 'spy', 'knight'];
export const GEBAEUDE: Record<string, string> = { barracks: 'Kaserne', stable: 'Stall', garage: 'Werkstatt', snob: 'Adelshof' };
const SCHALTER: Record<string, string> = { farmen: 'Farmen', bau: 'Bauen', raubzug: 'Raubzug', rohstoffe: 'Rohstoffe', bhwacht: 'BH-Wacht' };

export type Dorf = {
  id: string; name: string; coord: string;
  truppen: [string, number][];
  bau: { at: number; grund: string } | null;
  vorlage: string | null;
  rekrut: { geb: string; at: number; grund: string }[];
};
export type KontoBild = {
  zustand: 'botschutz' | 'arbeitet' | 'ruht' | 'unbekannt';
  gemeldetAt: number;
  version: string;
  schalter: { name: string; an: boolean }[];
  naechstFarm: number | null;
  farm: { gesendet: number; at: number; fehler: boolean; text: string } | null;
  stats: { points?: number; rank?: number; loot_res?: number; loot_vil?: number; at?: number } | null;
  doerfer: Dorf[];
  truppenGesamt: [string, number][];
  truppenAt: number;
  autokat: { spaeher: number; beschuss: number } | null;
  botschutzSeit: number;
  letzteAufnahme: number;
  aktivitaet: { at: number; art: string; text: string }[];
};

// 3 Min. ohne neuen Steuerstand = GodBot laeuft nicht (mehr) sichtbar.
const LEBT_MS = 3 * 60 * 1000;

export function kontoBild(w: KontoWerte | undefined): KontoBild {
  const st = lies<{ schalter?: Record<string, boolean>; ausgeblendet?: string[]; naechst?: Record<string, number | null>;
    botschutz?: boolean; at?: number; version?: string } | null>(w, 'tw_odin_steuerstand', null);
  const alarm = lies<{ active?: boolean; since?: number } | null>(w, 'tw_bot_alert_state', null);
  const gemeldetAt = st?.at ?? 0;
  const botschutz = !!(st?.botschutz || alarm?.active);
  const zustand: KontoBild['zustand'] = !st ? 'unbekannt' : botschutz ? 'botschutz'
    : Date.now() - gemeldetAt < LEBT_MS ? 'arbeitet' : 'ruht';
  const aus = new Set(st?.ausgeblendet ?? []);
  const schalter = Object.keys(SCHALTER).filter(k => st?.schalter && k in st.schalter && !aus.has(k))
    .map(k => ({ name: SCHALTER[k], an: !!st!.schalter![k] }));

  const fs = lies<{ gesendet?: number; at?: number; fehler?: boolean; text?: string } | null>(w, 'tw_godfarm_stand', null);
  const farm = fs && fs.at ? { gesendet: fs.gesendet ?? 0, at: fs.at, fehler: !!fs.fehler, text: fs.text ?? '' } : null;

  // Doerfer: Namen aus der Dorfliste, Truppen bevorzugt aus dem frischeren
  // Truppenstand der Rekrutierung, sonst aus der Truppenuebersicht.
  const tv = lies<{ villages?: Record<string, { coord?: string; name?: string }> }>(w, 'tw_tabben_villages', {});
  const vd = lies<Record<string, { n?: string; c?: string }>>(w, 'tw_village_dir', {});
  const raw = lies<{ villages?: Record<string, Record<string, number>> }>(w, 'tw_tabben_raw_troops', {});
  const ts = lies<Record<string, Record<string, { gesamt?: number }>>>(w, 'tw_truppen_stand', {});
  const bau = lies<Record<string, { at?: number; grund?: string }>>(w, 'tw_build_next_at', {});
  const plaene = lies<Record<string, { name?: string }>>(w, 'tw_build_plans', {});
  const rek = lies<Record<string, { at?: number; grund?: string }>>(w, 'tw_recruit_next_at', {});
  const ids = new Set<string>([...Object.keys(tv.villages ?? {}), ...Object.keys(vd), ...Object.keys(raw.villages ?? {}), ...Object.keys(ts)]);
  const doerfer: Dorf[] = [...ids].map(id => {
    const t: Record<string, number> = {};
    const r = raw.villages?.[id] ?? {};
    for (const u of Object.keys(r)) t[u] = Number(r[u]) || 0;
    const s = ts[id] ?? {};
    for (const u of Object.keys(s)) if (typeof s[u]?.gesamt === 'number') t[u] = s[u].gesamt as number;
    const truppen = EINHEIT_REIHE.filter(u => (t[u] ?? 0) > 0).map(u => [u, t[u]] as [string, number]);
    const b = bau[id];
    const rekrut = Object.keys(rek).filter(k => k.split(':')[0] === id)
      .map(k => ({ geb: k.split(':')[1] ?? '', at: Number(rek[k].at) || 0, grund: rek[k].grund ?? '' }))
      .sort((a, c) => a.at - c.at);
    return {
      id,
      name: tv.villages?.[id]?.name || vd[id]?.n || `Dorf ${id}`,
      coord: tv.villages?.[id]?.coord || vd[id]?.c || '',
      truppen,
      bau: b && b.at ? { at: Number(b.at), grund: b.grund ?? '' } : null,
      vorlage: plaene[id]?.name ?? null,
      rekrut,
    };
  }).sort((a, c) => a.name.localeCompare(c.name, 'de'));

  const summe: Record<string, number> = {};
  for (const d of doerfer) for (const [u, n] of d.truppen) summe[u] = (summe[u] ?? 0) + n;
  const truppenGesamt = EINHEIT_REIHE.filter(u => (summe[u] ?? 0) > 0).map(u => [u, summe[u]] as [string, number]);
  let truppenAt = Number((raw as { at?: number }).at) || 0;
  for (const v of Object.values(ts)) for (const e of Object.values(v ?? {})) {
    const a = Number((e as { at?: number })?.at) || 0; if (a > truppenAt) truppenAt = a;
  }

  const ak = lies<{ ziele?: Record<string, { offen?: { art?: string } }> } | null>(w, 'tw_autokat_stand', null);
  let autokat: KontoBild['autokat'] = null;
  if (ak?.ziele) {
    let spaeher = 0, beschuss = 0;
    for (const z of Object.values(ak.ziele)) {
      if (z?.offen?.art === 'spaeher') spaeher++;
      else if (z?.offen) beschuss++;
    }
    autokat = { spaeher, beschuss };
  }

  const akt = lies<{ at?: number; art?: string; text?: string }[]>(w, 'tw_aktivitaet', []);
  return {
    zustand, gemeldetAt, version: st?.version ?? '', schalter,
    naechstFarm: st?.naechst?.farmen ?? null,
    farm,
    stats: lies(w, 'tw_stats_cache', null),
    doerfer,
    truppenGesamt,
    truppenAt,
    autokat,
    botschutzSeit: alarm?.active ? alarm.since ?? 0 : 0,
    letzteAufnahme: Number(lies<number | string>(w, 'tw_botschutz_aufnahme_at', 0)) || 0,
    aktivitaet: (Array.isArray(akt) ? akt : []).filter(a => a && a.at)
      .map(a => ({ at: a.at as number, art: a.art ?? '', text: a.text ?? '' }))
      .sort((a, c) => c.at - a.at).slice(0, 40),
  };
}

// Aeltere App als die gerade gebaute? (nur Zahlenteile vergleichen)
export function versionAelter(v: string, aktuell: string): boolean {
  const a = v.split('.').map(Number), b = aktuell.split('.').map(Number);
  if (a.some(Number.isNaN) || b.some(Number.isNaN)) return false;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    if ((a[i] ?? 0) !== (b[i] ?? 0)) return (a[i] ?? 0) < (b[i] ?? 0);
  }
  return false;
}

export const zahl = (n?: number | null) => (n == null || Number.isNaN(n) ? '–' : Math.round(n).toLocaleString('de-DE'));
// Spielereignisse mit fester Uhrzeit, dazu die Spanne.
export const uhrzeit = (ms: number) => {
  const d = new Date(ms), h = new Date();
  const gleicherTag = d.toDateString() === h.toDateString();
  return d.toLocaleString('de-DE', gleicherTag ? { hour: '2-digit', minute: '2-digit' }
    : { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
};
export const spanne = (ms: number) => {
  const diff = ms - Date.now(), s = Math.round(Math.abs(diff) / 1000);
  const t = s < 60 ? `${s} s` : s < 3600 ? `${Math.round(s / 60)} Min` : s < 86400 ? `${Math.round(s / 3600)} Std` : `${Math.round(s / 86400)} T`;
  return diff >= 0 ? `in ${t}` : `vor ${t}`;
};
