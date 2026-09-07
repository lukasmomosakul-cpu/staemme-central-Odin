import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = { title: 'Stämme Central', description: 'Team-Zentrale' };

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="de"><body>{children}</body></html>;
}
