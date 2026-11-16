# Dynamic Settings Pages Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Dynamically fetch and display settings content (About Us, What We Do, Privacy, Terms) from `GET /settings/{slug}` with native HTML rendering and resilient static fallback.

**Architecture:** A `SettingsRepository` fetches dynamic HTML from the FastAPI backend. A zero-dependency `HtmlContentView` widget parses semantic HTML into themed Flutter text. A unified `SettingController` manages state and caching for the four settings routes (`/about`, `/what-we-do`, `/privacy`, `/terms`), falling back to existing static content on error or offline.

**Tech Stack:** Flutter, Dart, GetX, url_launcher.

**Spec:** `docs/superpowers/specs/2026-11-13-dynamic-settings-pages-design.md`

## Global Constraints
- Zero external package additions to `pubspec.yaml`.
- Maintain existing routes (`/about`, `/what-we-do`, `/privacy`, `/terms`) and `Navigation` helper methods.
- Consistent layout padding (`Breakpoints.pagePadding(context)`) and responsive maximum width (`1100`).
- Seamless offline fallback: never display a blank page or error screen for informational/legal pages when the backend is unreachable.

## Review Focus
- Malformed HTML or unclosed tags in `content_html` — parser handles without throwing or crashing.
- Slugs with `null` or empty `content_html` — smoothly displays fallback static content.
- Network timeouts or HTTP 500/404 — silently and immediately activates fallback static content.
- External links (`<a href="...">`) inside HTML — tapped links invoke `url_launcher` safely.
- Rapid tab switching between `/about`, `/terms`, `/privacy`, `/what-we-do` — cached setting loads synchronously without flicker.

---

### Task 1: Setting Model and Deserialization

**Files:**
- Create: `lib/data/models/setting.dart`
- Test: `test/data/models/setting_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class Setting {
    final int id;
    final String slug;
    final String title;
    final String contentHtml;
    final DateTime? createdAt;
    final DateTime? updatedAt;

    Setting({
      required this.id,
      required this.slug,
      required this.title,
      required this.contentHtml,
      this.createdAt,
      this.updatedAt,
    });

    factory Setting.fromJson(Map<String, dynamic> json);
    Map<String, dynamic> toJson();
  }
  ```

- [x] **Step 1: Write the failing unit tests for `Setting`**

Create `test/data/models/setting_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:newsai/data/models/setting.dart';

void main() {
  group('Setting model', () {
    test('parses direct JSON map', () {
      final json = {
        'id': 1,
        'slug': 'about-us',
        'title': 'About Us',
        'content_html': '<h2>About NewsAI</h2><p>Description</p>',
        'created_at': '2026-11-13T12:54:00.134570+07:00',
        'updated_at': '2026-11-13T12:54:00.134607+07:00',
      };
      final setting = Setting.fromJson(json);
      expect(setting.id, 1);
      expect(setting.slug, 'about-us');
      expect(setting.title, 'About Us');
      expect(setting.contentHtml, '<h2>About NewsAI</h2><p>Description</p>');
      expect(setting.updatedAt, isNotNull);
    });

    test('parses ApiResponse envelope when json contains data field', () {
      final json = {
        'code': 0,
        'status': 'success',
        'message': '',
        'data': {
          'id': 2,
          'slug': 'what-we-do',
          'title': 'What We Do',
          'content_html': '<p>We aggregate news</p>',
        }
      };
      final setting = Setting.fromJson(json);
      expect(setting.id, 2);
      expect(setting.slug, 'what-we-do');
      expect(setting.title, 'What We Do');
      expect(setting.contentHtml, '<p>We aggregate news</p>');
    });

    test('handles empty or missing content_html gracefully', () {
      final json = {
        'id': 3,
        'slug': 'privacy',
        'title': 'Privacy',
      };
      final setting = Setting.fromJson(json);
      expect(setting.contentHtml, '');
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/models/setting_test.dart`
Expected: FAIL with compilation error (cannot find `lib/data/models/setting.dart`).

- [x] **Step 3: Implement `Setting` in `lib/data/models/setting.dart`**

Implement `Setting` class with `fromJson` handling both direct attributes and envelope `data` wrapper.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/models/setting_test.dart`
Expected: PASS.

---

### Task 2: Settings Repository

**Files:**
- Create: `lib/data/repositories/settings_repository.dart`
- Modify: `lib/core/app_binding.dart:20-31`
- Test: `test/data/repositories/settings_repository_test.dart`

**Interfaces:**
- Consumes: `ApiClient` from `lib/services/api_client.dart` and `Setting` from `lib/data/models/setting.dart`
- Produces:
  ```dart
  abstract class SettingsRepository {
    Future<Setting> getSetting(String slug);
  }

  class ApiSettingsRepository implements SettingsRepository {
    final ApiClient api;
    ApiSettingsRepository(this.api);
    @override
    Future<Setting> getSetting(String slug);
  }
  ```

- [x] **Step 1: Write failing unit test for `SettingsRepository`**

Create `test/data/repositories/settings_repository_test.dart`:
```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newsai/data/repositories/settings_repository.dart';
import 'package:newsai/services/api_client.dart';

void main() {
  group('ApiSettingsRepository', () {
    test('fetches setting successfully from /settings/{slug}', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/settings/about-us') {
          return http.Response(
            jsonEncode({
              'code': 0,
              'status': 'success',
              'data': {
                'id': 1,
                'slug': 'about-us',
                'title': 'About Us',
                'content_html': '<p>About dynamic content</p>',
              }
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiSettingsRepository(apiClient);

      final setting = await repo.getSetting('about-us');
      expect(setting.slug, 'about-us');
      expect(setting.title, 'About Us');
      expect(setting.contentHtml, '<p>About dynamic content</p>');
    });

    test('throws exception when API returns error status', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final apiClient = ApiClient(client: mockClient);
      final repo = ApiSettingsRepository(apiClient);

      expect(() => repo.getSetting('privacy'), throwsA(isA<Exception>()));
    });
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/data/repositories/settings_repository_test.dart`
Expected: FAIL with compilation error (file not found).

- [x] **Step 3: Implement `ApiSettingsRepository` in `lib/data/repositories/settings_repository.dart` and register in `AppBinding`**

Implement `ApiSettingsRepository` using `api.get('/settings/$slug')`.
Register `Get.put(ApiSettingsRepository(Get.find<ApiClient>()), permanent: true);` in `lib/core/app_binding.dart`.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/data/repositories/settings_repository_test.dart`
Expected: PASS.

---

### Task 3: Zero-Dependency HTML Content Renderer Widget

**Files:**
- Create: `lib/widgets/html_content_view.dart`
- Test: `test/widgets/html_content_view_test.dart`

**Interfaces:**
- Produces:
  ```dart
  class HtmlContentView extends StatelessWidget {
    final String html;
    const HtmlContentView({super.key, required this.html});
  }
  ```

- [x] **Step 1: Write failing widget test for `HtmlContentView`**

Create `test/widgets/html_content_view_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsai/widgets/html_content_view.dart';

void main() {
  testWidgets('renders headings, paragraphs, and list items without errors', (tester) async {
    const html = '''
      <h2>Main Heading</h2>
      <p>This is a paragraph with <strong>bold text</strong> and <em>italic text</em>.</p>
      <ul>
        <li>First item</li>
        <li>Second item</li>
      </ul>
    ''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlContentView(html: html),
        ),
      ),
    );

    expect(find.text('Main Heading'), findsOneWidget);
    expect(find.textContaining('This is a paragraph'), findsOneWidget);
    expect(find.textContaining('First item'), findsOneWidget);
    expect(find.textContaining('Second item'), findsOneWidget);
  });

  testWidgets('handles malformed or unclosed html tags safely', (tester) async {
    const malformedHtml = '<h2>Unclosed heading<p>Nested unclosed paragraph <b>bold';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlContentView(html: malformedHtml),
        ),
      ),
    );

    expect(find.textContaining('Unclosed heading'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/html_content_view_test.dart`
Expected: FAIL with compilation error (widget not found).

- [x] **Step 3: Implement `HtmlContentView` in `lib/widgets/html_content_view.dart`**

Implement a robust regex/token-based block parser:
- Splits HTML into blocks (`<h1>-<h4>`, `<p>`, `<ul>`, `<ol>`, `<li>`, `<hr>`).
- Parses inline formatting (`<strong>`, `<b>`, `<em>`, `<i>`, `<a>`, `<br>`) into `TextSpan`.
- When an `<a>` link is tapped, invokes `launchUrl(Uri.parse(href))` safely.
- Gracefully handles unknown or unclosed tags by stripping or rendering text spans.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/html_content_view_test.dart`
Expected: PASS.

---

### Task 4: Dynamic Setting Controller & Setting Page Integration

**Files:**
- Create: `lib/controllers/setting_controller.dart`
- Create: `lib/features/more/setting_page.dart`
- Modify: `lib/features/more/about_us_page.dart`
- Modify: `lib/features/more/what_we_do_page.dart`
- Modify: `lib/features/more/privacy_page.dart`
- Modify: `lib/features/more/terms_page.dart`
- Test: `test/features/more/setting_page_test.dart`

**Interfaces:**
- Consumes: `SettingsRepository` from `lib/data/repositories/settings_repository.dart`, `HtmlContentView` from `lib/widgets/html_content_view.dart`.
- Produces:
  ```dart
  class SettingController extends GetxController {
    final SettingsRepository repository;
    final String slug;
    SettingController({required this.repository, required this.slug});

    final Rx<Setting?> setting = Rx<Setting?>(null);
    final RxBool isLoading = false.obs;
    final RxnString error = RxnString(null);

    Future<void> loadSetting({bool force = false});
  }

  class SettingPage extends StatelessWidget {
    final String slug;
    final String defaultTitle;
    final Widget fallbackContent;
    final Widget? footer;

    const SettingPage({
      super.key,
      required this.slug,
      required this.defaultTitle,
      required this.fallbackContent,
      this.footer,
    });
  }
  ```

- [x] **Step 1: Write failing widget test for dynamic loading and fallback**

Create `test/features/more/setting_page_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:newsai/controllers/setting_controller.dart';
import 'package:newsai/data/models/setting.dart';
import 'package:newsai/data/repositories/settings_repository.dart';
import 'package:newsai/features/more/setting_page.dart';

class FakeSettingsRepo implements SettingsRepository {
  final Setting? Function(String slug) onFetch;
  FakeSettingsRepo(this.onFetch);

  @override
  Future<Setting> getSetting(String slug) async {
    final res = onFetch(slug);
    if (res == null) throw Exception('Network error');
    return res;
  }
}

void main() {
  tearDown(() => Get.reset());

  testWidgets('displays dynamic content when API succeeds', (tester) async {
    final repo = FakeSettingsRepo((slug) => Setting(
      id: 1,
      slug: 'about-us',
      title: 'Dynamic About Title',
      contentHtml: '<p>Dynamic About Body from Backend</p>',
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingPage(
            slug: 'about-us',
            defaultTitle: 'Default About Title',
            fallbackContent: const Text('Static Fallback Content'),
            repository: repo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dynamic About Title'), findsOneWidget);
    expect(find.textContaining('Dynamic About Body from Backend'), findsOneWidget);
    expect(find.text('Static Fallback Content'), findsNothing);
  });

  testWidgets('displays fallback content seamlessly when API fails', (tester) async {
    final repo = FakeSettingsRepo((slug) => null); // Triggers Exception

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingPage(
            slug: 'about-us',
            defaultTitle: 'Default About Title',
            fallbackContent: const Text('Static Fallback Content'),
            repository: repo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Default About Title'), findsOneWidget);
    expect(find.text('Static Fallback Content'), findsOneWidget);
  });
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/more/setting_page_test.dart`
Expected: FAIL with compilation error (classes not found).

- [x] **Step 3: Implement `SettingController` and `SettingPage`, and update `AboutUsPage`, `WhatWeDoPage`, `PrivacyPage`, and `TermsPage`**

1. Implement `SettingController` in `lib/controllers/setting_controller.dart`. Keep an in-memory cache map `static final Map<String, Setting> _cache = {}` to prevent repeat calls on page navigation.
2. Implement `SettingPage` in `lib/features/more/setting_page.dart`. Use `GetBuilder` or `Obx` to render `HtmlContentView(html: setting.contentHtml)` when available, or `fallbackContent` if `setting == null`.
3. Refactor `AboutUsPage`, `WhatWeDoPage`, `PrivacyPage`, and `TermsPage` to wrap their existing content tree inside `SettingPage(slug: '...', defaultTitle: '...', fallbackContent: ...)` so their existing static widgets become the fallback. Keep the contact footer on `AboutUsPage`.

- [x] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/more/setting_page_test.dart`
Expected: PASS.

---

### Task 5: Full Test Suite Verification

**Files:**
- Test all: `test/`

- [x] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: All tests pass with zero failures.

- [x] **Step 2: Verify code formatting and analysis**

Run: `dart analyze`
Expected: No issues found (or 0 errors/warnings).
