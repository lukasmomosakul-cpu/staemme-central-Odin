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
  },
};

export default config;
