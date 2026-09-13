'use client';

import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';

type Ereignis = {
  id: string;
  level: string;
  bereich: string;
  message: string;
  device: string;
  app_version: string;
  created_at: string;
  account_id: string | null;
};

const FARBE: Record<string, string> = { FEHLER: '#b42318', WICHTIG: '#b45309', info: '#667085' };

// Obergrenze, damit die Seite bei langen Laeufen nicht unbrauchbar wird.
const GRENZE = 1000;

export default function ProtokollSeite() {
  const [eintraege, setEintraege] = useState<Ereignis[]>([]);
  const [namen, setNamen] = useState<Record<string, string>>({});
  const [stufe, setStufe] = useState('alle');
  const [bereich, setBereich] = useState('alle');
  const [suche, setSuche] = useState('');
  const [laedt, setLaedt] = useState(true);
  const [auto, setAuto] = useState(true);
  const [stand, setStand] = useState('');

  const laden = useCallback(async () => {
    if (!supabase) { setLaedt(false); return; }
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) { window.location.href = '/login/'; return; }
    try {
      const { data: accs } = await supabase.from('game_accounts').select('id,name');
      setNamen(Object.fromEntries(((accs ?? []) as { id: string; name: string }[]).map((a) => [a.id, a.name])));
      const { data } = await supabase
        .from('app_events')
        .select('id,level,bereich,message,device,app_version,created_at,account_id')
        .order('created_at', { ascending: false })
        .limit(GRENZE);
      setEintraege((data ?? []) as Ereignis[]);
      setStand(new Date().toLocaleTimeString('de-DE'));
    } catch { /* Abrufe duerfen die Seite nicht blockieren */ }
    setLaedt(false);
  }, []);

  useEffect(() => { laden(); }, [laden]);
  useEffect(() => {
    if (!auto) return;
    const t = setInterval(laden, 20000);
    return () => clearInterval(t);
  }, [auto, laden]);

  const gefiltert = eintraege.filter((e) =>
    (stufe === 'alle' || e.level === stufe) &&
    (bereich === 'alle' || e.bereich === bereich) &&
    (!suche || e.message.toLowerCase().includes(suche.toLowerCase())),
  );

  const bereiche = Array.from(new Set(eintraege.map((e) => e.bereich))).sort();

  const zeit = (iso: string) =>
    new Date(iso).toLocaleString('de-DE', {
      day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit',
    });

  const exportieren = (format: 'txt' | 'json') => {
    const inhalt = format === 'json'
      ? JSON.stringify(gefiltert, null, 2)
      : gefiltert
          .map((e) => `[${zeit(e.created_at)}] ${e.level} · ${e.bereich} · ${namen[e.account_id ?? ''] ?? '-'} · ${e.message} (${e.device}, APK ${e.app_version})`)
          .join('\n');
    const blob = new Blob([inhalt], { type: format === 'json' ? 'application/json' : 'text/plain' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `odin-protokoll-${new Date().toISOString().slice(0, 16).replace(/[:T]/g, '-')}.${format}`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  const kopieren = async () => {
    const text = gefiltert
      .map((e) => `[${zeit(e.created_at)}] ${e.level} · ${e.bereich} · ${e.message}`)
      .join('\n');
    try { await navigator.clipboard.writeText(text); } catch { /* ohne Berechtigung nicht moeglich */ }
  };

  const fehler = eintraege.filter((e) => e.level === 'FEHLER').length;

  return (
    <div className="shell">
      <main className="main" style={{ paddingBottom: 90 }}>
        <header className="top" style={{ position: 'sticky', top: 0, zIndex: 30, background: 'var(--bg,#fff)', borderBottom: '1px solid rgba(0,0,0,.08)', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h1 className="title" style={{ margin: 0 }}>Protokoll</h1>
          {fehler > 0 && <span style={{ color: FARBE.FEHLER, fontSize: 13 }}>{fehler} Fehler</span>}
        </header>

        <section className="section card">
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
            <select value={stufe} onChange={(e) => setStufe(e.target.value)} aria-label="Stufe">
              <option value="alle">alle Stufen</option>
              <option value="FEHLER">nur Fehler</option>
              <option value="WICHTIG">nur Wichtig</option>
              <option value="info">nur Info</option>
            </select>
            <select value={bereich} onChange={(e) => setBereich(e.target.value)} aria-label="Bereich">
              <option value="alle">alle Bereiche</option>
              {bereiche.map((b) => <option key={b} value={b}>{b}</option>)}
            </select>
            <input value={suche} onChange={(e) => setSuche(e.target.value)} placeholder="Text suchen" style={{ flex: '1 1 140px', minWidth: 120 }} />
          </div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center', marginTop: 10 }}>
            <button type="button" onClick={() => exportieren('txt')}>Export .txt</button>
            <button type="button" onClick={() => exportieren('json')}>Export .json</button>
            <button type="button" onClick={kopieren}>Kopieren</button>
            <button type="button" onClick={laden}>↻</button>
            <label style={{ fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
              <input type="checkbox" checked={auto} onChange={(e) => setAuto(e.target.checked)} />
              automatisch
            </label>
          </div>
          <div className="muted" style={{ fontSize: 11, marginTop: 8 }}>
            {gefiltert.length} von {eintraege.length} Einträgen (Obergrenze {GRENZE})
            {stand && ` · Stand ${stand}`}
          </div>
        </section>

        <section className="section card">
          {laedt && <p className="muted">Lade…</p>}
          {!laedt && gefiltert.length === 0 && <p className="muted">Keine Einträge.</p>}
          {gefiltert.map((e) => (
            <div key={e.id} style={{ padding: '7px 0', borderBottom: '1px solid rgba(0,0,0,.06)', fontSize: 13 }}>
              <div style={{ display: 'flex', gap: 8, alignItems: 'baseline', flexWrap: 'wrap' }}>
                <strong style={{ color: FARBE[e.level] ?? FARBE.info, fontSize: 11 }}>{e.level}</strong>
                <span className="muted" style={{ fontSize: 11 }}>{zeit(e.created_at)}</span>
                <span className="muted" style={{ fontSize: 11 }}>· {e.bereich}</span>
                {e.account_id && namen[e.account_id] && (
                  <span className="muted" style={{ fontSize: 11 }}>· {namen[e.account_id]}</span>
                )}
              </div>
              <div style={{ wordBreak: 'break-word' }}>{e.message}</div>
            </div>
          ))}
        </section>
      </main>

      <nav className="bottomNav" aria-label="Navigation">
        <a className="active" href="/protokoll/"><span>📋</span><span>Protokoll</span></a>
        <a href="/einstellungen/"><span>⚙</span><span>Einstellungen</span></a>
      </nav>
    </div>
  );
}
