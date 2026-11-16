# Dynamic Settings Pages: Design

**Date:** 2026-11-13 · **Size:** small change (short design)

## Intent
Allow the app to dynamically load and display content for **About Us**, **What We Do**, **Privacy Policy**, and **Terms of Service** from the backend `GET /settings/{slug}` endpoint, while seamlessly falling back to existing bundled text if offline or if the backend request fails.

## Goals / Non-goals / Anti-goals
- **Goals:**
  - Introduce `Setting` data model (`id`, `slug`, `title`, `content_html`, `updated_at`).
  - Introduce `SettingsRepository` with `Future<Setting> getSetting(String slug)` using existing `ApiClient`.
  - Wire the 4 pages to their backend slugs:
    - `/about` ➔ `about-us`
    - `/what-we-do` ➔ `what-we-do`
    - `/privacy` ➔ `privacy`
    - `/terms` ➔ `terms`
  - Zero external package additions: provide a lightweight editorial HTML parser widget (`HtmlContentView`) that translates standard tags (`<h2>`, `<h3>`, `<p>`, `<ul>`, `<ol>`, `<li>`, `<a>`, `<strong>`, `<em>`, `<br>`) into Flutter typography (`headlineSmall`, `titleLarge`, `bodyLarge`).
  - Fallback resiliency: if the API request fails, times out, or returns invalid data, seamlessly display the existing hardcoded static content so the screen is never broken or blank.
- **Non-goals:**
  - Admin editing UI (handled separately by the FastAPI backend admin routes).
  - Heavy WebView or large third-party HTML parser dependencies.
- **Anti-goals:**
  - Disrupting current route URLs (`/about`, `/what-we-do`, `/privacy`, `/terms`).
  - Showing jarring error states for core informational and legal pages when offline.

## Approaches Considered
| | Approach | Verdict |
|---|---|---|
| 1 | **Unified Dynamic Setting Page with Lightweight HTML Parser & Fallback** | **Picked.** Matches app typography, zero new package dependencies, keeps code DRY, and provides graceful offline fallback. |
| 2 | Full HTML package (`flutter_widget_from_html`) with API-only states | Rejected: adds extra package dependency weight and shows error screens on network failures instead of fallback text. |
| 3 | Per-page duplicate fetch logic in each existing static file | Rejected: creates repetitive loading/error state code across 4 files. |

## Design

### 1. Data Layer
- **Model** (`lib/data/models/setting.dart`):
  `Setting` with fields:
  - `final int id`
  - `final String slug`
  - `final String title`
  - `final String contentHtml`
  - `final DateTime? updatedAt`
  - Factory `Setting.fromJson(Map<String, dynamic> json)` parsing standard FastAPI `ApiResponse[SettingResponse]` wrapper or raw payload.
- **Repository** (`lib/data/repositories/settings_repository.dart`):
  `SettingsRepository` interface & `ApiSettingsRepository` implementation:
  - `Future<Setting> getSetting(String slug)` ➔ `GET /settings/{slug}`.
  - Registers into GetX or dependency setup alongside other repositories.

### 2. HTML to Flutter Widget Renderer
- **Widget** (`lib/widgets/html_content_view.dart`):
  A clean, lightweight zero-dependency parser for standard editorial tags:
  - `<h1>`, `<h2>`, `<h3>`: `Theme.of(context).textTheme.titleLarge` with appropriate font weight and spacing.
  - `<p>`: `Theme.of(context).textTheme.bodyLarge` with line height 1.7 and `AppColors.ink`.
  - `<ul>`, `<ol>`, `<li>`: Indented bullet/numbered rows.
  - `<a>`: Clickable link calling `url_launcher`.
  - `<strong>`, `<b>`, `<em>`, `<i>`: Inline formatting using `TextSpan`.
  - `<br>`: Newline separation.

### 3. Presentation Layer
- **Controller** (`lib/controllers/setting_controller.dart`):
  - Manages `Rx<Setting?> setting`, `RxBool isLoading`, and `RxnString error`.
  - In-memory cache for loaded slugs during session so navigation between tabs is instant.
- **Page Views** (`lib/features/more/`):
  - A shared `SettingPage(slug: '...', defaultTitle: '...', fallbackBuilder: ...)` or update each page to use the shared setting controller.
  - While loading: if no cache exists, shows existing static content or lightweight shimmer/skeleton; when API response arrives, updates content seamlessly.
  - On error / offline: renders the fallback static content that currently exists in `AboutUsPage`, `WhatWeDoPage`, `TermsPage`, `PrivacyPage`.
  - Preserves custom additions (e.g. contact email section on About Us).

### 4. Router & Navigation
- No changes to URL paths or `Navigation` helper methods (`/about`, `/what-we-do`, `/terms`, `/privacy` remain identical).

## Left to the Builder
- Tag parsing edge cases and sanitization.
- Fine-tuning exact heading vertical margins to match the current look and feel.

## Verification
- Unit tests:
  - `test/data/models/setting_test.dart`: verifies `Setting.fromJson` parsing.
  - `test/data/repositories/settings_repository_test.dart`: verifies API fetch, response extraction, and error handling.
  - `test/widgets/html_content_view_test.dart`: verifies HTML tags render appropriate Text / RichText spans.
- Widget tests:
  - Verify that setting pages display dynamic API content when successful.
  - Verify that setting pages display fallback content when API request fails.
- Run `flutter test` to ensure all tests pass.
