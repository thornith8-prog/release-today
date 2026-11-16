# Recommendations Endpoint for Home Page: Design

**Date:** 2026-11-12 · **Size:** Small change (short design)

## Intent
Use the personalized recommendation endpoint `https://news-ai-d115c798.fastapicloud.dev/recommendations/?limit=20` to load articles in the Home Page's "The latest news" section. When users are authenticated, the endpoint delivers personalized articles based on activity (clicks, searches via AI embeddings); for guests, it gracefully falls back to popular/recent articles.

## Goals
- Load articles on `HomePage` via `/recommendations/?limit=20`.
- Update environment settings in `.env` and `.env.example` so `NEWS_API_LATEST_PATH` defaults to `/recommendations/`.
- Ensure `Env.latestPath` defaults to `/recommendations/` as the fallback when unset.
- Whitelist `/recommendations` in `tool/cors_proxy.dart` so local web development proxying does not block requests with `403 Forbidden`.
- Keep existing `HomeController` logic loading 20 articles without regressions.
- Verify through unit/widget tests and `flutter analyze lib`.

## Non-goals / Anti-goals
- Non-goal: Changing the backend implementation of `/recommendations/`.
- Non-goal: Redesigning the home page layout or replacing the "The latest news" UI title unless requested.

## Approaches Considered
1. **Approach A (Configurable Environment & Repository - Selected):**
   - Update `NEWS_API_LATEST_PATH` default in `lib/core/env.dart` and `.env` to `/recommendations/`.
   - Update `tool/cors_proxy.dart` path filter to allow `/recommendations`.
   - `HomeController` continues calling `repository.latest(skip: 0, limit: 20)`, fetching directly from `/recommendations/?skip=0&limit=20`.
   - *Why chosen:* Seamless integration, zero disruption to existing UI, adheres to the project's configurable environment pattern.
2. **Approach B (Hardcoded dedicated method):**
   - Add a separate `recommendations()` method in `NewsRepository`.
   - *Why rejected:* Inflexibility, unnecessary duplication when `Env.latestPath` is already intended to configure the main feed path.

## Technical Details
- `.env` & `.env.example`: Set `NEWS_API_LATEST_PATH=/recommendations/`.
- `lib/core/env.dart`: Update `latestPath => _get('NEWS_API_LATEST_PATH', '/recommendations/');`.
- `tool/cors_proxy.dart`: Add `!path.startsWith('/recommendations')` check alongside `/articles`, `/search`, and `/health`.
