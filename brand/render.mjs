// Rasterises the brand SVGs into Android launcher/adaptive icons and web icons.
// Usage (from repo root): NODE_PATH=<dir containing playwright> node brand/render.mjs
// Re-run after changing any SVG; the PNG outputs are committed.
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const brand = dirname(fileURLToPath(import.meta.url));
const app = join(brand, '..', 'app');
const svg = (name) => readFileSync(join(brand, name), 'utf8');

const densities = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };
const jobs = [];
for (const [d, scale] of Object.entries(densities)) {
  const res = join(app, 'android/app/src/main/res', `mipmap-${d}`);
  jobs.push({ src: 'vepari-logo.svg', size: 48 * scale, out: join(res, 'ic_launcher.png') });
  jobs.push({ src: 'vepari-icon-foreground.svg', size: 108 * scale, out: join(res, 'ic_launcher_foreground.png') });
}
jobs.push(
  { src: 'vepari-logo.svg', size: 192, out: join(app, 'web/icons/Icon-192.png') },
  { src: 'vepari-logo.svg', size: 512, out: join(app, 'web/icons/Icon-512.png') },
  { src: 'vepari-icon-maskable.svg', size: 192, out: join(app, 'web/icons/Icon-maskable-192.png') },
  { src: 'vepari-icon-maskable.svg', size: 512, out: join(app, 'web/icons/Icon-maskable-512.png') },
  { src: 'vepari-logo.svg', size: 32, out: join(app, 'web/favicon.png') },
  { src: 'vepari-logo.svg', size: 1024, out: join(brand, 'vepari-logo-1024.png') },
);

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH });
const page = await browser.newPage();
for (const job of jobs) {
  await page.setViewportSize({ width: job.size, height: job.size });
  await page.setContent(
    `<html><body style="margin:0;background:transparent">${svg(job.src).replace('<svg ', `<svg width="${job.size}" height="${job.size}" `)}</body></html>`,
  );
  await page.screenshot({ path: job.out, omitBackground: true, clip: { x: 0, y: 0, width: job.size, height: job.size } });
  console.log(`${job.out.replace(join(brand, '..') + '/', '')} (${job.size}px)`);
}
await browser.close();
