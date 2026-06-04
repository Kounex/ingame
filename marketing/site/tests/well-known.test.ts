import fs from 'node:fs';
import path from 'node:path';

import { describe, expect, it } from 'vitest';

const publicDir = path.resolve(process.cwd(), 'public');
const canonicalWellKnownDir = path.resolve(process.cwd(), '..', '..', 'web', '.well-known');

describe('well-known files', () => {
  it('includes the Apple association file', () => {
    const file = path.join(publicDir, '.well-known', 'apple-app-site-association');
    expect(fs.existsSync(file)).toBe(true);
  });

  it('includes the Android asset links file', () => {
    const file = path.join(publicDir, '.well-known', 'assetlinks.json');
    expect(fs.existsSync(file)).toBe(true);
  });

  it('matches the canonical Apple association file from web/.well-known', () => {
    const marketingFile = path.join(publicDir, '.well-known', 'apple-app-site-association');
    const canonicalFile = path.join(canonicalWellKnownDir, 'apple-app-site-association');

    expect(fs.readFileSync(marketingFile, 'utf8')).toBe(fs.readFileSync(canonicalFile, 'utf8'));
  });

  it('matches the canonical Android asset links file from web/.well-known', () => {
    const marketingFile = path.join(publicDir, '.well-known', 'assetlinks.json');
    const canonicalFile = path.join(canonicalWellKnownDir, 'assetlinks.json');

    expect(fs.readFileSync(marketingFile, 'utf8')).toBe(fs.readFileSync(canonicalFile, 'utf8'));
  });
});
