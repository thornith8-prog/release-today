# Search TopicId Continuation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pass `topicId` to `GET /search/` when searching after clicking a topic item, and omit `topicId` on fresh searches.

**Architecture:** Track `activeTopicId` (`RxnInt`) in `SearchBarController`, set it in `AppNav.goTopicEntries`, and clear it in `AppNav.goHome` / `AppNav.goMore`. Thread optional `topicId` through `AppNav.goSearch`, `/search` route in `router.dart`, `ResultsPage`, `ResultsController`, `NewsRepository.search`, and `ApiNewsRepository.search`.

**Tech Stack:** Flutter, GetX (`get`), `go_router`

**Spec:** `docs/superpowers/specs/2026-11-11-search-topic-id-design.md`

## Global Constraints

- `GET /search/` query parameter name for topic continuation is `topicId` (integer string in query map).
- Fresh searches (`topicId == null`) must NOT include `topicId` in the query parameters sent to `/search/` or in the `/search?q=...` route URI.

## Review Focus

- Fresh search from Home must send only `{Env.searchParam: query, 'limit': '$limit'}` without `topicId`.
- Search after clicking a topic item (`AppNav.goTopicEntries(42, 'AI')`) must send `{'q': query, 'limit': '20', 'topicId': '42'}`.
- Navigating back to Home (`AppNav.goHome()`) after selecting a topic must clear `activeTopicId` so the next search omits `topicId`.
- Searching two different queries within the same topic must create distinct `ResultsPage` keys and `ResultsController` tags (`'$query-${searchTopicId ?? ""}'`).

---

### Task 1: Repository, Controller, Navigation & Router `topicId` Support

**Files:**
- Modify: `lib/data/repositories/NewsRepository.dart`
- Modify: `lib/data/repositories/news_repository.dart`
- Modify: `lib/controllers/results_controller.dart`
- Modify: `lib/controllers/search_bar_controller.dart`
- Modify: `lib/core/navigation.dart`
- Modify: `lib/router.dart`
- Modify: `lib/features/results/results_page.dart`
- Create: `test/search_topic_id_test.dart`

- [ ] **Step 1: Write failing tests in `test/search_topic_id_test.dart`**
- [ ] **Step 2: Run `flutter test test/search_topic_id_test.dart` to verify it fails (RED)**
- [ ] **Step 3: Implement `topicId` support in repository, controllers, navigation, router, and results page (GREEN)**
- [ ] **Step 4: Run `flutter test test/search_topic_id_test.dart` and `flutter analyze` to verify all pass**
