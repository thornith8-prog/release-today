"""Reference FastAPI route for NewsAI article share links.

Copy into the backend repo and wire up the DB lookup. This file is not run by
the Flutter app.

    GET /s/{article_id}

Returns a tiny HTML page with Open Graph / Twitter Card tags so Facebook,
Telegram, LinkedIn, X, WhatsApp, Slack, etc. render a proper preview. Real
visitors are forwarded to the publisher's article immediately.

Security:
- Forwards ONLY to the article URL stored in the database, never to a value
  taken from the request (no open redirect).
- Every value is HTML-escaped before it goes into the page.
- No scripts; a strict CSP is sent.
"""

from html import escape
from typing import Optional
from urllib.parse import urlparse

from fastapi import APIRouter, HTTPException
from fastapi.responses import HTMLResponse

router = APIRouter()

SITE_NAME = "NewsAI"
# Where to send people when an article has no usable URL.
SITE_HOME = "https://newsai.app/"  # TODO: set to your Flutter app's public URL
# Public origin of this route, used for og:url. Should match SHARE_BASE_URL in the app.
SHARE_BASE_URL = "https://news-ai-d115c798.fastapicloud.dev"  # TODO: set per environment
DESCRIPTION_MAX = 200


def _get_article(article_id: int) -> Optional[dict]:
    """Return the article as a dict with keys title, summary, image_url, url, status.

    TODO: replace with your ORM query, e.g.
        row = db.query(Article).filter(Article.id == article_id).first()
    """
    raise NotImplementedError


def _safe_http_url(value: Optional[str]) -> Optional[str]:
    if not value:
        return None
    parsed = urlparse(value.strip())
    if parsed.scheme in ("http", "https") and parsed.netloc:
        return value.strip()
    return None


def _truncate(text: str, limit: int) -> str:
    text = " ".join(text.split())
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


@router.get("/s/{article_id}", response_class=HTMLResponse, include_in_schema=False)
def share_article(article_id: int) -> HTMLResponse:
    article = _get_article(article_id)
    if not article or article.get("status") is False:
        raise HTTPException(status_code=404, detail="Article not found")

    target = _safe_http_url(article.get("url")) or SITE_HOME
    image = _safe_http_url(article.get("image_url"))
    title = escape(article.get("title") or SITE_NAME)
    description = escape(_truncate(article.get("summary") or "", DESCRIPTION_MAX))
    share_url = escape(f"{SHARE_BASE_URL.rstrip('/')}/s/{article_id}")
    target_attr = escape(target)

    image_tags = (
        f'<meta property="og:image" content="{escape(image)}">\n'
        f'<meta name="twitter:image" content="{escape(image)}">\n'
        if image
        else ""
    )

    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>{title}</title>
<meta name="description" content="{description}">
<link rel="canonical" href="{target_attr}">
<meta property="og:type" content="article">
<meta property="og:site_name" content="{SITE_NAME}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{description}">
<meta property="og:url" content="{share_url}">
{image_tags}<meta name="twitter:card" content="{'summary_large_image' if image else 'summary'}">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{description}">
<meta http-equiv="refresh" content="0; url={target_attr}">
</head>
<body style="font-family:sans-serif;padding:24px">
<p>Redirecting to <a href="{target_attr}" rel="noopener">{title}</a>…</p>
</body>
</html>"""

    return HTMLResponse(
        content=html,
        headers={
            "Cache-Control": "public, max-age=3600",
            "X-Content-Type-Options": "nosniff",
            "Content-Security-Policy": "default-src 'none'; img-src https:; style-src 'unsafe-inline'",
            "Referrer-Policy": "strict-origin-when-cross-origin",
        },
    )


# In your app:  app.include_router(router)
