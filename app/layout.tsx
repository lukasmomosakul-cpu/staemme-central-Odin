import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Teamzentrale Odin',
  description: 'Zentrale Verwaltung für dein Team',
  applicationName: 'Teamzentrale Odin',
  appleWebApp: { capable: true, title: 'Teamzentrale Odin', statusBarStyle: 'black-translucent' },
};

export const viewport: Viewport = { width: 'device-width', initialScale: 1, viewportFit: 'cover' };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="de"><body>{children}</body></html>;
}
