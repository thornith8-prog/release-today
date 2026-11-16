# Search TopicId Continuation Design

## Intent & Why
When a user selects a topic item from the sidebar (`AppSidebar`), subsequent searches submitted from `PromptSearchBar` should include `topicId` in `GET /search/?q=...&topicId=...` so the backend continues that topic. When the user performs a fresh search (e.g., from Home or More without an active topic), `topicId` must be omitted from `GET /search/?q=...`.

## Goals, Non-goals, and Anti-goals
- **Goals:**
  - Set `SearchBarController.activeTopicId` when the user clicks a sidebar topic (`AppNav.goTopicEntries(topicId, label)`).
  - Clear `SearchBarController.activeTopicId` when the user navigates to Home (`AppNav.goHome()`) or More (`AppNav.goMore()`).
  - Pass `topicId` from `SearchBarController.submit` -> `AppNav.goSearch(q, topicId: activeTopicId.value)` -> `/search?q=...&topicId=...` (when non-null) -> `ResultsPage(query: q, searchTopicId: topicId)` -> `ResultsController(query: q, topicId: searchTopicId, repository: ...)` -> `ApiNewsRepository.search(query, limit: 20, topicId: topicId)`.
  - Include `'topicId': '$topicId'` in the `GET /search/` query map only when `topicId != null`.
- **Non-goals:**
  - Changing how `/topics/:topicId/entries` displays existing saved entries when first clicked.

## Approaches
1. **Store `activeTopicId` on `SearchBarController` + pass `topicId` in `/search` route query params (Selected):** Preserves topic context across follow-up searches and route changes until the user returns to Home/More for a fresh search.
2. **Parse current route URL only:** Loses `topicId` if `/search` does not carry `topicId`.
