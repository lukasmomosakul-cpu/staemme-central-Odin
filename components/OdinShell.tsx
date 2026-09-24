'use client';

import { type ReactNode } from 'react';
import VersionUpdater from './VersionUpdater';

// Gemeinsames Geruest fuer alle Seiten. Vorher hatte jede Seite ihr eigenes
// Layout, wodurch Kopfzeile, Seitenleiste und Fusszeile auseinanderliefen.
const SEITEN: [string, string][] = [
  ['Dashboard', '/'],
  ['Accounts', '/#accounts'],
  ['GodBot', '/godbot/'],
  ['Statistik', '/statistik/'],
  ['Protokoll', '/protokoll/'],
  ['Team', '/team/'],
  ['Scripts', '/scripts/'],
  ['Einstellungen', '/einstellungen/'],
];

const FUSS: [string, string, string][] = [
  ['⌂', 'Dashboard', '/'],
  ['📊', 'Statistik', '/statistik/'],
  ['📋', 'Protokoll', '/protokoll/'],
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
            <h1 className="title" style={{ whiteSpace: 'nowrap', margin: 0 }}>{titel}</h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              {rechts}
              <VersionUpdater />
            </div>
          </header>

          {children}
        </main>

        <nav className="bottomNav" aria-label="Mobile Navigation">
          {FUSS.map(([icon, label, href]) => (
            <a href={href} key={label} className={label === aktiv ? 'active' : ''}>
              <span>{icon}</span>
              <small>{label}</small>
            </a>
          ))}
        </nav>
      </div>
    </div>
  );
}
