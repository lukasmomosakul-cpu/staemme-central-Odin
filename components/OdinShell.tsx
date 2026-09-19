'use client';

import { useEffect, type ReactNode } from 'react';
import { supabase } from '../lib/supabase';
import VersionUpdater from './VersionUpdater';

// Gemeinsames Geruest fuer alle Seiten. Vorher hatte jede Seite ihr eigenes
// Layout, wodurch Kopfzeile, Seitenleiste und Fusszeile auseinanderliefen.
const SEITEN: [string, string][] = [
  ['Dashboard', '/'],
  ['Accounts', '/#accounts'],
  ['GodBot', '/godbot/'],
  ['Protokoll', '/protokoll/'],
  ['Team', '/team/'],
  ['Scripts', '/scripts/'],
  ['Einstellungen', '/einstellungen/'],
];

const FUSS: [string, string, string][] = [
  ['⌂', 'Dashboard', '/'],
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
  // supabase-js frischt die Sitzung selbst auf und dreht dabei das
  // Erneuerungstoken weiter. Ohne diese Zeile blieb die App auf dem alten
  // sitzen, jede eigene Erneuerung scheiterte und es kam die Meldung, der
  // Zugang sei abgelaufen - obwohl im Vordergrund alles lief.
  useEffect(() => {
    if (!supabase) return;
    const weiterreichen = (zugang?: string, erneuerung?: string) => {
      const br = (window as unknown as {
        Android?: { updateSupabaseTokens?: (a: string, r: string) => void };
      }).Android;
      if (br?.updateSupabaseTokens && zugang) br.updateSupabaseTokens(zugang, erneuerung ?? '');
    };
    supabase.auth.getSession().then(({ data }) =>
      weiterreichen(data.session?.access_token, data.session?.refresh_token));
    const { data: abo } = supabase.auth.onAuthStateChange((_e, sitzung) =>
      weiterreichen(sitzung?.access_token, sitzung?.refresh_token));
    return () => abo.subscription.unsubscribe();
  }, []);

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
