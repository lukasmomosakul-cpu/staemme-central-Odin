'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { supabase } from '../../lib/supabase';
import OdinShell from '../../components/OdinShell';

// Vorlagensammlung (04.10.2026).
//
// Bauvorlagen fuer alle Konten an einem Ort (Supabase bau_vorlagen).
// "Fuer alle" = team_id leer: jeder Odin-Nutzer sieht sie; aendern darf nur,
// wer sie angelegt hat. "Nur Team" = sichtbar und aenderbar fuer das Team.
// Ein Konto bekommt eine Vorlage als App-Befehl bauvorlage.uebernehmen
// ({name, queue, zuweisen}); GodBot legt sie an bzw. ersetzt sie gleichen
// Namens und weist sie zu. Der Befehl gilt 7 Tage, er erreicht also auch
// ein Konto, dessen Spielansicht gerade ruht.

type Vorlage = {
  id: string; team_id: string | null; name: string; beschreibung: string; welt: string | null;
  queue: string; erstellt_von: string | null; geaendert_at: string;
};
type Konto = { id: string; name: string | null; world: string | null; team_id: string };
type Team = { id: string; name: string };
type Versand = { id: number; konto: string; vorlage: string; erledigt?: boolean; ok?: boolean | null; ergebnis?: string | null };

// Gebaeude-IDs wie in GodBot (BAU_NAMEN).
const NAMEN: Record<string, string> = {
  main: 'Hauptgebäude', barracks: 'Kaserne', stable: 'Stall', garage: 'Werkstatt', church: 'Kirche',
  church_f: 'Erste Kirche', watchtower: 'Wachturm', snob: 'Adelshof', smith: 'Schmiede', place: 'Versammlungsplatz',
  statue: 'Statue', market: 'Marktplatz', wood: 'Holzfällerlager', stone: 'Lehmgrube', iron: 'Eisenmine',
  farm: 'Bauernhof', storage: 'Speicher', hide: 'Versteck', wall: 'Wall',
};
const KURZ: Record<string, string> = {
  main: 'HG', barracks: 'Kaserne', stable: 'Stall', garage: 'Werkstatt', church: 'Kirche', church_f: '1. Kirche',
  watchtower: 'Wachturm', snob: 'Adelshof', smith: 'Schmiede', place: 'VP', statue: 'Statue', market: 'Markt',
  wood: 'Holz', stone: 'Lehm', iron: 'Eisen', farm: 'Hof', storage: 'Speicher', hide: 'Versteck', wall: 'Wall',
};

// Prueft die Kette und rechnet die Endstufen aus - dieselben Regeln wie
// GodBot (bauVorlageAusSammlung), damit nichts gesendet wird, was dort
// abgelehnt wuerde.
function pruefen(queue: string): { fehler: string | null; schritte: number; end: Record<string, number> } {
  const teile = queue.replace(/\s+/g, '').split(';').filter(Boolean);
  const end: Record<string, number> = {};
  let schritte = 0;
  if (!teile.length) return { fehler: 'Vorlage ist leer', schritte: 0, end };
  for (const t of teile) {
    const m = t.match(/^([a-z_]+):(\d{1,2})$/);
    if (!m) return { fehler: `ungültiger Eintrag „${t.slice(0, 30)}“ (Form gebaeude:stufen)`, schritte, end };
    if (!NAMEN[m[1]]) return { fehler: `unbekanntes Gebäude „${m[1]}“`, schritte, end };
    const n = Number(m[2]);
    if (n < 1) return { fehler: `„${t}“: mindestens 1 Stufe`, schritte, end };
    end[m[1]] = (end[m[1]] ?? 0) + n;
    schritte += n;
  }
  const hoch = Object.keys(end).filter(g => end[g] > 30);
  if (hoch.length) return { fehler: `Endstufe über 30: ${hoch.map(g => KURZ[g]).join(', ')}`, schritte, end };
  return { fehler: null, schritte, end };
}

const endText = (end: Record<string, number>) =>
  Object.keys(NAMEN).filter(g => end[g]).map(g => `${KURZ[g]} ${end[g]}`).join(' · ');

const leer = { id: '', name: '', welt: '', beschreibung: '', queue: '', freigabe: 'alle' };

export default function VorlagenSeite() {
  const [ich, setIch] = useState('');
  const [vorlagen, setVorlagen] = useState<Vorlage[]>([]);
  const [konten, setKonten] = useState<Konto[]>([]);
  const [teams, setTeams] = useState<Team[]>([]);
  const [laedt, setLaedt] = useState(true);
  const [offen, setOffen] = useState<string | null>(null);
  const [auswahl, setAuswahl] = useState<Record<string, boolean>>({});
  const [zuweisen, setZuweisen] = useState('frei');
  const [form, setForm] = useState<typeof leer | null>(null);
  const [versand, setVersand] = useState<Versand[]>([]);
  const [meldung, setMeldung] = useState<{ text: string; gut: boolean } | null>(null);
  const versandRef = useRef<Versand[]>([]);
  versandRef.current = versand;

  const laden = useCallback(async () => {
    if (!supabase) { setLaedt(false); return; }
    const { data: u } = await supabase.auth.getUser();
    if (!u.user) { window.location.href = '/login/'; return; }
    setIch(u.user.id);
    const [v, k, t] = await Promise.all([
      supabase.from('bau_vorlagen').select('id,team_id,name,beschreibung,welt,queue,erstellt_von,geaendert_at').order('name'),
      supabase.from('game_accounts').select('id,name,world,team_id').order('name'),
      supabase.from('teams').select('id,name').order('name'),
    ]);
    setVorlagen((v.data ?? []) as Vorlage[]);
    setKonten((k.data ?? []) as Konto[]);
    setTeams((t.data ?? []) as Team[]);
    setLaedt(false);
  }, []);

  useEffect(() => { laden(); }, [laden]);

  // Gesendete Befehle verfolgen, bis GodBot sie bestaetigt hat.
  useEffect(() => {
    const t = setInterval(async () => {
      const o = versandRef.current.filter(x => !x.erledigt);
      if (!o.length || !supabase) return;
      const { data } = await supabase.from('godbot_befehle').select('id,ok,ergebnis,erledigt_at').in('id', o.map(x => x.id));
      const fertig = ((data ?? []) as { id: number; ok: boolean | null; ergebnis: string | null; erledigt_at: string | null }[])
        .filter(r => r.erledigt_at);
      if (!fertig.length) return;
      setVersand(vs => vs.map(x => {
        const f = fertig.find(r => r.id === x.id);
        return f ? { ...x, erledigt: true, ok: f.ok, ergebnis: f.ergebnis } : x;
      }));
    }, 3000);
    return () => clearInterval(t);
  }, []);

  useEffect(() => {
    if (!meldung) return;
    const t = setTimeout(() => setMeldung(null), meldung.gut ? 3000 : 8000);
    return () => clearTimeout(t);
  }, [meldung]);

  const darfAendern = (v: Vorlage) => v.team_id ? teams.some(t => t.id === v.team_id) : v.erstellt_von === ich;

  const senden = async (v: Vorlage) => {
    if (!supabase) return;
    const ziele = konten.filter(k => auswahl[k.id]);
    if (!ziele.length) { setMeldung({ text: 'Kein Konto ausgewählt', gut: false }); return; }
    const zeilen = ziele.map(k => ({
      team_id: k.team_id, account_id: k.id, pfad: 'bauvorlage.uebernehmen',
      wert: { name: v.name, queue: v.queue, zuweisen },
    }));
    const { data, error } = await supabase.from('godbot_befehle').insert(zeilen).select('id,account_id');
    if (error || !data) { setMeldung({ text: `Senden fehlgeschlagen: ${error?.message ?? '?'}`, gut: false }); return; }
    const neu = (data as { id: number; account_id: string }[]).map(r => {
      const k = konten.find(x => x.id === r.account_id);
      return { id: r.id, konto: `${k?.name ?? r.account_id.slice(0, 8)} · ${k?.world ?? '–'}`, vorlage: v.name };
    });
    setVersand(vs => [...neu, ...vs].slice(0, 30));
    setMeldung({ text: `An ${neu.length} Konto/Konten gesendet – GodBot übernimmt beim nächsten Abholen`, gut: true });
    setAuswahl({});
  };

  const speichern = async () => {
    if (!supabase || !form) return;
    const queue = form.queue.replace(/\s+/g, '');
    const p = pruefen(queue);
    if (p.fehler) { setMeldung({ text: p.fehler, gut: false }); return; }
    if (!form.name.trim()) { setMeldung({ text: 'Name fehlt', gut: false }); return; }
    const satz = {
      name: form.name.trim().slice(0, 60), welt: form.welt.trim() || null, beschreibung: form.beschreibung.trim(),
      queue, team_id: form.freigabe === 'alle' ? null : form.freigabe,
    };
    const r = form.id
      ? await supabase.from('bau_vorlagen').update(satz).eq('id', form.id)
      : await supabase.from('bau_vorlagen').insert(satz);
    if (r.error) {
      const doppelt = /duplicate|unique/i.test(r.error.message);
      setMeldung({ text: doppelt ? 'Name ist schon vergeben' : `Speichern fehlgeschlagen: ${r.error.message}`, gut: false });
      return;
    }
    setMeldung({ text: form.id ? 'Vorlage gespeichert' : 'Vorlage angelegt', gut: true });
    setForm(null);
    laden();
  };

  const loeschen = async (v: Vorlage) => {
    if (!supabase || !confirm(`Vorlage „${v.name}“ aus der Sammlung löschen? In den Konten bleibt sie erhalten.`)) return;
    const { error } = await supabase.from('bau_vorlagen').delete().eq('id', v.id);
    if (error) { setMeldung({ text: `Löschen fehlgeschlagen: ${error.message}`, gut: false }); return; }
    setOffen(null); laden();
  };

  const formPruef = form ? pruefen(form.queue) : null;
  const feldStil = { width: '100%', padding: '8px 10px', borderRadius: 10, border: '1px solid var(--odin-border)', boxSizing: 'border-box' } as const;

  return (
    <OdinShell titel="Vorlagen" aktiv="Vorlagen">
      {meldung && (
        <div className="toast" style={{
          position: 'sticky', top: 70, zIndex: 20, padding: '10px 14px', borderRadius: 12, marginBottom: 12,
          color: meldung.gut ? '#287a4b' : '#a63f3f', fontWeight: 700,
        }}>{meldung.gut ? '✓ ' : '✗ '}{meldung.text}</div>
      )}

      <section className="section" style={{ marginBottom: 20 }}>
        <div className="sectionhead" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10 }}>
          <h2>Bauvorlagen</h2>
          {!form && (
            <button className="button" type="button" style={{ padding: '8px 12px', borderRadius: 10, border: 0 }}
              onClick={() => setForm({ ...leer })}>+ Neue Vorlage</button>
          )}
        </div>
        <div className="muted" style={{ fontSize: 12, marginBottom: 12 }}>
          Gemeinsame Sammlung für alle Konten. „Senden“ legt die Vorlage im Konto an (gleicher Name wird ersetzt)
          und weist sie den Dörfern zu. Format: <code>gebaeude:stufen;…</code>, Stufen relativ ab 0.
        </div>

        {form && (
          <div className="card" style={{ padding: 16, marginBottom: 14 }}>
            <div style={{ fontWeight: 800, marginBottom: 10 }}>{form.id ? 'Vorlage bearbeiten' : 'Neue Vorlage'}</div>
            <div style={{ display: 'grid', gap: 10 }}>
              <label>Name<input value={form.name} maxLength={60} style={feldStil}
                onChange={e => setForm({ ...form, name: e.target.value })} /></label>
              <label>Welt (optional, z. B. de260)<input value={form.welt} style={feldStil}
                onChange={e => setForm({ ...form, welt: e.target.value })} /></label>
              <label>Beschreibung<textarea value={form.beschreibung} rows={3} style={feldStil}
                onChange={e => setForm({ ...form, beschreibung: e.target.value })} /></label>
              <label>Bauauftrag-Kette<textarea value={form.queue} rows={5} style={{ ...feldStil, fontFamily: 'monospace', fontSize: 12 }}
                onChange={e => setForm({ ...form, queue: e.target.value })} placeholder="main:1;farm:1;storage:1;wood:1;…" /></label>
              {form.queue && formPruef && (
                <div style={{ fontSize: 12, color: formPruef.fehler ? '#a63f3f' : '#287a4b', fontWeight: 700 }}>
                  {formPruef.fehler ?? `${formPruef.schritte} Stufen · ${endText(formPruef.end)}`}
                </div>
              )}
              <label>Sichtbar für
                <select value={form.freigabe} style={feldStil} onChange={e => setForm({ ...form, freigabe: e.target.value })}>
                  <option value="alle">Alle Odin-Nutzer</option>
                  {teams.map(t => <option key={t.id} value={t.id}>Nur Team {t.name}</option>)}
                </select>
              </label>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="button" type="button" disabled={!!formPruef?.fehler || !form.name.trim()}
                  style={{ padding: '8px 14px', borderRadius: 10, border: 0, opacity: formPruef?.fehler || !form.name.trim() ? 0.5 : 1 }}
                  onClick={speichern}>Speichern</button>
                <button type="button" style={{ padding: '8px 14px', borderRadius: 10, border: '1px solid var(--odin-border)', background: 'transparent' }}
                  onClick={() => setForm(null)}>Abbrechen</button>
              </div>
            </div>
          </div>
        )}

        {laedt ? <div className="muted">lädt …</div> : !vorlagen.length ? (
          <div className="muted">Noch keine Vorlagen.</div>
        ) : (
          <div style={{ display: 'grid', gap: 12 }}>
            {vorlagen.map(v => {
              const p = pruefen(v.queue);
              const auf = offen === v.id;
              return (
                <div key={v.id} className="card" style={{ padding: 16 }}>
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer' }}
                    onClick={() => { setOffen(auf ? null : v.id); setAuswahl({}); }}>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 800, fontSize: 15 }}>{v.name}</div>
                      <div className="muted" style={{ fontSize: 12, marginTop: 4 }}>
                        {v.welt ? `${v.welt} · ` : ''}{v.team_id ? 'Team' : 'für alle'} · {p.schritte} Stufen
                      </div>
                      <div style={{ fontSize: 12, marginTop: 4 }}>{endText(p.end)}</div>
                    </div>
                    <span className="muted">{auf ? '▲' : '▼'}</span>
                  </div>

                  {auf && (
                    <div style={{ marginTop: 12 }}>
                      {v.beschreibung && <div style={{ fontSize: 13, marginBottom: 10, whiteSpace: 'pre-wrap' }}>{v.beschreibung}</div>}
                      <div style={{ fontFamily: 'monospace', fontSize: 11, wordBreak: 'break-all', padding: 10, borderRadius: 10,
                        background: 'rgba(0,0,0,.04)', marginBottom: 8 }}>{v.queue}</div>
                      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 14 }}>
                        <button type="button" style={{ padding: '6px 10px', borderRadius: 10, border: '1px solid var(--odin-border)', background: 'transparent' }}
                          onClick={() => navigator.clipboard?.writeText(v.queue).then(() => setMeldung({ text: 'Kette kopiert', gut: true }))}>Kette kopieren</button>
                        {darfAendern(v) && (
                          <>
                            <button type="button" style={{ padding: '6px 10px', borderRadius: 10, border: '1px solid var(--odin-border)', background: 'transparent' }}
                              onClick={() => setForm({ id: v.id, name: v.name, welt: v.welt ?? '', beschreibung: v.beschreibung, queue: v.queue, freigabe: v.team_id ?? 'alle' })}>Bearbeiten</button>
                            <button type="button" style={{ padding: '6px 10px', borderRadius: 10, border: '1px solid #e2b4b4', color: '#a63f3f', background: 'transparent' }}
                              onClick={() => loeschen(v)}>Löschen</button>
                          </>
                        )}
                      </div>

                      <div style={{ fontWeight: 800, marginBottom: 6 }}>An Konten senden</div>
                      {!konten.length ? <div className="muted">Keine Konten.</div> : (
                        <div style={{ display: 'grid', gap: 6, marginBottom: 10 }}>
                          {konten.map(k => (
                            <label key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <input type="checkbox" checked={!!auswahl[k.id]}
                                onChange={e => setAuswahl(a => ({ ...a, [k.id]: e.target.checked }))} />
                              {k.name ?? k.id.slice(0, 8)} · {k.world ?? '–'}
                              {v.welt && k.world && v.welt !== k.world && <span className="muted" style={{ fontSize: 11 }}>(andere Welt)</span>}
                            </label>
                          ))}
                        </div>
                      )}
                      <label style={{ display: 'block', marginBottom: 10 }}>Zuweisen
                        <select value={zuweisen} style={feldStil} onChange={e => setZuweisen(e.target.value)}>
                          <option value="frei">Dörfern ohne Vorlage</option>
                          <option value="alle">Allen Dörfern (ersetzt bestehende Zuweisung)</option>
                          <option value="keine">Nur anlegen, nicht zuweisen</option>
                        </select>
                      </label>
                      <button className="button" type="button" disabled={!konten.some(k => auswahl[k.id])}
                        style={{ padding: '8px 14px', borderRadius: 10, border: 0, opacity: konten.some(k => auswahl[k.id]) ? 1 : 0.5 }}
                        onClick={() => senden(v)}>Senden</button>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </section>

      {versand.length > 0 && (
        <section className="section card" style={{ padding: 16 }}>
          <div className="sectionhead"><h2>Gesendet</h2></div>
          <table className="table" style={{ width: '100%' }}>
            <tbody>
              {versand.map(x => (
                <tr key={x.id}>
                  <td>{x.vorlage}</td>
                  <td>{x.konto}</td>
                  <td style={{ color: !x.erledigt ? '#b98f48' : x.ok ? '#287a4b' : '#a63f3f', fontWeight: 700 }}>
                    {!x.erledigt ? 'wartet auf GodBot …' : x.ok ? '✓ übernommen' : '✗ abgelehnt'}
                    {x.ergebnis ? <div className="muted" style={{ fontWeight: 400, fontSize: 12 }}>{x.ergebnis}</div> : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}
    </OdinShell>
  );
}
