import { describe, expect, it } from 'vitest';

import { brandGradient, themeTokens } from '../src/theme/tokens';

describe('theme tokens', () => {
  it('matches the app color palette', () => {
    expect(themeTokens.background).toBe('#0A0E1A');
    expect(themeTokens.surface).toBe('#151B2E');
    expect(themeTokens.primary).toBe('#4FC3F7');
    expect(themeTokens.secondary).toBe('#B388FF');
  });

  it('keeps the wordmark gradient aligned with the app', () => {
    expect(brandGradient).toEqual(['#4FC3F7', '#B388FF']);
  });
});
