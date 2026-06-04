import { describe, expect, it } from 'vitest';

import { homepageContent } from '../src/data/homepage';

describe('homepage content', () => {
  it('keeps the web app as the primary CTA destination', () => {
    expect(homepageContent.hero.primaryCta.href).toBe('https://app.in-game.app');
  });

  it('frames native apps as the better mobile experience for notifications', () => {
    expect(homepageContent.platforms.description).toContain('notifications');
    expect(homepageContent.platforms.items.map((item) => item.label)).toEqual([
      'Web',
      'iOS',
      'Android',
    ]);
  });

  it('only lists shipped product capabilities', () => {
    const features = homepageContent.features.map((item) => item.title).join(' ');

    expect(features).toContain('Private groups');
    expect(features).toContain('Invite links');
    expect(features).not.toContain('Matchmaking');
  });
});
