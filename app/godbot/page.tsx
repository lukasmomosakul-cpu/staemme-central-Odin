'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { supabase } from '../../lib/supabase';
import OdinShell from '../../components/OdinShell';

// GodBot-Steuerzentrale.
//
// GodBot ist die Arbeit, diese Seite die Bedienung. Der Weg ist zweiseitig:
//   runter: jede Aenderung wird eine Zeile in godbot_befehle (eine Einstellung
//           je Zeile). Die Spielansicht holt sie ab und schaltet ueber
//           dieselben Knoepfe wie im Spiel, danach wird die Zeile bestaetigt.
//   hoch:   GodBot meldet seinen Ist-Zustand als tw_odin_steuerstand.
// Angezeigt wird immer der gemeldete Ist-Zustand. Solange ein Befehl
// unterwegs ist, zeigt der Schalter die neue Stellung mit "wird übernommen".

type Konto = { id: string; name: string | null; world: string | null; team_id: string };
type Takt = { von?: number; bis?: number };
type Stand = {
  at?: number;
  version?: string;
  schalter?: Record<string, boolean | null>;
  werte?: Record<string, number | Takt>;
  naechst?: Record<string, number | null>;
  laeuft?: string | null;
  botschutz?: boolean | null;
};
type Befehl = { id: number; pfad: string; wert: unknown; zeit: number; erledigt?: boolean; ok?: boolean | null; ergebnis?: string | null };

const MODULE: { key: string; titel: string; text: string; sperre: string }[] = [
  { key: 'raubzug', titel: 'Raubzug', text: 'Schickt Truppen auf Raubzüge und holt sie zurück.', sperre: 'scavenge' },
  { key: 'farmen', titel: 'Farmen', text: 'Farmassistent im Takt, mit Farmwert-Wächter.', sperre: 'farm' },
  { key: 'bau', titel: 'Bauautomat', text: 'Baut nach den Vorlagen, solange der Account-Manager ruht.', sperre: 'bau' },
  { key: 'rohstoffe', titel: 'Rohstoff-Fix', text: 'Gleicht Rohstoffe zwischen den Dörfern aus.', sperre: 'resources' },
  { key: 'bhwacht', titel: 'Bauernhof-Wacht', text: 'Zieht den Bauernhof vor, bevor Plätze fehlen – auch im Account-Manager.', sperre: '' },
];

const TAKTE: { pfad: string; titel: string; min: number; max: number }[] = [
  { pfad: 'raubzug.takt', titel: 'Raubzug prüfen', min: 10, max: 480 },
  { pfad: 'farmen.takt', titel: 'Farmen', min: 5, max: 240 },
  { pfad: 'rohstoffe.takt', titel: 'Rohstoff-Fix', min: 15, max: 480 },
];

const vor = (ms?: number) => {
  if (!ms) return '–';
  const s = Math.max(0, Math.round((Date.now() - ms) / 1000));
  return s < 60 ? `vor ${s} s` : s < 3600 ? `vor ${Math.round(s / 60)} Min` : `vor ${Math.round(s / 3600)} Std`;
};
const inZeit = (ms?: number | null) => {
  if (!ms) return '';
  const m = Math.round((ms - Date.now()) / 60000);
  return ms <= Date.now() ? 'fällig' : m < 1 ? 'in <1 Min' : m < 60 ? `in ${m} Min` : `in ${Math.floor(m / 60)} Std ${m % 60} Min`;
};
const uhr = (ms: number) =>
  new Date(ms).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

function lies<T>(roh: string | undefined, fallback: T): T {
  try { return roh ? (JSON.parse(roh) as T) : fallback; } catch { return fallback; }
}

// --- kleine Bausteine -------------------------------------------------------
function Schalter({ an, wartet, onClick, aus }: { an: boolean; wartet: boolean; onClick: () => void; aus?: boolean }) {
  return (
    <button
      type="button" role="switch" aria-checked={an} disabled={aus} onClick={onClick}
      style={{
        width: 52, height: 30, borderRadius: 999, border: 0, padding: 3, cursor: aus ? 'default' : 'pointer',
        background: an ? 'linear-gradient(145deg,#d9b873,#b98f48)' : '#d5dde7',
        opacity: aus ? 0.5 : wartet ? 0.75 : 1, transition: 'background .2s ease', flex: '0 0 auto',
      }}
    >
      <span style={{
        display: 'block', width: 24, height: 24, borderRadius: '50%', background: '#fff',
        boxShadow: '0 1px 4px rgba(0,0,0,.25)', transform: `translateX(${an ? 22 : 0}px)`, transition: 'transform .2s ease',
      }} />
    </button>
  );
}

function Punkt({ farbe }: { farbe: string }) {
  return <span style={{ display: 'inline-block', width: 8, height: 8, borderRadius: '50%', background: farbe, marginRight: 6 }} />;
}

const feld = { width: 70, padding: '8px 10px', borderRadius: 10, border: '1px solid var(--odin-border)' } as const;

export default function GodBotSeite() {
  const [konten, setKonten] = useState<Konto[]>([]);
  const [aktiv, setAktiv] = useState('');
  const [stand, setStand] = useState<Stand | null>(null);
  const [aktivitaet, setAktivitaet] = useState<{ at?: number; art?: string; text?: string }[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [befehle, setBefehle] = useState<Befehl[]>([]);
  const [entwurf, setEntwurf] = useState<Record<string, string>>({});
  const [meldung, setMeldung] = useState<{ text: string; gut: boolean } | null>(null);
  const [, setTick] = useState(0);
  const befehleRef = useRef<Befehl[]>([]);
  befehleRef.current = befehle;

  useEffect(() => { const t = setInterval(() => setTick(x => x + 1), 1000); return () => clearInterval(t); }, []);

  useEffect(() => {
    (async () => {
      if (!supabase) { setLaedt(false); return; }
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) { window.location.href = '/login/'; return; }
      const { data } = await supabase.from('game_accounts').select('id,name,world,team_id').order('name');
      const l = (data ?? []) as Konto[];
      setKonten(l);
      const gemerkt = typeof localStorage !== 'undefined' ? localStorage.getItem('odin-selected-game-account') : null;
      setAktiv(l.find(k => k.id === gemerkt)?.id ?? l[0]?.id ?? '');
      if (!l.length) setLaedt(false);
    })();
  }, []);

  // Ist-Zustand: klein und oft (10 s) - nur der Steuerstand und die Aktivitaet.
  const standLaden = useCallback(async () => {
    if (!aktiv || !supabase) return;
    const { data } = await supabase.from('godbot_settings').select('skey,value')
      .eq('account_id', aktiv).in('skey', ['tw_odin_steuerstand', 'tw_aktivitaet']);
    const m: Record<string, string> = {};
    for (const r of (data ?? []) as { skey: string; value: string }[]) m[r.skey] = r.value;
    setStand(lies<Stand | null>(m['tw_odin_steuerstand'], null));
    setAktivitaet(lies<{ at?: number; art?: string; text?: string }[]>(m['tw_aktivitaet'], []));
    setLaedt(false);
  }, [aktiv]);

  useEffect(() => {
    setStand(null); setBefehle([]); setEntwurf({}); setLaedt(true);
    standLaden();
    const t = setInterval(standLaden, 10000);
    return () => clearInterval(t);
  }, [standLaden]);

  // Offene Befehle verfolgen, bis die Spielansicht sie bestaetigt hat.
  useEffect(() => {
    const t = setInterval(async () => {
      const offen = befehleRef.current.filter(b => !b.erledigt);
      if (!offen.length || !supabase) return;
      const { data } = await supabase.from('godbot_befehle').select('id,ok,ergebnis,erledigt_at')
        .in('id', offen.map(b => b.id));
      const fertig = ((data ?? []) as { id: number; ok: boolean | null; ergebnis: string | null; erledigt_at: string | null }[])
        .filter(r => r.erledigt_at);
      if (!fertig.length) return;
      setBefehle(bs => bs.map(b => {
        const f = fertig.find(x => x.id === b.id);
        return f ? { ...b, erledigt: true, ok: f.ok, ergebnis: f.ergebnis } : b;
      }));
      const schlecht = fertig.find(f => !f.ok);
      setMeldung(schlecht
        ? { text: `Nicht übernommen: ${schlecht.ergebnis ?? ''}`, gut: false }
        : { text: 'Übernommen', gut: true });
      standLaden();
    }, 2000);
    return () => clearInterval(t);
  }, [standLaden]);

  useEffect(() => {
    if (!meldung) return;
    const t = setTimeout(() => setMeldung(null), meldung.gut ? 2500 : 8000);
    return () => clearTimeout(t);
  }, [meldung]);

  const konto = konten.find(k => k.id === aktiv);

  const senden = async (pfad: string, wert: unknown) => {
    if (!supabase || !konto) return;
    const { data, error } = await supabase.from('godbot_befehle')
      .insert({ team_id: konto.team_id, account_id: konto.id, pfad, wert })
      .select('id').single();
    if (error || !data) { setMeldung({ text: `Senden fehlgeschlagen: ${error?.message ?? '?'}`, gut: false }); return; }
    const id = (data as { id: number }).id;
    setBefehle(bs => [...bs.filter(b => b.pfad !== pfad || b.erledigt), { id, pfad, wert, zeit: Date.now() }]);
  };

  // Was der Schalter zeigt: ein offener Befehl gewinnt, sonst der Ist-Zustand.
  const offenFuer = (pfad: string) => [...befehle].reverse().find(b => b.pfad === pfad && !b.erledigt);
  const schalterStand = (key: string): boolean => {
    const o = offenFuer(key);
    if (o) return o.wert === true;
    return !!stand?.schalter?.[key];
  };

  const lebt = !!stand?.at && Date.now() - stand.at < 3 * 60 * 1000;
  const bot = !!stand?.botschutz;

  const statusZeile = (m: typeof MODULE[number]) => {
    if (offenFuer(m.key)) return { farbe: '#b98f48', text: 'wird übernommen …' };
    const an = !!stand?.schalter?.[m.key];
    if (bot && an) return { farbe: '#c0392b', text: 'Botschutz – pausiert' };
    if (m.sperre && stand?.laeuft === m.sperre) return { farbe: '#d4a017', text: 'läuft gerade' };
    if (!an) return { farbe: '#9aa7b5', text: 'aus' };
    if (m.key === 'bhwacht') {
      const p = stand?.werte?.['bhwacht.prozent'];
      return { farbe: '#2f9e6b', text: `an · unter ${typeof p === 'number' ? p : '–'} % freien Plätzen` };
    }
    const n = stand?.naechst?.[m.key];
    return { farbe: '#2f9e6b', text: n ? `an · nächster Lauf ${inZeit(n)}` : 'an' };
  };

  const taktWert = (pfad: string): Takt => {
    const w = stand?.werte?.[pfad];
    return typeof w === 'object' && w ? w : {};
  };

  const ohne = (x: Record<string, string>, ...k: string[]) => { const n = { ...x }; k.forEach(s => delete n[s]); return n; };

  return (
    <OdinShell
      titel="GodBot"
      aktiv="GodBot"
      rechts={konten.length > 1 ? (
        <select value={aktiv} aria-label="Konto"
          onChange={e => { setAktiv(e.target.value); localStorage.setItem('odin-selected-game-account', e.target.value); }}>
          {konten.map(k => <option key={k.id} value={k.id}>{k.name ?? k.id.slice(0, 8)} · {k.world ?? '–'}</option>)}
        </select>
      ) : undefined}
    >
      {/* Lebenszeichen */}
      <section className="section card" style={{ padding: '14px 18px', marginBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <strong>{konto ? `${konto.name ?? ''} · ${konto.world ?? ''}` : 'Kein Konto'}</strong>
          {laedt ? <span className="muted">lädt …</span> : !stand ? (
            <span className="muted">GodBot hat sich für dieses Konto noch nicht gemeldet – einmal das Spiel öffnen.</span>
          ) : (
            <span className="muted">
              <Punkt farbe={bot ? '#c0392b' : lebt ? '#2f9e6b' : '#9aa7b5'} />
              {bot ? 'Botschutz aktiv' : lebt ? 'GodBot arbeitet' : 'Spielansicht ruht'}
              {' · '}zuletzt gemeldet {vor(stand.at)}{stand.version ? ` · v${stand.version}` : ''}
            </span>
          )}
        </div>
        {!!stand && !lebt && (
          <div className="muted" style={{ fontSize: 12, marginTop: 6 }}>
            Änderungen werden übernommen, sobald die Spielansicht wieder läuft (spätestens beim nächsten Wecken).
          </div>
        )}
      </section>

      {meldung && (
        <div className="toast" style={{
          position: 'sticky', top: 70, zIndex: 20, padding: '10px 14px', borderRadius: 12, marginBottom: 12,
          color: meldung.gut ? '#287a4b' : '#a63f3f', fontWeight: 700,
        }}>{meldung.gut ? '✓ ' : '✗ '}{meldung.text}</div>
      )}

      {/* Module */}
      <section className="section" style={{ marginBottom: 20 }}>
        <div className="sectionhead"><h2>Automatik</h2></div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(260px,1fr))', gap: 12 }}>
          {MODULE.map(m => {
            const z = statusZeile(m);
            const an = schalterStand(m.key);
            return (
              <div key={m.key} className="card" style={{ padding: 16, display: 'flex', gap: 14, alignItems: 'center' }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 800, fontSize: 15 }}>{m.titel}</div>
                  <div style={{ fontSize: 12, marginTop: 4, color: z.farbe, fontWeight: 700 }}>
                    <Punkt farbe={z.farbe} />{z.text}
                  </div>
                  <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>{m.text}</div>
                </div>
                <Schalter an={an} wartet={!!offenFuer(m.key)} aus={!stand} onClick={() => senden(m.key, !an)} />
              </div>
            );
          })}
        </div>
      </section>

      {/* Takte und Marke */}
      <section className="section" style={{ marginBottom: 20 }}>
        <div className="sectionhead"><h2>Takt</h2></div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill,minmax(260px,1fr))', gap: 12 }}>
          {TAKTE.map(t => {
            const ist = taktWert(t.pfad);
            const kv = t.pfad + '.von', kb = t.pfad + '.bis';
            const vonE = entwurf[kv] ?? String(ist.von ?? '');
            const bisE = entwurf[kb] ?? String(ist.bis ?? '');
            const geaendert = vonE !== String(ist.von ?? '') || bisE !== String(ist.bis ?? '');
            const v = Number(vonE), b = Number(bisE);
            const gueltig = vonE !== '' && bisE !== '' && v >= t.min && b <= t.max && v <= b;
            const unterwegs = !!offenFuer(t.pfad);
            return (
              <div key={t.pfad} className="card" style={{ padding: 16 }}>
                <div style={{ fontWeight: 800 }}>{t.titel}</div>
                <div className="muted" style={{ fontSize: 12, margin: '4px 0 10px' }}>
                  zufällig zwischen … Minuten (erlaubt {t.min}–{t.max})
                </div>
                <div className="field" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input inputMode="numeric" value={vonE} disabled={!stand} aria-label="von" style={feld}
                    onChange={e => setEntwurf(x => ({ ...x, [kv]: e.target.value.replace(/\D/g, '') }))} />
                  <span className="muted">bis</span>
                  <input inputMode="numeric" value={bisE} disabled={!stand} aria-label="bis" style={feld}
                    onChange={e => setEntwurf(x => ({ ...x, [kb]: e.target.value.replace(/\D/g, '') }))} />
                  <span className="muted">Min</span>
                  {(geaendert || unterwegs) && (
                    <button className="button" type="button" disabled={!gueltig || unterwegs}
                      style={{ marginLeft: 'auto', padding: '8px 12px', borderRadius: 10, border: 0, opacity: gueltig ? 1 : 0.5 }}
                      onClick={async () => { await senden(t.pfad, { von: v, bis: b }); setEntwurf(x => ohne(x, kv, kb)); }}>
                      {unterwegs ? '…' : 'Übernehmen'}
                    </button>
                  )}
                </div>
              </div>
            );
          })}

          {(() => {
            const pfad = 'bhwacht.prozent';
            const ist = stand?.werte?.[pfad];
            const istS = typeof ist === 'number' ? String(ist) : '';
            const e = entwurf[pfad] ?? istS;
            const n = Number(e);
            const gueltig = e !== '' && n >= 0 && n <= 100;
            const unterwegs = !!offenFuer(pfad);
            return (
              <div className="card" style={{ padding: 16 }}>
                <div style={{ fontWeight: 800 }}>Bauernhof-Wacht</div>
                <div className="muted" style={{ fontSize: 12, margin: '4px 0 10px' }}>
                  vorziehen unter … % freien Plätzen (Account-Manager: auf 5/10/15/20 gerundet)
                </div>
                <div className="field" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <input inputMode="numeric" value={e} disabled={!stand} aria-label="Prozent" style={feld}
                    onChange={x => setEntwurf(y => ({ ...y, [pfad]: x.target.value.replace(/\D/g, '') }))} />
                  <span className="muted">%</span>
                  {(e !== istS || unterwegs) && (
                    <button className="button" type="button" disabled={!gueltig || unterwegs}
                      style={{ marginLeft: 'auto', padding: '8px 12px', borderRadius: 10, border: 0, opacity: gueltig ? 1 : 0.5 }}
                      onClick={async () => { await senden(pfad, n); setEntwurf(y => ohne(y, pfad)); }}>
                      {unterwegs ? '…' : 'Übernehmen'}
                    </button>
                  )}
                </div>
              </div>
            );
          })()}
        </div>
      </section>

      {aktivitaet.length > 0 && (
        <section className="section card" style={{ padding: 16 }}>
          <div className="sectionhead"><h2>Letzte Aktivität</h2></div>
          <table className="table" style={{ width: '100%' }}>
            <tbody>
              {[...aktivitaet].reverse().slice(0, 12).map((a, i) => (
                <tr key={i}>
                  <td style={{ whiteSpace: 'nowrap' }}>{a.at ? uhr(a.at) : ''}</td>
                  <td>{a.art ?? ''}</td>
                  <td>{a.text ?? ''}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}
    </OdinShell>
  );
}
