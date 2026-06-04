import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://in-game.app',
  output: 'static',
  build: {
    format: 'directory',
  },
});
