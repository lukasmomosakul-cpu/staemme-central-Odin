import type { Metadata, Viewport } from 'next';
import './globals.css';
import VersionUpdater from '../components/VersionUpdater';

export const metadata: Metadata = {
  title: 'Teamzentrale Odin',
  description: 'Zentrale Verwaltung für dein Team',
  applicationName: 'Teamzentrale Odin',
  appleWebApp: { capable: true, title: 'Teamzentrale Odin', statusBarStyle: 'black-translucent' },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1, viewportFit: 'cover' };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="de"><head><style>{`header.top > div > span.muted { display: none !important; } .mobileNav > span.muted { visibility:hidden !important; } #odin-version-updater { position:fixed; top:36px; right:28px; z-index:60; } @media(max-width:900px){#odin-version-updater{top:23px;right:16px}}`}</style></head><body>{children}<div id="odin-version-updater"><VersionUpdater /></div></body></html>;
}