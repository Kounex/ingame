import { afterEach, describe, expect, it, vi } from 'vitest';

import {
  APP_URL,
  MARKETING_URL,
  buildCanonicalUrl,
  siteMeta,
} from '../src/config/site';

describe('site config', () => {
  afterEach(() => {
    delete process.env.INGAME_MARKETING_SITE_URL;
    delete process.env.INGAME_WEB_APP_BASE_URL;
    delete process.env.INGAME_API_BASE_URL;
    vi.resetModules();
  });

  it('uses the agreed production hosts', () => {
    expect(MARKETING_URL).toBe('https://in-game.app');
    expect(APP_URL).toBe('https://app.in-game.app');
  });

  it('builds canonical URLs on the marketing domain', () => {
    expect(buildCanonicalUrl('/privacy')).toBe('https://in-game.app/privacy');
    expect(buildCanonicalUrl('/')).toBe('https://in-game.app/');
  });

  it('keeps homepage metadata product-accurate', () => {
    expect(siteMeta.title).toContain('InGame');
    expect(siteMeta.description).toContain('find time to play');
    expect(siteMeta.description).not.toContain('matchmaking');
  });

  it('allows build-time host overrides for containerized environments', async () => {
    process.env.INGAME_MARKETING_SITE_URL = 'http://localhost:8081';
    process.env.INGAME_WEB_APP_BASE_URL = 'http://localhost:8080';
    process.env.INGAME_API_BASE_URL = 'http://localhost:8000/api/v1';
    vi.resetModules();

    const siteConfig = await import('../src/config/site');

    expect(siteConfig.MARKETING_URL).toBe('http://localhost:8081');
    expect(siteConfig.APP_URL).toBe('http://localhost:8080');
    expect(siteConfig.API_URL).toBe('http://localhost:8000/api/v1');
    expect(siteConfig.buildCanonicalUrl('/privacy')).toBe('http://localhost:8081/privacy');
  });
});
