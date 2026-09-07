import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'de.teamzentrale.odin',
  appName: 'Teamzentrale Odin',
  webDir: 'out',
  server: {
    url: process.env.ODIN_NATIVE_SERVER_URL,
    cleartext: false
  }
};

export default config;
