# Article Share Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give each news card a Share button that shares one NewsAI link, `{shareBaseUrl}/s/{id}`, which previews correctly on every social network. The link itself is served by a new FastAPI route.

**Architecture:** A pure Dart helper (`ArticleShare`) builds the share URL and the share URLs for each network. `NewsCard` gets a share icon that opens a popup menu using that helper. The backend route is delivered as a reference snippet because the backend repo is not in this workspace.

**Tech Stack:** Flutter (web), GetX, `url_launcher`, `flutter/services` Clipboard, and FastAPI for the snippet.

**Spec:** `docs/superpowers/specs/2026-11-11-article-share-link-design.md`

## Global Constraints
- No new pub dependencies.
- The share URL format is exactly `{Env.shareBaseUrl}/s/{article.id}`. `shareBaseUrl` has no trailing slash.
- `SHARE_BASE_URL` comes from `.env` and defaults to `Env.apiUrl`.
- The menu actions are exactly: Copy link, Telegram, Facebook, LinkedIn, X.
- All query values are encoded with `Uri` (never string concatenation).
- This workspace is not a git repo, so the commit steps are skipped.

## Review Focus
- A title with `&`, `#`, `?` or emoji must not break the Telegram/X share URLs (encoding test in Task 1).
- An article with a `null` id gets no share icon and `shareUrl` returns `null` (Tasks 1 and 2).
- A `SHARE_BASE_URL` with a trailing slash must not produce `//s/` (Task 1).
- Tapping the share icon must not also open the article, which is the card's own tap (Task 2).
- A very long title in X's `text` is still a valid, encoded URL (covered by the encoding test).

---

### Task 1: Share URL builder

**Files:**
- Modify: `lib/core/env.dart` (add `shareBaseUrl`)
- Create: `lib/core/article_share.dart`
- Test: `test/article_share_test.dart`

**Interfaces:**
- Produces:
  - `enum ShareTarget { telegram, facebook, linkedin, x }`
  - `class ArticleShare { static String? shareUrl(ArticleData a, {String? baseUrl}); static Uri? targetUri(ShareTarget t, ArticleData a, {String? baseUrl}); }`
    `baseUrl` defaults to `Env.shareBaseUrl` and exists only for tests.

- [ ] **Step 1: Write failing tests** in `test/article_share_test.dart`:
  - `shareUrl` returns `'https://n.ai/s/42'` for id 42 with `baseUrl: 'https://n.ai'`.
  - Same result with `baseUrl: 'https://n.ai/'` (trailing slash removed).
  - `shareUrl` returns `null` and `targetUri` returns `null` for each target when `id == null`.
  - `targetUri(telegram)` has host `t.me`, path `/share/url`, `queryParameters['url'] == 'https://n.ai/s/42'`, `queryParameters['text'] == title`.
  - `facebook`: host `www.facebook.com`, path `/sharer/sharer.php`, param `u`.
  - `linkedin`: host `www.linkedin.com`, path `/sharing/share-offsite/`, param `url`.
  - `x`: host `twitter.com`, path `/intent/tweet`, params `url` and `text`.
  - A title `'A & B #1? 🚀'` round-trips exactly through `queryParameters['text']` for telegram and x.
- [ ] **Step 2:** `flutter test test/article_share_test.dart` should FAIL (the file doesn't exist yet).
- [ ] **Step 3:** Add `static String get shareBaseUrl` to `Env` (strip the trailing `/`, the same way `apiUrl` does). Implement `ArticleShare` using `Uri.https(host, path, params)`.
- [ ] **Step 4:** Run the same command. It should PASS.

### Task 2: Share menu on NewsCard

**Files:**
- Create: `lib/widgets/article_share_button.dart`
- Modify: `lib/widgets/news_card.dart` (add a `Positioned(top: 4, left: 4)` share button inside the Stack, after the date)
- Test: `test/article_share_button_test.dart`

**Interfaces:**
- Consumes: `ArticleShare.shareUrl`, `ArticleShare.targetUri`, `ShareTarget` (Task 1).
- Produces: `class ArticleShareButton extends StatelessWidget { const ArticleShareButton({super.key, required ArticleData article}); }`

- [ ] **Step 1: Write failing widget tests:**
  - With id 42, tapping the `Icons.share` button shows the texts `Copy link`, `Telegram`, `Facebook`, `LinkedIn` and `X`.
  - Tapping `Copy link` puts `'{Env.shareBaseUrl}/s/42'` on the clipboard (mock `SystemChannels.platform` `Clipboard.setData`) and shows the snackbar `Link copied`.
  - With `id: null`, `find.byIcon(Icons.share)` finds nothing.
- [ ] **Step 2:** `flutter test test/article_share_button_test.dart` should FAIL.
- [ ] **Step 3:** Implement `ArticleShareButton` as a `PopupMenuButton<_Action>` with a white-circle `Icons.share` (size 18) and tooltip `Share`. It returns `SizedBox.shrink()` when `shareUrl` is null. Network items call `launchUrl(uri, webOnlyWindowName: '_blank')`. Because the button is a separate tap target on top of the card's `InkWell`, it does not trigger the card's open.
- [ ] **Step 4:** Run it. It should PASS. Then run `flutter analyze lib` with no issues and `flutter test` (only the known live-API test may fail).

### Task 3: Backend route snippet

**Files:**
- Create: `docs/backend/share_route.py` (a reference for the FastAPI repo; it is not run here)

- [ ] **Step 1:** Write `GET /s/{article_id}` (`article_id: int`), following the spec's Backend section:
  load by id, use `html.escape` on every value, set `og:*` / `twitter:card=summary_large_image` / canonical / meta refresh, and forward only to the stored `url` if its scheme is `http`/`https` (otherwise to the site home). Set the headers
  `Cache-Control: public, max-age=3600`, `X-Content-Type-Options: nosniff`, and
  `Content-Security-Policy: default-src 'none'; img-src https:; style-src 'unsafe-inline'`. Return 404 for unknown ids.
  Mark the DB lookup `# TODO: replace with your ORM query`.
- [ ] **Step 2:** `python3 -m py_compile docs/backend/share_route.py` should exit 0.
