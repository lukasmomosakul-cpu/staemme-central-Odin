import type { Metadata, Viewport } from 'next';
import './globals.css';
import './odin-theme.css';
import VersionUpdater from '../components/VersionUpdater';

export const metadata: Metadata = {
  title: 'Teamzentrale Odin',
  description: 'Zentrale Verwaltung für dein Team',
  applicationName: 'Teamzentrale Odin',
  appleWebApp: { capable: true, title: 'Teamzentrale Odin', statusBarStyle: 'black-translucent' },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1, viewportFit: 'cover' };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  // Frueher stand hier ein fest positionierter Versionsknopf plus CSS, das die
  // Version in der Kopfzeile ausblendete. Beide Zeilen waren nach dem Umbau der
  // Kopfzeile sichtbar. Der Knopf wird jetzt direkt in der Kopfzeile gerendert.
  return <html lang="de"><body>{children}</body></html>;
}