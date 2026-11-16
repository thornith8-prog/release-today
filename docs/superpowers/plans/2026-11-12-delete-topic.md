# Delete Topic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to delete a topic from the sidebar via `DELETE /search-topic/topics/{topic_id}` with a confirmation dialog and in-place list update.

**Architecture:** Extend `TopicRepository` with `deleteTopic(int topicId)`, implement in `ApiTopicRepository` using `ApiClient.delete`, bind into `TopicsController.deleteTopic`, and add an `IconButton(icon: Icon(Icons.delete_outline))` with a confirmation dialog on the topic `ListTile` in `AppSidebar`.

**Tech Stack:** Flutter, GetX, Dart.

**Spec:** `docs/superpowers/specs/2026-11-12-delete-topic-design.md`

## Global Constraints
- Target endpoint: `DELETE ${Env.topicsPath}/{topic_id}` (`/search-topic/topics/{topic_id}`)
- Uses existing `ApiClient` with Bearer token authentication.
- Immediate UI removal upon successful deletion (`topicsItem.removeWhere((t) => t.id == topicId)`).

## Review Focus
- Topic ID is null (e.g. mock or empty item) - delete button should be hidden or disabled.
- Deletion API failure - displays error snackbar, does not remove item from list.
- User cancels the confirmation dialog - no API request is sent, item remains in list.
- Tapping delete button does not trigger `ListTile.onTap` (no unwanted navigation to topic entries).

---

### Task 1: Repository Method `deleteTopic`

**Files:**
- Modify: `lib/data/repositories/topic_repository.dart`
- Test: `test/delete_topic_test.dart`

**Interfaces:**
- Consumes: `ApiClient.delete`
- Produces: `Future<bool> deleteTopic(int topicId)` in `TopicRepository` and `ApiTopicRepository`

- [ ] **Step 1: Write failing test for `ApiTopicRepository.deleteTopic`**
In `test/delete_topic_test.dart`:
```dart
test('ApiTopicRepository.deleteTopic calls DELETE on topicsPath/topicId', () async {
  final client = _CapturingApiClient();
  final repo = ApiTopicRepository(client);
  final ok = await repo.deleteTopic(42);
  expect(ok, isTrue);
  expect(client.requestedMethod, 'DELETE');
  expect(client.requestedPath, '/search-topic/topics/42');
});
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/delete_topic_test.dart`
Expected: FAIL (method not defined)

- [ ] **Step 3: Implement `deleteTopic` in `TopicRepository` and `ApiTopicRepository`**
In `lib/data/repositories/topic_repository.dart`:
Add `Future<bool> deleteTopic(int topicId);` to `TopicRepository`.
In `ApiTopicRepository`:
```dart
@override
Future<bool> deleteTopic(int topicId) async {
  final response = await api.delete('${Env.topicsPath}/$topicId');
  if (response.status.hasError) {
    final detail = response.statusText?.trim();
    final code = response.statusCode;
    throw TopicApiException(
      (detail != null && detail.isNotEmpty)
          ? detail
          : 'Failed to delete topic (${code ?? "network/CORS error"})',
    );
  }
  return true;
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/delete_topic_test.dart`
Expected: PASS

---

### Task 2: Controller Method `deleteTopic`

**Files:**
- Modify: `lib/controllers/topics_controller.dart`
- Test: `test/delete_topic_test.dart`

**Interfaces:**
- Consumes: `TopicRepository.deleteTopic`
- Produces: `Future<bool> deleteTopic(int topicId)` in `TopicsController`

- [ ] **Step 1: Write failing test for `TopicsController.deleteTopic`**
In `test/delete_topic_test.dart`:
```dart
test('TopicsController.deleteTopic removes topic from topicsItem list', () async {
  final fakeRepo = _FakeTopicRepository();
  final controller = TopicsController(fakeRepo);
  controller.topicsItem.assignAll([
    TopicItems(id: 1, label: 'Tech'),
    TopicItems(id: 2, label: 'Science'),
  ]);

  final success = await controller.deleteTopic(1);
  expect(success, isTrue);
  expect(controller.topicsItem.length, 1);
  expect(controller.topicsItem.first.id, 2);
});
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/delete_topic_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement `deleteTopic` in `TopicsController`**
In `lib/controllers/topics_controller.dart`:
```dart
Future<bool> deleteTopic(int topicId) async {
  try {
    final success = await repository.deleteTopic(topicId);
    if (success) {
      topicsItem.removeWhere((item) => item.id == topicId);
    }
    return success;
  } catch (e) {
    debugPrint('Failed to delete topic $topicId: $e');
    return false;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/delete_topic_test.dart`
Expected: PASS

---

### Task 3: Delete Icon and Confirmation Dialog in `AppSidebar`

**Files:**
- Modify: `lib/features/shell/sidebar.dart`
- Test: `test/delete_topic_test.dart`

**Interfaces:**
- Consumes: `TopicsController.deleteTopic`, `TopicItems`
- Produces: Trailing delete `IconButton` on topic `ListTile` with dialog confirmation

- [ ] **Step 1: Write widget test for topic deletion in sidebar**
In `test/delete_topic_test.dart`:
Verify that tapping the delete icon shows the confirmation dialog, clicking Cancel does not delete, and clicking Delete calls `controller.deleteTopic(t.id)` and removes the tile.

- [ ] **Step 2: Run widget test to verify it fails**
Run: `flutter test test/delete_topic_test.dart`
Expected: FAIL

- [ ] **Step 3: Update `AppSidebar` with delete icon and confirmation dialog**
In `lib/features/shell/sidebar.dart`:
Add `trailing: IconButton(icon: Icon(Icons.delete_outline, size: 18), ...)` on topic `ListTile`.
Add `_confirmDeleteTopic(BuildContext context, TopicsController tc, TopicItems topic)` function showing `AlertDialog` with Cancel and Delete buttons, calling `tc.deleteTopic(topic.id!)`, and showing a `SnackBar`.

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/delete_topic_test.dart`
Expected: PASS

---

### Task 4: Static Analysis and Project Verification

**Files:**
- None (verification)

- [ ] **Step 1: Run flutter analyze**
Run: `flutter analyze lib test`
Expected: No errors

- [ ] **Step 2: Run all test suites**
Run: `flutter test test/delete_topic_test.dart test/recommendations_test.dart test/sidebar_test.dart`
Expected: All tests pass
