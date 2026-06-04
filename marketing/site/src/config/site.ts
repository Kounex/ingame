const DEFAULT_MARKETING_URL = 'https://in-game.app';
const DEFAULT_APP_URL = 'https://app.in-game.app';
const DEFAULT_API_URL = 'https://api.in-game.app';

export const MARKETING_URL =
  process.env.INGAME_MARKETING_SITE_URL ?? DEFAULT_MARKETING_URL;
export const APP_URL =
  process.env.INGAME_WEB_APP_BASE_URL ?? DEFAULT_APP_URL;
export const API_URL =
  process.env.INGAME_API_BASE_URL ?? DEFAULT_API_URL;

export const siteMeta = {
  title: 'InGame | Find time to play with friends',
  description:
    'InGame is a social gaming coordination app to help friend groups find time to play across web, iOS, and Android.',
};

export function buildCanonicalUrl(path: string): string {
  const normalized = path === '/' ? '/' : `/${path.replace(/^\/+/, '')}`;
  return new URL(normalized, `${MARKETING_URL}/`).toString();
}
