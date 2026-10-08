'use client';

import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import OdinShell from '../../components/OdinShell';

// IP-Waechter (08.10.2026, Migration 031). Zeigt je Konto den letzten
// Pruefstand der Geraete-Sperre: Geraet, Weg (Proxy/direkt), IP, letzte
// Pruefung, Befund und WebRTC. Die Warnungen werden hier aus denselben Daten
// berechnet - sie ersetzen die Pruefung in der Datenbank nicht, sie machen
// sichtbar, ob sie laeuft. Zugangsdaten der Proxys werden nie angezeigt.

type Konto = { id: string; name: string; world: string | null; proxy: string | null };
type Sperre = {
  account_id: string; geraet_name: string | null; gemeldet: string | null;
  ip: string | null; ip_konflikt_at: string | null; ip_pruef_at: string | null;
  ip_befund: string | null; ip_weg: string | null; rtc_befund: string | null; rtc_at: string | null;
};
type Ereignis = { id: string; level: string; message: string; device: string; created_at: string; account_id: string | null };

const ROT = '#b42318', GELB = '#b45309', GRUEN = '#027a48', GRAU = '#667085';
const MIN = 60_000;

const welt = (w: string | null) => {
  const x = (w ?? '').toLowerCase().replace(/[^a-z0-9]/g, '');
  return /^[0-9]+$/.test(x) ? 'de' + x : x;
};
const alter = (iso: string | null) => (iso ? Date.now() - new Date(iso).getTime() : Infinity);
const alterText = (iso: string | null) => {
  const a = alter(iso);
  if (a === Infinity) return 'nie';
  if (a < MIN) return 'gerade eben';
  if (a < 60 * MIN) return `vor ${Math.round(a / MIN)} Min`;
  if (a < 48 * 60 * MIN) return `vor ${Math.round(a / (60 * MIN))} Std`;
  return `vor ${Math.round(a / (24 * 60 * MIN))} Tagen`;
};

type Zeile = { k: Konto; s: Sperre | null; aktiv: boolean; proxy: boolean; warn: { farbe: string; text: string }[] };

export default function IpWaechterSeite() {
  const [zeilen, setZeilen] = useState<Zeile[]>([]);
  const [ereignisse, setEreignisse] = useState<Ereignis[]>([]);
  const [namen, setNamen] = useState<Record<string, string>>({});
  const [laedt, setLaedt] = useState(true);
  const [stand, setStand] = useState('');

  const laden = useCallback(async () => {
    if (!supabase) { setLaedt(false); return; }
    const { data: user } = await supabase.auth.getUser();
    if (!user.user) { window.location.href = '/login/'; return; }
    try {
      const [{ data: accs }, { data: leases }, { data: ev }] = await Promise.all([
        supabase.from('game_accounts').select('id,name,world,proxy'),
        supabase.from('account_leases').select('account_id,geraet_name,gemeldet,ip,ip_konflikt_at,ip_pruef_at,ip_befund,ip_weg,rtc_befund,rtc_at'),
        supabase.from('app_events').select('id,level,message,device,created_at,account_id')
          .like('bereich', 'ip%').order('created_at', { ascending: false }).limit(60),
      ]);
      const konten = (accs ?? []) as Konto[];
      const sperren = new Map(((leases ?? []) as Sperre[]).map((l) => [l.account_id, l]));
      setNamen(Object.fromEntries(konten.map((k) => [k.id, k.name])));

      const basis = konten.map((k) => {
        const s = sperren.get(k.id) ?? null;
        return { k, s, aktiv: !!s && alter(s.gemeldet) < 3 * MIN, proxy: !!(k.proxy ?? '').trim(), warn: [] as Zeile['warn'] };
      });
      const aktive = basis.filter((z) => z.aktiv && z.s?.ip);
      basis.forEach((z) => {
        if (!z.aktiv || !z.s) return;
        const s = z.s;
        if (s.ip_konflikt_at && alter(s.ip_konflikt_at) < 15 * MIN) z.warn.push({ farbe: ROT, text: 'IP-Konflikt – Konto angehalten' });
        if (s.ip) {
          const doppelt = aktive.find((o) => o !== z && o.s!.ip === s.ip
            && o.k.name.trim().toLowerCase() !== z.k.name.trim().toLowerCase()
            && (!welt(o.k.world) || !welt(z.k.world) || welt(o.k.world) === welt(z.k.world)));
          if (doppelt) z.warn.push({ farbe: ROT, text: `gleiche IP wie ${doppelt.k.name} auf derselben Welt` });
          if (z.proxy) {
            const direkt = aktive.find((o) => o !== z && !o.proxy && o.s!.ip === s.ip);
            if (direkt) z.warn.push({ farbe: ROT, text: `Proxy-IP = Geräte-IP von ${direkt.k.name} – Proxy wirkt nicht` });
          }
        }
        // App prueft alle 10 Min, Odin PC jede Minute.
        if (alter(s.ip_pruef_at) > 15 * MIN) z.warn.push({ farbe: GELB, text: 'IP-Prüfung überfällig' });
        if (z.proxy) {
          if (!s.rtc_at) z.warn.push({ farbe: GELB, text: 'WebRTC nicht geprüft' });
          else if (!/^ok/.test(s.rtc_befund ?? '')) z.warn.push({ farbe: ROT, text: 'WebRTC verrät IP' });
        }
      });
      basis.sort((a, b) => Number(b.aktiv) - Number(a.aktiv) || b.warn.length - a.warn.length || a.k.name.localeCompare(b.k.name));
      setZeilen(basis);
      setEreignisse((ev ?? []) as Ereignis[]);
      setStand(new Date().toLocaleTimeString('de-DE'));
    } catch { /* Abrufe duerfen die Seite nicht blockieren */ }
    setLaedt(false);
  }, []);

  useEffect(() => { laden(); }, [laden]);
  useEffect(() => { const t = setInterval(laden, 30000); return () => clearInterval(t); }, [laden]);

  const rot = zeilen.filter((z) => z.warn.some((w) => w.farbe === ROT)).length;
  const gelb = zeilen.filter((z) => !z.warn.some((w) => w.farbe === ROT) && z.warn.length).length;
  const zeit = (iso: string) => new Date(iso).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });

  return (
    <OdinShell
      titel="IP-Wächter"
      aktiv="IP-Wächter"
      rechts={<span style={{ fontSize: 13, color: rot ? ROT : gelb ? GELB : GRUEN }}>
        {rot ? `${rot} kritisch` : gelb ? `${gelb} Hinweis(e)` : 'alles ok'}</span>}
    >
      <section className="section card">
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
          <button type="button" onClick={laden}>↻</button>
          <span className="muted" style={{ fontSize: 12 }}>
            aktiv = Geräte-Sperre in den letzten 3 Min gemeldet{stand && ` · Stand ${stand}`}
          </span>
        </div>
      </section>

      <section className="section card">
        {laedt && <p className="muted">Lade…</p>}
        {zeilen.map((z) => (
          <div key={z.k.id} style={{ padding: '9px 0', borderBottom: '1px solid rgba(0,0,0,.06)', fontSize: 13, opacity: z.aktiv ? 1 : 0.55 }}>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'baseline' }}>
              <strong>{z.k.name}</strong>
              <span className="muted">{welt(z.k.world) || '?'}</span>
              <span style={{ fontSize: 11, color: z.proxy ? GRUEN : GRAU }}>{z.proxy ? 'Proxy' : 'direkt'}</span>
              {!z.aktiv && <span className="muted" style={{ fontSize: 11 }}>· läuft nicht</span>}
            </div>
            {z.s && (
              <div className="muted" style={{ fontSize: 12, marginTop: 2 }}>
                {z.s.geraet_name || 'Gerät ?'} · IP {z.s.ip ?? '–'} · geprüft {alterText(z.s.ip_pruef_at)}
                {z.proxy && ` · WebRTC ${z.s.rtc_at ? (/^ok/.test(z.s.rtc_befund ?? '') ? 'dicht' : 'LECK') + ' (' + alterText(z.s.rtc_at) + ')' : 'ungeprüft'}`}
              </div>
            )}
            {z.s?.ip_befund && z.s.ip_befund !== 'ok' && (
              <div style={{ fontSize: 12, color: ROT, marginTop: 2 }}>{z.s.ip_befund}</div>
            )}
            {z.warn.map((w) => (
              <div key={w.text} style={{ fontSize: 12, color: w.farbe, marginTop: 2 }}>{w.farbe === ROT ? '⛔' : '⚠'} {w.text}</div>
            ))}
            {z.aktiv && !z.warn.length && <div style={{ fontSize: 12, color: GRUEN, marginTop: 2 }}>✓ geprüft, kein Konflikt</div>}
          </div>
        ))}
      </section>

      <section className="section card">
        <h3 style={{ marginTop: 0 }}>Letzte IP-Ereignisse</h3>
        {!ereignisse.length && <p className="muted">Noch keine Einträge im Bereich „ip“.</p>}
        {ereignisse.map((e) => (
          <div key={e.id} style={{ padding: '6px 0', borderBottom: '1px solid rgba(0,0,0,.06)', fontSize: 12 }}>
            <span style={{ color: e.level === 'FEHLER' ? ROT : e.level === 'WICHTIG' ? GELB : GRAU, fontWeight: 600 }}>{e.level}</span>
            <span className="muted"> {zeit(e.created_at)} · {namen[e.account_id ?? ''] ?? '-'} · {e.device}</span>
            <div style={{ wordBreak: 'break-word' }}>{e.message}</div>
          </div>
        ))}
      </section>
    </OdinShell>
  );
}
