# InGame Marketing Site

## Local development

```bash
cd site
npm install
npm run dev
```

## Build

```bash
cd site
npm run build
```

The static output is written to `site/dist/`.

## Deploy

- Serve `site/dist/` as the static root for `in-game.app`
- Use `nginx.conf` for `/.well-known/*` handling and `/join/*` proxying
- Keep `app.in-game.app` pointing at the browser app runtime
- Keep the sample `.well-known` files updated with real production identifiers before launch
- `Dockerfile.marketing` builds the runtime image that the release workflow publishes as `ghcr.io/<owner>/ingame-marketing`
- `docker-compose.yml` exposes the marketing runtime on `localhost:8081`
- `docker-compose.release.yml` exposes the marketing runtime on port `8081` for external tunnel routing

## Verification

```bash
cd site
npm test
npm run build
cd ..
nginx -t -c "$PWD/nginx.conf"
```
