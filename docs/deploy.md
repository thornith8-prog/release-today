# Deploying Release Today (Flutter Web)

Release Today is a **static Flutter web app**. Deploying it means building once and serving the `build/web/` directory from any static web host.

```
flutter build web --release   # -> build/web/
          ^------------------ deploy this directory
```

---

## 1. Prerequisites

- Flutter SDK **3.44.0** (stable) — pinned by `.github/workflows/flutter-web.yml`
- Dart 3.12.0 (bundled with Flutter)
- Dependencies already fetched: `flutter pub get` (`.dart_tool/package_config.json` present)

Verify:

```bash
flutter --version      # Flutter 3.44.0 • channel stable
flutter pub get        # resolves dependencies
```

---

## 2. Build for release

```bash
flutter build web --release
```

Output goes to `build/web/`. That directory is self-contained (HTML, JS, CSS, assets, fonts) — copy it to your host.

**Build-time configuration** comes from `.env` (gitignored, local-dev only — see `pubspec.yaml`; it is **not** bundled into the web build):

```
cp .env.example .env   # local dev only
```

Key variables (`lib/core/env.dart`):

| Variable | Purpose | Release default |
|---|---|---|
| `NEWS_API_URL` | Backend base URL (no trailing slash) | `https://news-ai-d115c798.fastapicloud.dev` |
| `NEWS_API_USE_CORS_PROXY` | Route via local `127.0.0.1:8787` proxy | `false` (off — release must not depend on a dev-only proxy) |
| `NEWS_API_TIMEOUT` | Request timeout seconds | `30` |
| `ABOUT_URL`, `WHAT_WE_DO_URL`, `TERMS_URL`, `PRIVACY_URL` | Legal/info links | `https://newsai.app/…` |

> ⚠️ `.env` is **gitignored** and is **not** shipped with the web build. Do not put secrets in it. For deployment, pass config via `--dart-define` instead:
> ```bash
> flutter build web --release \
>   --dart-define=NEWS_API_URL=https://api.example.com \
>   --dart-define=NEWS_API_USE_CORS_PROXY=false
> ```

---

## 3. Deploy options

### A. GitHub Pages — automated via CI (recommended)

`.github/workflows/flutter-web.yml` runs on every push to `main` (and on `workflow_dispatch`):

1. Checks out the repo
2. Sets up Flutter 3.44.0 (stable)
3. `flutter pub get` → `flutter analyze`
4. `flutter build web --release`
5. Deploys `build/web/` to the `gh-pages` branch via `peaceiris/actions-gh-pages@v4`

No extra configuration is required — `GITHUB_TOKEN` is provided automatically by GitHub Actions.

**Note:** CI does **not** check out a `.env`, so the release build uses the code defaults (or `--dart-define` values if you add them to the workflow). To customize `NEWS_API_URL` in CI, add repo/environment secrets and pass them via `--dart-define`.

### B. Any static host (manual)

Upload the entire contents of `build/web/` to the host's web root. Works with:

- Vercel, Netlify, Firebase Hosting
- AWS S3 + CloudFront, Cloudflare Pages, GitLab Pages, etc.

The app is a single-page application (SPA) using `go_router`. Your host must **rewrite all routes to `index.html`** so a direct refresh on `/search?q=…` doesn't 404. Example (Vercel `vercel.json`):

```json
{
  "rewrites": [{ "source": "/:path*", "destination": "/index.html" }]
}
```

---

## 4. Subdirectory hosting (base href)

If the app is served from a path other than the domain root (e.g. `https://example.com/app/`), build with `--base-href`:

```bash
flutter build web --release --base-href=/app/
```

`web/index.html` contains `<base href="$FLUTTER_BASE_HREF">`, which Flutter replaces with the value you pass. Serve from `/app/` and all asset/routes resolve correctly.

---

## 5. What NOT to ship to production

- **`tool/cors_proxy.dart`** — local development only. It binds `127.0.0.1:8787` and proxies to the backend so Chrome can run without `--disable-web-security`. It is not part of the web build and has no place on a public host.
- **`NEWS_API_USE_CORS_PROXY=true`** — off by default in release (`docs/deploy.md` + `.env.example` set it to `false`). In production there is no proxy at the visitor's `127.0.0.1`, so leaving it `on` would break API calls.
- **Secrets in `.env`** — it is bundled into `build/web/assets/.env` and readable by anyone.

For production, the browser calls the backend directly, so the FastAPI backend must allow your web origin via CORS (see `README.md` "Configure").

---

## 6. Verify locally before deploying

```bash
flutter build web --release
cd build/web
python3 -m http.server 8080   # or: npx serve . / dart run webdev serve
# open http://localhost:8080
```

Check:
- Home loads and the carousel/search work
- Backend responses succeed (no CORS or proxy errors in DevTools)
- Refreshing on a deep link (e.g. `/search?q=ai`) returns the app, not a 404

---

## 7. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Blank white screen | Wrong `--base-href`, or JS failed to load | Open DevTools Console; confirm `<base href>` matches the served path |
| API calls fail with CORS error | Backend doesn't allow your origin | Add your domain to the FastAPI `CORSMiddleware` `allow_origins` |
| API calls fail in release only | `NEWS_API_USE_CORS_PROXY=true` pointing at a dev-only `127.0.0.1:8787` | Set to `false` (release default) |
| 404 on refresh of `/search?q=…` | Host not rewriting SPA routes to `index.html` | Add a catch-all rewrite rule on your host |
| Build fails on `pub get` | Network/proxy blocked | Dependencies are cached locally; CI runs on GitHub-hosted runners with direct access |

---

### Files referenced

- `.github/workflows/flutter-web.yml` — CI build + GitHub Pages deploy
- `pubspec.yaml` — Flutter SDK constraint, dependencies, `.env` as asset
- `.env.example` — tracked config template (copy to `.env`)
- `lib/core/env.dart` — config parsing and defaults
- `lib/services/api_client.dart` — API client (dev-only CORS proxy at `127.0.0.1:8787`)
- `web/index.html` — entry page with `$FLUTTER_BASE_HREF` placeholder
