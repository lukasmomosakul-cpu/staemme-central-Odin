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
