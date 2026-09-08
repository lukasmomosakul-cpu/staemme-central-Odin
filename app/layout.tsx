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
  return <html lang="de"><head><style>{`header.top > div > span.muted { display: inline !important; }`}</style></head><body>{children}<div id="odin-version-updater" style={{position:'fixed',left:'50%',bottom:4,transform:'translateX(-50%)',zIndex:60,fontSize:10,opacity:.7}}><VersionUpdater /></div></body></html>;
}
