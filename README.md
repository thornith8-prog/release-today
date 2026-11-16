# Release Today (Flutter Web)

Responsive Flutter web front end for the Release Today backend: home carousel, search results grid, login dialog,
prompt-style search bar pinned to the bottom. State management: GetX.

## Setup
```bash
cp .env.example .env              # if .env is missing
flutter create . --platforms=web  # generates web/ (does not overwrite lib/ or pubspec.yaml)
flutter pub get
# Start the local CORS proxy (required so Chrome can run without the
# unsupported --disable-web-security flag, which newer Chrome versions
# reject with an error page instead of loading the app):
dart run tool/cors_proxy.dart

# Serve the web app without launching Chrome (flutter run -d chrome passes
# --disable-web-security, which is unsupported and blocks the page):
flutter run -d web-server

# Open the printed URL (e.g. http://localhost:XXXX) directly in Chrome.
```
Production build: `flutter build web --release` (output in `build/web`).

## Configure
`NEWS_API_URL` points at the backend; leave it empty to use demo data.
Match `NEWS_API_LATEST_PATH`, `NEWS_API_SEARCH_PATH`, `NEWS_API_SEARCH_METHOD` and `NEWS_API_SEARCH_PARAM` to the API's `/docs`.

`.env` is **local-dev only** (gitignored, not bundled into the web build). Copy `.env.example` to `.env` to override defaults locally:
```bash
cp .env.example .env
```
For deployment, pass config via `--dart-define` instead (e.g. `--dart-define=NEWS_API_URL=https://api.example.com`), since `.env` is not shipped with the build. Do not put secrets in `.env`.

**CORS:** the browser calls the API directly, so the FastAPI backend must allow your web origin:
```python
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
```
For local development you can avoid configuring backend CORS entirely: run
`dart run tool/cors_proxy.dart` and set `NEWS_API_USE_CORS_PROXY=true` (already set
in `.env`). The browser then calls `http://127.0.0.1:8787` (same origin), which
proxies to the backend.

## Responsive behavior
| Width | Layout |
|---|---|
| < 600 | drawer sidebar, 1-column grid, 16px padding, smaller hero text |
| 600-1023 | drawer sidebar, 2-column grid |
| >= 1024 | permanent collapsible sidebar, 3-column grid |
Breakpoints live in `lib/core/breakpoints.dart`.

## State management (GetX)
- `AppBinding` (`lib/core/app_binding.dart`) registers the repository and long-lived controllers once, as `GetMaterialApp`'s `initialBinding`.
- `AppController`: recent searches, signed-in user, sidebar open/closed (all `.obs`).
- `HomeController`: latest news; permanent, so returning home does not refetch.
- `ResultsController`: one per query, created and disposed with the results page (`GetX<ResultsController>(tag: query, ...)`).
- `SearchBarController`: owns the search text field and submits searches.
- Widgets read state with `Obx` / `GetView`; there is no `setState` for app data.
- Navigation stays on `go_router` (URL per page, back button, reload). `AppNav` lets controllers navigate without a `BuildContext`.

## Structure
```
lib/
  main.dart, app.dart, router.dart     entry, GetMaterialApp.router, go_router (shell + / + /search?q=)
  controllers/ app, home, results, search bar (GetxController); shared ArticlesController base
  core/        env, theme, breakpoints, AppBinding, AppNav, scroll behavior
  data/        Article model + tolerant JSON parser, NewsRepository (API + demo)
  features/    shell (sidebar, top bar, search bar), home, results
  widgets/     news card, pill button, auth dialog, loading/error views
test/          parser, controller and responsive smoke tests
```
