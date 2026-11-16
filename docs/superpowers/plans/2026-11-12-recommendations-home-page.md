# Load Recommendations in Home Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Configure the home page latest news feed to load recommendations from `/recommendations/?limit=20`, support it in the local dev CORS proxy, and verify with tests.

**Architecture:** Use the existing configurable environment architecture (`Env.latestPath`) so that `HomeController` queries `/recommendations/?skip=0&limit=20` via `ApiNewsRepository`. Update `tool/cors_proxy.dart` to allow `/recommendations` without 403 Forbidden.

**Tech Stack:** Flutter Web, GetX, Dart.

**Spec:** `docs/superpowers/specs/2026-11-12-recommendations-home-page-design.md`

## Global Constraints
- Target endpoint: `https://news-ai-d115c798.fastapicloud.dev/recommendations/?limit=20`
- Backward compatibility: `.env` key `NEWS_API_LATEST_PATH` overrides default.
- Default path in `Env.latestPath`: `/recommendations/`
- Local dev CORS proxy port: `8787` (`tool/cors_proxy.dart`)

## Review Focus
- Local proxy blocks `/recommendations` when tested with `NEWS_API_USE_CORS_PROXY=true`.
- Default value of `Env.latestPath` when `.env` is absent or uninitialized must be `/recommendations/`.
- `HomeController.fetch()` fetches with `limit: 20`.
- Handling empty or null data response from `/recommendations/` gracefully.
- Response parsing handles both snake_case (`image_url`, `logo_url`) and camelCase.

---

### Task 1: Update Environment Defaults and Config Files

**Files:**
- Modify: `lib/core/env.dart:38`
- Modify: `.env:5`
- Modify: `.env.example:5`

**Interfaces:**
- Consumes: none
- Produces: `Env.latestPath` returns `/recommendations/`

- [ ] **Step 1: Write test verifying `Env.latestPath` defaults to `/recommendations/`**
In `test/recommendations_test.dart`:
```dart
test('Env.latestPath defaults to /recommendations/', () {
  expect(Env.latestPath, contains('/recommendations/'));
});
```

- [ ] **Step 2: Run test to check current behavior**
Run: `flutter test test/recommendations_test.dart`

- [ ] **Step 3: Update `Env.latestPath`, `.env`, and `.env.example`**
In `lib/core/env.dart`:
```dart
static String get latestPath => _get('NEWS_API_LATEST_PATH', '/recommendations/');
```
In `.env` and `.env.example`:
```
NEWS_API_LATEST_PATH=/recommendations/
```

- [ ] **Step 4: Re-run test to verify it passes**
Run: `flutter test test/recommendations_test.dart`
Expected: PASS

---

### Task 2: Update Local CORS Proxy to Allow `/recommendations`

**Files:**
- Modify: `tool/cors_proxy.dart:49-56`

**Interfaces:**
- Consumes: HTTP request path
- Produces: Proxy forwarding for paths starting with `/recommendations`

- [ ] **Step 1: Inspect `tool/cors_proxy.dart` path filter check**
Locate the existing path check:
```dart
    final path = req.uri.path;
    if (!path.startsWith('/articles') &&
        !path.startsWith('/search') &&
        !path.startsWith('/health')) {
      res.statusCode = HttpStatus.forbidden;
      await res.close();
      continue;
    }
```

- [ ] **Step 2: Add `/recommendations` to allowed paths**
Update check to:
```dart
    final path = req.uri.path;
    if (!path.startsWith('/articles') &&
        !path.startsWith('/search') &&
        !path.startsWith('/health') &&
        !path.startsWith('/recommendations')) {
      res.statusCode = HttpStatus.forbidden;
      await res.close();
      continue;
    }
```

---

### Task 3: Test `HomeController` and `ApiNewsRepository` with `/recommendations/`

**Files:**
- Create/Update: `test/recommendations_test.dart`

**Interfaces:**
- Consumes: `HomeController`, `ApiNewsRepository`, `ApiClient`
- Produces: Verified loading of recommendations with limit 20

- [ ] **Step 1: Add mock / test case for `HomeController` loading recommendations**
In `test/recommendations_test.dart`:
Verify that `HomeController.load()` invokes `repository.latest(skip: 0, limit: 20)` which requests `Env.latestPath` (`/recommendations/`) with `limit=20` and loads the articles into `controller.articles`.

- [ ] **Step 2: Run the recommendations test**
Run: `flutter test test/recommendations_test.dart`
Expected: PASS

---

### Task 4: Static Analysis and Project Verification

**Files:**
- None (verification)

- [ ] **Step 1: Run flutter analyze**
Run: `flutter analyze lib`
Expected: No errors

- [ ] **Step 2: Verify `dart run tool/cors_proxy.dart` compiles cleanly**
Run: `dart analyze tool/cors_proxy.dart`
Expected: No errors
