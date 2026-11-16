# Partner Home Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Partners section under "The latest news" on the home screen that loads `GET /partners?page=1&limit=50` into the `Partner` model and renders small circular partner items that redirect to each partner's `url` on tap.

**Architecture:** Introduce `ApiPartnerRepository` and `PartnerController` (registered permanently in `AppBinding`) to fetch `/partners?page=1&limit=50` via `ApiClient`, parse with `Partner.fromJson`, filter active items, and sort by `displayOrder`. Render a `Partners` section on `HomePage` below the latest news carousel using a `PartnerCircle` widget (`48x48` circular logo with `url_launcher` redirect).

**Tech Stack:** Flutter, GetX (`get`), `url_launcher`, `flutter_dotenv`

**Spec:** `docs/superpowers/specs/2026-11-11-partner-home-section-design.md`

## Global Constraints

- Base URL comes from `Env.apiUrl` (`https://news-ai-d115c798.fastapicloud.dev`), endpoint path from `Env.partnersPath` (`/partners`), query `page=1&limit=50`.
- Model must use `Partner` and `Items` in `lib/data/models/partner.dart`.
- Only `http` and `https` URLs may be launched via `launchUrl(uri, webOnlyWindowName: '_blank')` (prevents `javascript:` / open-scheme XSS).

## Review Focus

- Partner item with `isActive: false` must be excluded from `PartnerController.partners`.
- Partner items with out-of-order `displayOrder` values (or `null`) must be sorted ascending (`null` treated as `0`).
- Partner item with empty, null, or non-http(s) `url` (e.g. `javascript:alert(1)`) must not call `launchUrl` or throw on tap.
- Partner item with null or empty `logoUrl` must render the fallback icon without throwing.
- Backend returning an error status or malformed JSON must surface a clean `PartnerApiException` message in `PartnerController.error`.

## Verification Plan

### Automated Security Check

- **Security Scanner**: Run a scan on all newly created files to identify common vulnerabilities (e.g., XSS, SQL injection). If findings are detected, auto-apply the fix and document the results.
- **Security Audit**: Audit the new code for design-level security issues (input validation, secrets handling, auth checks, URL scheme validation against `javascript:` XSS, framework-native text escaping, HTTPS transport). Document findings and remediations in the `walkthrough.md` artifact using the `generate_security_audit_report` skill.

---

### Task 1: Partner Repository & Controller

**Files:**
- Modify: `.env`
- Modify: `lib/core/env.dart`
- Create: `lib/data/repositories/partner_repository.dart`
- Create: `lib/controllers/partner_controller.dart`
- Test: `test/partner_test.dart`

**Interfaces:**
- Consumes: `ApiClient` (`lib/services/api_client.dart`), `Partner` / `Items` (`lib/data/models/partner.dart`)
- Produces:
  - `Env.partnersPath` (`String`, defaults to `'/partners'`)
  - `abstract class PartnerRepository { Future<Partner> partners({int page = 1, int limit = 50}); }`
  - `class ApiPartnerRepository implements PartnerRepository`
  - `class PartnerController extends GetxController` with `final partners = <Items>[].obs;`, `final isLoading = true.obs;`, `final error = RxnString();`, `Future<void> load({int page = 1, int limit = 50})`

- [ ] **Step 1: Write the failing tests in `test/partner_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:newsai/controllers/partner_controller.dart';
import 'package:newsai/data/models/partner.dart';
import 'package:newsai/data/repositories/partner_repository.dart';

class _FakePartnerRepository implements PartnerRepository {
  _FakePartnerRepository(this.responder);
  final Future<Partner> Function(int page, int limit) responder;

  @override
  Future<Partner> partners({int page = 1, int limit = 50}) =>
      responder(page, limit);
}

void main() {
  test('PartnerController filters inactive items and sorts by displayOrder', () async {
    final repo = _FakePartnerRepository((page, limit) async {
      expect(page, 1);
      expect(limit, 50);
      return Partner.fromJson({
        'code': 0,
        'status': 'success',
        'data': {
          'total': 3,
          'page': 1,
          'limit': 50,
          'total_pages': 1,
          'items': [
            {'id': 2, 'name': 'Second', 'url': 'https://b.example.com', 'is_active': true, 'display_order': 2},
            {'id': 3, 'name': 'Inactive', 'url': 'https://c.example.com', 'is_active': false, 'display_order': 0},
            {'id': 1, 'name': 'First', 'url': 'https://a.example.com', 'is_active': true, 'display_order': 1},
          ],
        },
      });
    });

    final controller = PartnerController(repo);
    await controller.load();

    expect(controller.error.value, isNull);
    expect(controller.isLoading.value, isFalse);
    expect(controller.partners.map((p) => p.name).toList(), ['First', 'Second']);
  });

  test('PartnerController captures repository error', () async {
    final repo = _FakePartnerRepository((_, __) async {
      throw PartnerApiException('Failed to load partners (500)');
    });

    final controller = PartnerController(repo);
    await controller.load();

    expect(controller.isLoading.value, isFalse);
    expect(controller.error.value, 'Failed to load partners (500)');
    expect(controller.partners, isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/partner_test.dart`
Expected: FAIL with compilation error (`partner_controller.dart` and `partner_repository.dart` not found)

- [ ] **Step 3: Implement `Env.partnersPath`, `ApiPartnerRepository`, and `PartnerController`**

Add `NEWS_API_PARTNERS_PATH=/partners` to `.env` and `static String get partnersPath => _get('NEWS_API_PARTNERS_PATH', '/partners');` to `lib/core/env.dart`.
Create `lib/data/repositories/partner_repository.dart` with `PartnerApiException`, `PartnerRepository`, and `ApiPartnerRepository` calling `api.get(Env.partnersPath, query: {'page': '$page', 'limit': '$limit'})` and parsing `Partner.fromJson`.
Create `lib/controllers/partner_controller.dart` filtering `item.isActive != false` and sorting by `(a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/partner_test.dart`
Expected: PASS

---

### Task 2: PartnerCircle Widget, AppBinding & HomePage Integration

**Files:**
- Create: `lib/widgets/partner_circle.dart`
- Modify: `lib/core/app_binding.dart`
- Modify: `lib/features/home/home_page.dart`
- Modify: `test/partner_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `PartnerController`, `ApiPartnerRepository`, `Items` (`lib/data/models/partner.dart`)
- Produces:
  - `class PartnerCircle extends StatelessWidget` (`const PartnerCircle({super.key, required this.partner, this.size = 48})`)
  - `PartnerCircle.isValidPartnerUrl(String? rawUrl) -> bool` (validates `http`/`https` URI with non-empty host)
  - `HomePage` displays `"Partners"` section with `PartnerCircle` items under `"The latest news"`

- [ ] **Step 1: Write the failing widget and integration tests in `test/partner_test.dart`**

```dart
  test('PartnerCircle.isValidPartnerUrl only allows http and https URLs', () {
    expect(PartnerCircle.isValidPartnerUrl('https://bookeyond.com/'), isTrue);
    expect(PartnerCircle.isValidPartnerUrl('http://mephtah.com'), isTrue);
    expect(PartnerCircle.isValidPartnerUrl('javascript:alert(1)'), isFalse);
    expect(PartnerCircle.isValidPartnerUrl(''), isFalse);
    expect(PartnerCircle.isValidPartnerUrl(null), isFalse);
  });

  testWidgets('HomePage renders Partners section with PartnerCircle items under latest news', (tester) async {
    // Register fake controllers and pump HomePage
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/partner_test.dart`
Expected: FAIL (`partner_circle.dart` not defined)

- [ ] **Step 3: Implement `PartnerCircle`, register in `AppBinding`, and add Partners section to `HomePage`**

Create `lib/widgets/partner_circle.dart` rendering a circular `Material` + `InkWell` (`BoxShape.circle`, `48x48` default size, `AppColors.line` border, `Tooltip` with `partner.name`, `Image.network` with `WebHtmlElementStrategy.fallback` and fallback when `logoUrl` is empty/errors, launching `partner.url` in `_blank` when `PartnerCircle.isValidPartnerUrl` is true).
Register `ApiPartnerRepository` and `PartnerController` in `lib/core/app_binding.dart`.
Update `lib/features/home/home_page.dart` to find `PartnerController`, trigger `partnerController.load()` if empty and not loading in `initState`, and render the `Partners` heading and horizontal list of `PartnerCircle` widgets directly beneath the latest news carousel.

- [ ] **Step 4: Run all tests and analyzer to verify they pass**

Run: `flutter test && flutter analyze`
Expected: PASS with 0 errors
