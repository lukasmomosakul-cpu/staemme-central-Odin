import type { CapacitorConfig } from '@capacitor/cli';

const nativeServerUrl = process.env.ODIN_NATIVE_SERVER_URL || 'https://staemme-central-odin.vercel.app/';

const config: CapacitorConfig = {
  appId: 'de.teamzentrale.odin',
  appName: 'Teamzentrale Odin',
  webDir: 'out',
  server: {
    url: nativeServerUrl,
    cleartext: false
  }
};

export default config;
