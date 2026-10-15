'use client';

import { useState } from 'react';
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

export function TeamKennzahlen({ bilder, kontenGesamt, geraeteAktiv }:
  { bilder: KontoBild[]; kontenGesamt: number; geraeteAktiv: number }) {
  const arbeitet = bilder.filter(b => b.zustand === 'arbeitet').length;
  const botschutz = bilder.filter(b => b.zustand === 'botschutz').length;
  const punkte = bilder.reduce((s, b) => s + (b.stats?.points ?? 0), 0);
  const beute = bilder.reduce((s, b) => s + (b.stats?.loot_res ?? 0), 0);
  const doerfer = bilder.reduce((s, b) => s + b.doerfer.length, 0);
  const kacheln: { titel: string; wert: string; zusatz: string; ton?: string }[] = [
    { titel: 'GodBot aktiv', wert: `${arbeitet} / ${kontenGesamt}`, zusatz: `${geraeteAktiv} Gerät(e) verbunden` },
    { titel: 'Botschutz', wert: botschutz ? String(botschutz) : 'keiner', zusatz: botschutz ? 'Konto/Konten gesperrt' : 'alle Konten frei', ton: botschutz ? 'rot' : 'gruen' },
    { titel: 'Punkte', wert: zahl(punkte), zusatz: `${doerfer} Dorf/Dörfer` },
    { titel: 'Erfarmt', wert: zahl(beute), zusatz: 'Rohstoffe laut Rangliste' },
  ];
  return (
    <section className="dashKpis" aria-label="Team-Kennzahlen">
      {kacheln.map(k => (
        <div key={k.titel} className={`dashKpi ${k.ton ?? ''}`}>
          <div className="dashKpiTitel">{k.titel}</div>
          <div className="dashKpiWert">{k.wert}</div>
          <div className="dashKpiZusatz">{k.zusatz}</div>
        </div>
      ))}
    </section>
  );
}

const ART: Record<string, string> = { botschutz: 'Botschutz', attack: 'Angriff', farm: 'Farmen', bau: 'Bau',
  truppen: 'Truppen', raubzug: 'Raubzug', support: 'Unterstützung', rohstoffe: 'Rohstoffe' };
const artText = (a: string) => ART[a] ?? (a ? a[0].toUpperCase() + a.slice(1) : '');

function Zeile({ label, children }: { label: string; children: React.ReactNode }) {
  return <div className="accRow"><span className="accLabel">{label}</span><div>{children}</div></div>;
}

export function KontoDetails({ bild }: { bild: KontoBild }) {
  const [dorfOffen, setDorfOffen] = useState<string | null>(null);
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
            {bild.stats.at ? ` · Stand ${uhrzeit(bild.stats.at)}` : ''}</div>
        </Zeile>
      ) : null}

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
        <Zeile label="Zuletzt">
          {bild.aktivitaet.map((a, i) => <div key={i} className="dashGrund">
            <span className="muted">{uhrzeit(a.at)}</span> {a.art ? <b>{artText(a.art)}</b> : null} {a.text}</div>)}
        </Zeile>
      ) : null}
    </>
  );
}
