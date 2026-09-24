'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import OdinShell from '../../components/OdinShell';

// Die App liest genau diese Zeile im Dienst - deshalb die gleichen Namen.
type Nb = {
  vorwarnung_an: boolean; vorwarnung_min: number;
  angriffe_gebuendelt: boolean;
  botschutz_an: boolean; botschutz_vibration_sek: number; botschutz_wecker_min: number;
};
const NB_STANDARD: Nb = {
  vorwarnung_an: true, vorwarnung_min: 3,
  angriffe_gebuendelt: true,
  botschutz_an: true, botschutz_vibration_sek: 60, botschutz_wecker_min: 10,
};

export default function EinstellungenSeite() {
  const [email, setEmail] = useState('');
  const [team, setTeam] = useState('');
  const [teamId, setTeamId] = useState('');
  const [nb, setNb] = useState<Nb>(NB_STANDARD);
  const [nbMeldung, setNbMeldung] = useState('');

  useEffect(() => {
    (async () => {
      if (!supabase) return;
      const { data } = await supabase.auth.getUser();
      setEmail(data.user?.email ?? '');
      const { data: m } = await supabase.from('team_members').select('team_id,role').limit(1).maybeSingle();
      if (m) {
        const { data: t } = await supabase.from('teams').select('name').eq('id', m.team_id).maybeSingle();
        setTeam(`${t?.name ?? ''} · ${m.role ?? ''}`);
        setTeamId(m.team_id);
        const { data: n } = await supabase.from('notification_settings').select('*').eq('team_id', m.team_id).maybeSingle();
        if (n) setNb({ ...NB_STANDARD, ...n });
      }
    })();
  }, []);

  // Sofort speichern statt Speichern-Knopf: eine Einstellung, die man setzt
  // und die dann doch nicht gilt, weil man den Knopf vergessen hat, ist
  // schlimmer als gar keine.
  const nbSetzen = async (teil: Partial<Nb>) => {
    const neu = { ...nb, ...teil };
    setNb(neu);
    if (!supabase || !teamId) return;
    const { error } = await supabase.from('notification_settings')
      .upsert({ team_id: teamId, ...neu, updated_at: new Date().toISOString() });
    setNbMeldung(error ? (error.message || 'Speichern fehlgeschlagen.')
      : 'Gespeichert. Die App übernimmt es beim nächsten Abgleich (max. 5 Min).');
  };

  // Der Testknopf ruft denselben Weg auf, den eine echte GodBot-Meldung
  // nimmt. Er ist nur in der App da - im Browser gibt es keine Bruecke.
  const [testMeldung, setTestMeldung] = useState('');
  const botschutzTesten = () => {
    const br = (window as unknown as { Android?: { testBotschutz?: () => void } }).Android;
    if (!br?.testBotschutz) {
      setTestMeldung('Nur in der Odin-App möglich – im Browser fehlt die Brücke.');
      return;
    }
    br.testBotschutz();
    setTestMeldung('Ausgelöst. Sperr das Gerät: Vibration kommt binnen 30 Sekunden, '
      + `der Wecker nach ${nb.botschutz_wecker_min} Minuten. Ende, sobald du wieder hier bist.`);
  };

  // Testfassung "mehrere Welten gleichzeitig" - nur in der App.
  type Konto = { id: string; name: string | null; world: string | null };
  const [konten, setKonten] = useState<Konto[]>([]);
  const [wahl, setWahl] = useState<string[]>([]);
  const [ptMeldung, setPtMeldung] = useState('');
  useEffect(() => {
    (async () => {
      if (!supabase || !teamId) return;
      const { data } = await supabase.from('game_accounts').select('id,name,world').eq('team_id', teamId);
      setKonten((data ?? []) as Konto[]);
    })();
  }, [teamId]);
  const umschalten = (id: string) => setWahl(w => w.includes(id) ? w.filter(x => x !== id)
    : (w.length >= 3 ? w : [...w, id]));
  const parallelStarten = () => {
    const br = (window as unknown as { Android?: { parallelTest?: (j: string) => void } }).Android;
    if (!br?.parallelTest) { setPtMeldung('Nur in der Odin-App (ab 1.73) möglich.'); return; }
    const liste = konten.filter(k => wahl.includes(k.id));
    if (liste.length < 2) { setPtMeldung('Mindestens zwei Konten mit Welt auswählen.'); return; }
    br.parallelTest(JSON.stringify(liste));
    setPtMeldung('Gestartet. Protokoll: je Welt und Minute eine Zeile „Parallel …“.');
  };

  // Zuweisung Konto -> Geraet. Nur das zugewiesene Geraet meldet sich im Spiel
  // an und laesst GodBot laufen; es haelt die Zuweisung, solange es sich
  // mindestens alle 3 Minuten meldet.
  type Zuweisung = { account_id: string; geraet_id: string; geraet_name: string; gemeldet: string };
  const [zuw, setZuw] = useState<Zuweisung[]>([]);
  const [meinGeraet, setMeinGeraet] = useState('');
  const [zwMeldung, setZwMeldung] = useState('');
  const bruecke = () => (window as unknown as { Android?: {
    geraetId?: () => string; kontoHierherHolen?: (id: string) => void; kontoFreigeben?: (id: string) => void;
  } }).Android;
  const zuwLaden = async () => {
    if (!supabase || !teamId) return;
    const { data } = await supabase.from('account_leases').select('account_id,geraet_id,geraet_name,gemeldet').eq('team_id', teamId);
    setZuw((data ?? []) as Zuweisung[]);
  };
  useEffect(() => {
    try { setMeinGeraet(bruecke()?.geraetId?.() ?? ''); } catch { /* Browser */ }
    zuwLaden();
    const t = setInterval(zuwLaden, 20000);
    return () => clearInterval(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [teamId]);
  const zuwText = (id: string) => {
    const z = zuw.find(x => x.account_id === id);
    if (!z) return 'frei';
    const alter = Math.round((Date.now() - new Date(z.gemeldet).getTime()) / 60000);
    const wer = z.geraet_id === meinGeraet ? 'dieses Gerät' : (z.geraet_name || 'anderes Gerät');
    return alter >= 3 ? `frei (zuletzt ${wer}, vor ${alter} Min)` : `${wer} · aktiv`;
  };
  const hierher = (id: string) => {
    const br = bruecke();
    if (!br?.kontoHierherHolen) { setZwMeldung('Nur in der Odin-App möglich.'); return; }
    br.kontoHierherHolen(id);
    setZwMeldung('Wird übernommen. Das andere Gerät pausiert bei seiner nächsten Prüfung (spätestens 1 Min).');
    setTimeout(zuwLaden, 3000);
  };
  const freigeben = (id: string) => {
    const br = bruecke();
    if (!br?.kontoFreigeben) { setZwMeldung('Nur in der Odin-App möglich.'); return; }
    br.kontoFreigeben(id);
    setZwMeldung('Freigegeben. Solange die Spielansicht hier offen ist, holt dieses Gerät das Konto sich wieder.');
    setTimeout(zuwLaden, 3000);
  };

  const abmelden = async () => {
    await supabase?.auth.signOut();
    window.location.href = '/login/';
  };

  return (
    <OdinShell titel="Einstellungen" aktiv="Einstellungen">
      <section className="section card">
        <h2>Konto</h2>
        <div className="muted">{email || 'nicht angemeldet'}</div>
        {team && <div className="muted" style={{ marginTop: 4 }}>{team}</div>}
        <div style={{ marginTop: 12 }}>
          <button type="button" onClick={abmelden}>Abmelden</button>
        </div>
      </section>

      <section className="section card">
        <h2>Benachrichtigungen</h2>

        <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <input type="checkbox" checked={nb.vorwarnung_an}
                 onChange={e => nbSetzen({ vorwarnung_an: e.target.checked })} />
          <span>Vorwarnung vor Terminen</span>
        </label>
        <div className="muted" style={{ marginLeft: 26 }}>
          Meldet sich, wenn ein Termin ansteht und Odin gerade gedrosselt läuft.
        </div>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6, marginLeft: 26 }}>
          <span>Vorlauf</span>
          <input type="number" min={1} max={60} value={nb.vorwarnung_min} style={{ width: 70 }}
                 onChange={e => nbSetzen({ vorwarnung_min: Number(e.target.value) || 1 })} />
          <span className="muted">Minuten</span>
        </label>

        <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 14 }}>
          <input type="checkbox" checked={nb.angriffe_gebuendelt}
                 onChange={e => nbSetzen({ angriffe_gebuendelt: e.target.checked })} />
          <span>Angriffe in einer Meldung bündeln</span>
        </label>
        <div className="muted" style={{ marginLeft: 26 }}>
          Aus: jeder Angriff eine eigene Meldung.
        </div>

        <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 14 }}>
          <input type="checkbox" checked={nb.botschutz_an}
                 onChange={e => nbSetzen({ botschutz_an: e.target.checked })} />
          <span>Botschutz: vibrieren und wecken</span>
        </label>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6, marginLeft: 26 }}>
          <span>Vibration alle</span>
          <input type="number" min={10} max={3600} value={nb.botschutz_vibration_sek} style={{ width: 80 }}
                 onChange={e => nbSetzen({ botschutz_vibration_sek: Number(e.target.value) || 60 })} />
          <span className="muted">Sekunden</span>
        </label>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6, marginLeft: 26 }}>
          <span>Wecker nach</span>
          <input type="number" min={1} max={120} value={nb.botschutz_wecker_min} style={{ width: 80 }}
                 onChange={e => nbSetzen({ botschutz_wecker_min: Number(e.target.value) || 10 })} />
          <span className="muted">Minuten</span>
        </label>
        <div className="muted" style={{ marginLeft: 26 }}>
          Endet, sobald du das Dashboard oder die Spielansicht öffnest.
        </div>

        <div style={{ marginTop: 14, marginLeft: 26 }}>
          <button type="button" onClick={botschutzTesten}>Botschutz-Alarm testen</button>
        </div>
        {testMeldung && <div className="muted" style={{ marginTop: 8, marginLeft: 26 }}>{testMeldung}</div>}

        {nbMeldung && <div className="muted" style={{ marginTop: 10 }}>{nbMeldung}</div>}
      </section>

      <section className="section card">
        <h2>Geräte-Zuweisung</h2>
        <div className="muted">
          Jedes Konto wird von genau einem Gerät gespielt: nur dieses meldet sich im Spiel an und
          lässt GodBot laufen. Andere Geräte zeigen die Welt, pausieren aber. So werfen sich zwei
          Geräte nicht gegenseitig aus dem Spiel.
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, marginTop: 10 }}>
          {konten.map(k => {
            const z = zuw.find(x => x.account_id === k.id);
            const meins = z?.geraet_id === meinGeraet;
            return (
              <div key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
                <span>{k.name || k.id.slice(0, 8)}</span>
                <span className="muted">{k.world || '–'}</span>
                <span className="muted">· {zuwText(k.id)}</span>
                {!meins && <button type="button" onClick={() => hierher(k.id)}>Hierher holen</button>}
                {meins && <button type="button" onClick={() => freigeben(k.id)}>Freigeben</button>}
              </div>
            );
          })}
          {!konten.length && <div className="muted">Keine Konten gefunden.</div>}
        </div>
        {zwMeldung && <div className="muted" style={{ marginTop: 8 }}>{zwMeldung}</div>}
      </section>

      <section className="section card">
        <h2>Mehrere Welten gleichzeitig – Test</h2>
        <div className="muted">
          Öffnet 2–3 Konten nebeneinander in einer Ansicht, noch ohne GodBot. Jede Welt meldet
          jede Minute, ob ihr Zeitgeber ungedrosselt läuft („Takt 60/60“), wie viel Speicher sie
          braucht und ob sie angemeldet ist. Welten mit demselben Stämme-Login teilen sich
          dabei eine Anmeldung. Vorher die Spielansichten dieser Konten schließen.
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginTop: 10 }}>
          {konten.map(k => (
            <label key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <input type="checkbox" checked={wahl.includes(k.id)} disabled={!k.world}
                     onChange={() => umschalten(k.id)} />
              <span>{k.name || k.id.slice(0, 8)}</span>
              <span className="muted">{k.world || 'keine Welt eingetragen'}</span>
            </label>
          ))}
          {!konten.length && <div className="muted">Keine Konten gefunden.</div>}
        </div>
        <div style={{ marginTop: 10 }}>
          <button type="button" onClick={parallelStarten}>Test starten</button>
        </div>
        {ptMeldung && <div className="muted" style={{ marginTop: 8 }}>{ptMeldung}</div>}
      </section>

      <section className="section card">
        <h2>Bereiche</h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <a href="/">Dashboard und Accounts</a>
          <a href="/godbot/">GodBot-Übersicht</a>
          <a href="/team/">Team</a>
          <a href="/scripts/">Scripts</a>
        </div>
      </section>
    </OdinShell>
  );
}
