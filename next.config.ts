import fs from 'node:fs';
import path from 'node:path';
import type { NextConfig } from 'next';

const appVersion = fs
  .readFileSync(path.join(process.cwd(), 'VERSION'), 'utf8')
  .trim();

if (!/^\d+\.\d+\.\d+$/.test(appVersion)) {
  throw new Error(`Invalid VERSION: ${appVersion}`);
}

const nextConfig: NextConfig = {
  output: 'export',
  trailingSlash: true,
  env: {
    NEXT_PUBLIC_APP_VERSION: appVersion,
  },
  images: {
    unoptimized: true,
  },
};

export default nextConfig;
