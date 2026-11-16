# Continuous Chat Flow for Results Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the search results page into a continuous, multi-turn chat stream where follow-up searches—both within an existing topic and across fresh searches—append new user and assistant message turns in-place without reloading or navigating to a new page.

**Architecture:** 
1. Introduce a `ChatTurn` model representing a conversation turn (user prompt, timestamp, list of results, loading status, error status).
2. Extend `SearchBarController` with an `onSearchSubmitted` handler that active chat pages can register with. When registered, submitting a search dispatches in-place to the active chat session instead of triggering GoRouter route teardown; when unregistered (e.g. on Home/More), it routes via `AppNav.goSearch` as before.
3. Enhance `TopicEntryController` to preserve individual `TopicEntryItem`s as distinct historical chat turns.
4. Update `ResultsPage` to render a unified, chronological list of chat turns (each with its user bubble and assistant bubble with typing indicator, error banner, or result tiles) and auto-scroll to the latest turn upon follow-up searches.

**Tech Stack:** Flutter, GetX state management, GoRouter.

**Spec:** Requirement from user:
- Existing chat from existing topic: if user searches again, keep existing list and add new data to list like a chat list.
- Fresh search: if user searches "What is the best news today" and results appear, and then searches again "Give me the latest news", results must show in the same list like a chat system.

## Global Constraints
- Preserve backward compatibility for existing controller methods and properties: `articles`, `entries`, `isLoading`, `error`, `load()` on both `ResultsController` and `TopicEntryController`.
- All existing tests in `test/widget_test.dart`, `test/search_topic_id_test.dart`, and `test/partner_test.dart` must pass without regressions.
- Preserve mobile/desktop responsiveness and styling with `AppColors`.

## Review Focus
- Input: Multiple rapid searches before the previous search finishes. Expected: Each turn maintains its own independent loading state and results without race conditions.
- Input: User clicking a topic in the sidebar while viewing search results. Expected: Proper route navigation to the selected topic's chat history.
- Input: User navigating to Home and performing a fresh search. Expected: `onSearchSubmitted` is properly cleaned up on page disposal, so the fresh search routes to `/search` cleanly.
- Input: Topic with multiple historical `TopicEntryItem` entries. Expected: Correct chronological rendering of all past turns.
- Input: Search error in a follow-up turn. Expected: Only that specific turn displays the error banner and retry button; prior turns remain intact.

---

### Task 1: Chat Turn Model & SearchBarController Callback

**Files:**
- Create: `lib/data/models/chat_turn.dart`
- Modify: `lib/controllers/search_bar_controller.dart`
- Test: `test/chat_turn_test.dart`

**Interfaces:**
- `ChatTurn`:
  ```dart
  class ChatTurn {
    final String prompt;
    final DateTime timestamp;
    final RxList<ArticleData> articles;
    final RxBool isLoading;
    final RxnString error;
    ChatTurn({
      required this.prompt,
      DateTime? timestamp,
      List<ArticleData>? articles,
      bool isLoading = false,
      String? error,
    });
  }
  ```
- `SearchBarController`:
  - `void Function(String query)? onSearchSubmitted`
  - `void submit([String? value])`: if `onSearchSubmitted != null`, invokes it; otherwise calls `AppNav.goSearch(q, topicId: activeTopicId.value)`.

- [ ] **Step 1: Write unit tests in `test/chat_turn_test.dart`**
  - Verify `ChatTurn` initializes with defaults, reactive articles, and loading state.
  - Verify `SearchBarController.submit()` invokes `onSearchSubmitted` when set, and delegates to `AppNav.goSearch` when null.

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/chat_turn_test.dart`
  Expected: FAIL with compilation error (ChatTurn not defined / onSearchSubmitted not defined).

- [ ] **Step 3: Implement `ChatTurn` in `lib/data/models/chat_turn.dart`**
  Implement the reactive `ChatTurn` model.

- [ ] **Step 4: Update `SearchBarController` in `lib/controllers/search_bar_controller.dart`**
  Add `onSearchSubmitted` hook and use it in `submit()`.

- [ ] **Step 5: Run tests to verify they pass**
  Run: `flutter test test/chat_turn_test.dart`
  Expected: PASS

---

### Task 2: Multi-turn Chat Management in Topic & Search Controllers

**Files:**
- Modify: `lib/controllers/topic_entry_controller.dart`
- Modify: `lib/controllers/results_controller.dart`
- Test: `test/multi_turn_controller_test.dart`

**Interfaces:**
- `TopicEntryController`:
  - `final turns = <ChatTurn>[].obs`
  - `Future<void> appendSearch(String query, ApiNewsRepository newsRepo)`: appends a new `ChatTurn(prompt: query, isLoading: true)`, calls `newsRepo.search(query, topicId: topicId)`, updates the turn with articles or error.
  - Preserves existing `entries`, `isLoading`, `load()`, `loadMore()`.
- `ResultsController`:
  - `final turns = <ChatTurn>[].obs`
  - `Future<void> appendSearch(String query)`: appends a new `ChatTurn(prompt: query, isLoading: true)`, calls `repository.search(query, topicId: topicId)`, updates the turn with articles or error.
  - Preserves existing `articles`, `isLoading`, `load()`.

- [ ] **Step 1: Write unit tests in `test/multi_turn_controller_test.dart`**
  - Test `ResultsController.appendSearch()` appends turns sequentially, updating loading and article lists.
  - Test `TopicEntryController` parses `items` into `turns`, and `appendSearch()` adds a new turn to the existing topic.

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/multi_turn_controller_test.dart`
  Expected: FAIL

- [ ] **Step 3: Update `ResultsController` and `TopicEntryController`**
  Implement `turns` and `appendSearch` in both controllers while preserving all existing methods and fields.

- [ ] **Step 4: Run tests to verify they pass**
  Run: `flutter test test/multi_turn_controller_test.dart`
  Expected: PASS

---

### Task 3: Chat Results Page UI with Continuous Turns & In-Place Search

**Files:**
- Modify: `lib/features/results/results_page.dart`
- Test: `test/results_page_chat_flow_test.dart`

**Interfaces:**
- `ResultsPage`:
  - In `initState()` / controller bindings: registers `searchBarController.onSearchSubmitted = (query) => controller.appendSearch(query)`.
  - In `dispose()`: unregisters `searchBarController.onSearchSubmitted`.
  - UI renders a single scrollable ListView containing all turns sequentially:
    - User message bubble with prompt and timestamp
    - Assistant message bubble with typing indicator, error banner, or article result items
  - Automatically scrolls to the bottom when a new turn is appended.

- [ ] **Step 1: Write widget test in `test/results_page_chat_flow_test.dart`**
  - Verify that submitting a second search query from the search bar appends a second turn without rebuilding the page or clearing the first query's results.

- [ ] **Step 2: Run test to verify it fails**
  Run: `flutter test test/results_page_chat_flow_test.dart`
  Expected: FAIL

- [ ] **Step 3: Refactor `ResultsPage` in `lib/features/results/results_page.dart`**
  - Render list of `ChatTurn`s.
  - Bind `SearchBarController.onSearchSubmitted` to `appendSearch` and scroll to bottom.
  - Handle retry on individual failed turns.

- [ ] **Step 4: Run widget tests to verify they pass**
  Run: `flutter test test/results_page_chat_flow_test.dart`
  Expected: PASS

---

### Task 4: Full Suite Regression Verification

**Files:**
- Test: `test/widget_test.dart`
- Test: `test/search_topic_id_test.dart`
- Test: `test/partner_test.dart`

- [ ] **Step 1: Run all existing and new tests**
  Run: `flutter test`
  Expected: All tests pass with zero failures.
