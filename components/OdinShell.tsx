'use client';

import { type ReactNode, useState } from 'react';
import VersionUpdater from './VersionUpdater';

// Gemeinsames Geruest fuer alle Seiten. Vorher hatte jede Seite ihr eigenes
// Layout, wodurch Kopfzeile, Seitenleiste und Fusszeile auseinanderliefen.
const SEITEN: [string, string][] = [
  ['Dashboard', '/'],
  ['Accounts', '/#accounts'],
  ['GodBot', '/godbot/'],
  ['Vorlagen', '/vorlagen/'],
  ['Statistik', '/statistik/'],
  ['Protokoll', '/protokoll/'],
  ['Team', '/team/'],
  ['Scripts', '/scripts/'],
  ['Einstellungen', '/einstellungen/'],
];

// 01.10.2026: Fuenf feste Plaetze, der fuenfte oeffnet "Mehr". Vorher waren
// es fuenf Eintraege in einem 4er-Raster (der letzte rutschte in eine zweite
// Zeile), und Team, Accounts und Scripts waren am Handy nicht erreichbar.
const FUSS: [string, string, string][] = [
  ['⌂', 'Dashboard', '/'],
  ['⚔', 'GodBot', '/godbot/'],
  ['📊', 'Statistik', '/statistik/'],
  ['📋', 'Protokoll', '/protokoll/'],
];
const MEHR: [string, string, string][] = [
  ['👥', 'Accounts', '/#accounts'],
  ['🤝', 'Team', '/team/'],
  ['📐', 'Vorlagen', '/vorlagen/'],
  ['🧩', 'Scripts', '/scripts/'],
  ['⚙', 'Einstellungen', '/einstellungen/'],
];

export default function OdinShell({
  titel,
  aktiv,
  rechts,
  children,
}: {
  titel: string;
  aktiv: string;
  rechts?: ReactNode;
  children: ReactNode;
}) {
  // Die Sitzung wird nicht mehr hier abgeglichen: lib/supabase.ts liest das
  // Tokenpaar in der App bei jedem Zugriff direkt aus der Bruecke. Die
  // fruehere Hin-und-Her-Uebergabe (5-Minuten-Takt, setSession) konnte selbst
  // erneuern und war Teil des Problems.

  const [mehrOffen, setMehrOffen] = useState(false);
  const mehrAktiv = MEHR.some(([, label]) => label === aktiv);

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">⚔ Teamzentrale Odin</div>
        <nav className="nav">
          {SEITEN.map(([name, href]) => (
            <a className={name === aktiv ? 'active' : ''} href={href} key={name}>{name}</a>
          ))}
        </nav>
      </aside>

      <div style={{ flex: 1, minWidth: 0 }}>
        <div className="mobileNav">
          <strong>⚔ Teamzentrale Odin</strong>
        </div>

        <main className="main">
          <header
            className="top"
            style={{
              position: 'sticky', top: 0, zIndex: 30,
              background: 'var(--bg,#fff)', borderBottom: '1px solid rgba(0,0,0,.08)',
              display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12,
            }}
          >
            <h1 className="title" style={{ whiteSpace: 'nowrap', margin: 0, minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis' }}>
              <span className="titleBrand">⚔ Odin</span>{titel}
            </h1>
            {/* 02.10.2026: darf schrumpfen - die Konto-Auswahl der GodBot-Seite
                machte die Kopfzeile breiter als den Bildschirm, das Handy zoomte
                die Seite heraus und die Fusszeile sah anders aus. */}
            <div className="topRechts" style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0, flexShrink: 1 }}>
              {rechts}
              <VersionUpdater />
            </div>
          </header>

          {children}
        </main>

        {mehrOffen && (
          <div className="mehrBackdrop" onClick={() => setMehrOffen(false)}>
            <div className="mehrSheet" onClick={e => e.stopPropagation()} role="dialog" aria-label="Weitere Seiten">
              <div className="mehrGriff" />
              {MEHR.map(([icon, label, href]) => (
                <a href={href} key={label} className={label === aktiv ? 'active' : ''} onClick={() => setMehrOffen(false)}>
                  <span>{icon}</span>{label}
                </a>
              ))}
            </div>
          </div>
        )}

        <nav className="bottomNav" aria-label="Mobile Navigation">
          {FUSS.map(([icon, label, href]) => (
            <a href={href} key={label} className={label === aktiv ? 'active' : ''} aria-current={label === aktiv ? 'page' : undefined}>
              <span>{icon}</span>
              <small>{label === 'Dashboard' ? 'Übersicht' : label}</small>
            </a>
          ))}
          <button type="button" className={mehrAktiv || mehrOffen ? 'active' : ''} onClick={() => setMehrOffen(o => !o)} aria-expanded={mehrOffen}>
            <span>☰</span>
            <small>Mehr</small>
          </button>
        </nav>
      </div>
    </div>
  );
}
