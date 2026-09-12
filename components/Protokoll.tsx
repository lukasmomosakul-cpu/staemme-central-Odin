'use client';

import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

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

const FARBE: Record<string, string> = {
  FEHLER: '#b42318',
  WICHTIG: '#b45309',
  info: '#667085',
};

export default function Protokoll({
  teamId,
  accountNamen = {},
  grenze = 40,
}: {
  teamId: string | null;
  accountNamen?: Record<string, string>;
  grenze?: number;
}) {
  const [eintraege, setEintraege] = useState<Ereignis[]>([]);
  const [nurFehler, setNurFehler] = useState(false);
  const [laedt, setLaedt] = useState(true);
  const [stand, setStand] = useState('');

  const laden = useCallback(async () => {
    if (!teamId || !supabase) { setLaedt(false); return; }
    try {
      let q = supabase
        .from('app_events')
        .select('id,level,bereich,message,device,app_version,created_at,account_id')
        .eq('team_id', teamId)
        .order('created_at', { ascending: false })
        .limit(grenze);
      if (nurFehler) q = q.eq('level', 'FEHLER');
      const { data } = await q;
      setEintraege((data ?? []) as Ereignis[]);
      setStand(new Date().toLocaleTimeString('de-DE'));
    } catch {
      // Ein fehlgeschlagener Abruf darf das Dashboard nicht blockieren.
    }
    setLaedt(false);
  }, [teamId, nurFehler, grenze]);

  useEffect(() => { laden(); }, [laden]);
  // Alle 30 s nachladen, damit man beim Beobachten nicht neu laden muss.
  useEffect(() => {
    const t = setInterval(laden, 30000);
    return () => clearInterval(t);
  }, [laden]);

  const zeit = (iso: string) =>
    new Date(iso).toLocaleString('de-DE', {
      day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit', second: '2-digit',
    });

  const fehlerAnzahl = eintraege.filter((e) => e.level === 'FEHLER').length;

  return (
    <section id="protokoll" className="section card">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, flexWrap: 'wrap' }}>
        <h2 style={{ margin: 0 }}>
          Protokoll{' '}
          {fehlerAnzahl > 0 && (
            <span style={{ color: FARBE.FEHLER, fontSize: 13 }}>· {fehlerAnzahl} Fehler</span>
          )}
        </h2>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <label style={{ fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
            <input type="checkbox" checked={nurFehler} onChange={(e) => setNurFehler(e.target.checked)} />
            nur Fehler
          </label>
          <button type="button" className="iconButton smallIcon" onClick={laden} title="Neu laden">↻</button>
        </div>
      </div>

      {laedt && <p className="muted">Lade…</p>}

      {!laedt && eintraege.length === 0 && (
        <p className="muted">
          Keine Einträge. Gemeldet werden nur auffällige Vorgänge – Fehler, Zugangssperre,
          Wecker. Routine bleibt auf dem Gerät.
        </p>
      )}

      {!laedt && eintraege.length > 0 && (
        <div style={{ maxHeight: 320, overflowY: 'auto', marginTop: 10 }}>
          {eintraege.map((e) => (
            <div key={e.id} style={{ padding: '7px 0', borderBottom: '1px solid rgba(0,0,0,.06)', fontSize: 13 }}>
              <div style={{ display: 'flex', gap: 8, alignItems: 'baseline', flexWrap: 'wrap' }}>
                <strong style={{ color: FARBE[e.level] ?? FARBE.info, fontSize: 11 }}>{e.level}</strong>
                <span className="muted" style={{ fontSize: 11 }}>{zeit(e.created_at)}</span>
                <span className="muted" style={{ fontSize: 11 }}>· {e.bereich}</span>
                {e.account_id && accountNamen[e.account_id] && (
                  <span className="muted" style={{ fontSize: 11 }}>· {accountNamen[e.account_id]}</span>
                )}
              </div>
              <div>{e.message}</div>
              {(e.device || e.app_version) && (
                <div className="muted" style={{ fontSize: 11 }}>
                  {e.device}{e.app_version ? ` · APK ${e.app_version}` : ''}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {stand && <div className="muted" style={{ fontSize: 11, marginTop: 8 }}>Stand: {stand}</div>}
    </section>
  );
}
