# Article share link: design

**Date:** 2026-11-11 · **Size:** small change (short design)

## Intent
Give each article **one NewsAI URL** that shows a proper preview (title, summary, image)
on every social network and then sends the reader on to the publisher's article.

## Goals / non-goals
- Goal: one link per article, `https://<api-domain>/s/{id}`, with correct previews on Facebook,
  Telegram, LinkedIn, X, WhatsApp, Slack and others.
- Goal: a Share button on each news card with Copy link, Telegram, Facebook, LinkedIn, X.
- Non-goal: a NewsAI article page in the app (the user picked "go to the publisher").
- Anti-goal: an open redirect. The share page must never forward to a URL taken from the request.

## Approaches considered
| | Approach | Verdict |
|---|---|---|
| A | **Backend share page** with `og:`/`twitter:` tags, then forward to the publisher | **Picked.** It's the only option that gives one branded link with correct previews everywhere. |
| B | Share the publisher's URL directly | Rejected: it isn't a NewsAI link, so no traffic or branding. |
| C | Pre-rendering service for the Flutter app | Rejected: extra cost and fragile, for no gain over A. |

## Design
**Backend (FastAPI, separate repo).** New public route `GET /s/{article_id:int}`:
1. Load the article by id from the DB. If it's missing or inactive, return 404 or forward to the NewsAI home page.
2. Return `text/html` with HTML-escaped `og:title`, `og:description` (summary, trimmed to about 200 chars),
   `og:image`, `og:url` (the share URL itself), `og:type=article`, `og:site_name=NewsAI`,
   `twitter:card=summary_large_image`, a `<link rel="canonical">` to the publisher URL, and
   `<meta http-equiv="refresh" content="0; url=...">` plus a plain fallback link.
3. Forward only to the article's **stored** `url`, and only if it is `http`/`https`.
4. Headers: `Cache-Control: public, max-age=3600`, `X-Content-Type-Options: nosniff`,
   and a strict CSP (no scripts).
5. Optional: count the click (the article model already has `clicks`).

Crawlers read the meta tags. People are forwarded right away.

**Flutter app (this repo).**
- `Env.shareBaseUrl`, read from `SHARE_BASE_URL` in `.env` and defaulting to `Env.apiUrl`.
- `ArticleShare` helper: `shareUrl(article)` returns `$shareBaseUrl/s/{id}`, plus builders for each network
  (Telegram `t.me/share/url`, Facebook `sharer.php`, LinkedIn `share-offsite`, X `intent/tweet`),
  all encoded with `Uri`.
- A share icon on `NewsCard` opens a small menu: Copy link (with a snackbar), Telegram, Facebook, LinkedIn, X.
  The icon is hidden when the article has no `id`.
- No new packages: it uses `url_launcher` and `Clipboard`, which are already available.

## Left to the builder
The exact icon placement on the card and the menu styling, matching the existing look.

## Verification
- Unit tests for the URL builders (encoding, missing id).
- A widget test that the share menu shows all five actions.
- Backend: check `/s/{id}` in the Facebook Sharing Debugger and the LinkedIn Post Inspector,
  and confirm a crafted id can't forward anywhere other than the stored URL.
