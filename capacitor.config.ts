import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'de.teamzentrale.odin',
  appName: 'Teamzentrale Odin',
  webDir: 'out',
  server: {
    // Keep Supabase configuration in Vercel instead of duplicating it in the APK build.
    // The Android shell loads the same production frontend as the web app.
    url: 'https://staemme-central-odin.vercel.app/',
    cleartext: false,
    // Die-Stämme must remain a top-level page inside Capacitor's Android WebView.
    // Without this allow-list Capacitor may hand external navigation to the system browser.
    allowNavigation: ['https://www.die-staemme.de', 'https://die-staemme.de'],
  },
};

export default config;
