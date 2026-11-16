# Delete Topic: Design

**Date:** 2026-11-12 · **Size:** Small change (short design)

## Intent
Allow users to delete a saved search topic from the sidebar "Recent" list. When a user clicks the delete icon on a topic, a confirmation dialog appears. Confirming calls `DELETE /search-topic/topics/{topic_id}` and removes the topic from the list in-place.

## Goals
- Add `deleteTopic(int topicId)` to `TopicRepository` and `ApiTopicRepository` calling `DELETE /search-topic/topics/{topic_id}` using `ApiClient.delete`.
- Add `deleteTopic(int topicId)` to `TopicsController` that updates `topicsItem` in-place on success.
- Add a delete icon button (`Icons.delete_outline`) on each topic's `ListTile.trailing` in `AppSidebar`.
- Show a confirmation dialog before executing the deletion to prevent accidental loss of search history.
- Show feedback (snackbar) on deletion success or error.
- Verify with unit and widget tests.

## Non-goals / Anti-goals
- Non-goal: Bulk deletion of all topics.
- Anti-goal: Silently deleting topics without confirmation.

## Approaches Considered
1. **Approach A (With Confirmation Dialog - Selected):**
   - User taps trash icon -> Confirmation dialog appears -> If confirmed, sends `DELETE` request and removes topic from list.
   - *Why chosen:* Protects against accidental clicks on mobile and desktop web.
2. **Approach B (Instant Deletion):**
   - User taps trash icon -> Deletes immediately with no confirmation.
   - *Why rejected:* High risk of accidental deletions.

## Technical Details
- `TopicRepository`: `Future<bool> deleteTopic(int topicId);`
- `ApiTopicRepository`:
  ```dart
  @override
  Future<bool> deleteTopic(int topicId) async {
    final response = await api.delete('${Env.topicsPath}/$topicId');
    if (response.status.hasError) {
      throw TopicApiException(response.statusText ?? 'Failed to delete topic');
    }
    return true;
  }
  ```
- `TopicsController`:
  ```dart
  Future<bool> deleteTopic(int topicId) async {
    try {
      final success = await repository.deleteTopic(topicId);
      if (success) {
        topicsItem.removeWhere((item) => item.id == topicId);
      }
      return success;
    } catch (e) {
      // capture error and return false
      return false;
    }
  }
  ```
- `AppSidebar`:
  In topic `ListTile`:
  ```dart
  trailing: IconButton(
    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
    tooltip: 'Delete topic',
    onPressed: () => _confirmDeleteTopic(context, tc, t),
  )
  ```
