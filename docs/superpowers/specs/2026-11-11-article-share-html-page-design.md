# Article Share HTML Page: Design

**Date:** 2026-11-11 · **Size:** Small change (short design)

## Intent
Provide a single, branded NewsAI URL per article (`{shareBaseUrl}/s/{article_id}`) that renders a complete, responsive HTML reader page embedded with article data (title, image, summary, body, publisher attribution, author, published date) and rich social media metadata (Open Graph and Twitter Card). Any social network (Facebook, Telegram, LinkedIn, X, WhatsApp, etc.) generates an attractive link preview card, and readers who open the link get a fast, mobile-friendly article experience with direct links to the publisher and 1-click social share tools.

## Goals
- Serve a standalone HTML page at `GET /s/{article_id}` directly from the FastAPI backend (`cambodia-news-ai`).
- Embed complete Open Graph and Twitter Card tags in `<head>` so all social crawlers extract high-quality previews without executing client-side JavaScript.
- Display a reader-friendly HTML page in `<body>`:
  - NewsAI branding bar with a link to open the full app.
  - Article metadata: title, source badge, author, published date, category.
  - Hero image with fallback.
  - AI-generated summary highlighted in a summary card.
  - Cleanly formatted article body text.
  - Call-to-action buttons: **"Read Original on [Source]"** (opens publisher URL in new tab) and **"Explore on NewsAI"**.
  - Social share action bar (Telegram, Facebook, X, LinkedIn, Copy Link) for re-sharing the article.
- Record view / click metrics (`article.clicks += 1` and `record_click(db, article_id=...)`).
- Seamlessly integrate with the Flutter app (`newsai_flutter`):
  - Ensure `ArticleShare.shareUrl` builds `{shareBaseUrl}/s/{id}`.
  - Mount share buttons on both `NewsCard` (Home/More) and search/topic results tiles (`ResultsPage`).

## Non-goals / Anti-goals
- Non-goal: Requiring users to authenticate or install the Flutter app just to read a shared article.
- Anti-goal: Open redirects. The page displays the article data directly; external publisher links only point to the validated `article.url` stored in the database with strict `http`/`https` scheme validation.
- Anti-goal: XSS vulnerabilities. Jinja2 templates auto-escape all dynamic fields (`title`, `summary`, `body_text`, `source`, `author`), attribute values are strictly quoted, and URLs are validated against `javascript:` protocols.

## Approaches Considered
1. **FastAPI Server-Rendered HTML Reader Page (Picked):**
   - Direct SSR via FastAPI + Jinja2 template.
   - Zero client JS overhead, instant page load (<50ms), 100% crawler compatibility, dynamic view tracking.
2. **Flutter Web Client Route with Crawler Interception Proxy:**
   - Rejected: Heavy initial bundle download for mobile readers, complex and brittle crawler User-Agent detection.
3. **Static HTML Pre-generation to Object Storage:**
   - Rejected: Unnecessary architectural overhead and cache invalidation complexity for dynamic news content.

## Technical Design

### 1. Backend (`cambodia-news-ai`)
- **Template (`app/templates/article_share.html`):**
  - Modern, responsive HTML5 + CSS (clean typography, dark/light contrast matching NewsAI aesthetic, mobile-optimized padding).
  - Open Graph tags: `og:title`, `og:description`, `og:image`, `og:url`, `og:site_name` ("NewsAI"), `og:type` ("article").
  - Twitter Card tags: `twitter:card` ("summary_large_image"), `twitter:title`, `twitter:description`, `twitter:image`.
  - Canonical URL pointing to the original article `url`.
  - Share modal / links with pre-filled intent URLs for Telegram, Facebook, X, LinkedIn, and native clipboard copy.
- **Router (`app/routers/share.py`):**
  - Route: `GET /s/{article_id}`
  - Dependency: `db: Session = Depends(get_db)`
  - Logic:
    1. Look up `Article` where `id == article_id`.
    2. If not found, return a branded 404 HTML page or JSON 404.
    3. Validate `article.url` and `article.image_url` for safe `http`/`https` schemes.
    4. Truncate summary for `og:description` (max 200 chars).
    5. Increment `article.clicks += 1` and call `record_click(db, article_id=article.id)`.
    6. Return `TemplateResponse` with security headers (`X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, Content Security Policy, and caching).
- **Public access & App integration (`app/main.py` & `app/middlewares/keycloak_middleware.py`):**
  - Add `/s` path prefix to public paths in `KeycloakAuthMiddleware` so anonymous readers and social web crawlers are never blocked by 401s.
  - Mount `share.router` in `app/main.py`.

### 2. Frontend (`newsai_flutter`)
- Ensure `ArticleShare.shareUrl` and `ArticleShare.targetUri` are used consistently across cards.
- Add `ArticleShareButton` to `_ResultTile` on `ResultsPage` so search results and topic entries can also be shared directly with one click.
- Verify tests in `test/article_share_test.dart` and `test/article_share_button_test.dart`.

## Security & Verification Plan
- **Security:**
  - Mandatory Jinja2 autoescaping prevents XSS.
  - Strict URL scheme validation (`http`/`https` only) prevents `javascript:` URI attacks in links.
  - Parameterized ORM queries (`db.query(Article).filter(Article.id == article_id).first()`) prevent SQL injection.
  - Safe CSP headers and `nosniff`.
- **Verification:**
  - Automated backend tests:
    - `GET /s/{valid_id}` returns 200 `text/html` with correct `og:title`, `og:image`, `og:description`, and embedded article body.
    - `GET /s/{invalid_id}` returns 404 status.
    - Click count increment verification.
    - XSS injection test (ensure special characters `<script>` in title/body are safely escaped).
  - Automated frontend tests:
    - Run `flutter test test/article_share_test.dart` and `test/article_share_button_test.dart`.
    - Run `flutter analyze lib`.
