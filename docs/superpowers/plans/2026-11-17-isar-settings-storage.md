# Isar Settings Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store settings fetched from `https://news-ai-d115c798.fastapicloud.dev/settings` into Isar database (`isar: ^3.1.0+1`), update records only when `updated_at` is newer, and load About Us, Privacy, What We Do, and Terms from Isar.

**Architecture:**
- Create an Isar collection `Setting` representing the settings records with unique slug index and timestamps.
- Implement `IsarService` to initialize Isar database safely across platforms (native and web-safe fallback).
- Update `SettingsRepository` to fetch `/settings`, inspect `updated_at`, and upsert records into Isar if `local.updatedAt == null` or `remote.updatedAt.isAfter(local.updatedAt)`.
- Update `AboutController`, `PrivacyController`, `WhatWeDoController`, and `TermController` to load directly from Isar.

**Tech Stack:**
- Flutter 3.5+
- `isar: ^3.1.0+1`, `isar_flutter_libs: ^3.1.0+1`
- `isar_generator: ^3.1.0+1`, `build_runner: ^2.4.9`
- `get: ^4.6.6`

**Spec:** User request:
- Use `isar: ^3.1.0+1` for storing settings loaded from `https://news-ai-d115c798.fastapicloud.dev/settings`.
- Update if field `updated_at` is latest update.
- Load About Us, Privacy, What We Do, and Terms from Isar.

## Global Constraints

- Isar version must be `^3.1.0+1`.
- URL endpoint is `/settings`.
- Update condition must check `updated_at` against the existing stored record.
- About Us (`about-us`), Privacy (`privacy`), What We Do (`what-we-do`), and Terms (`terms`) must load from Isar.

## Review Focus

1. **New remote update vs existing**: Remote has newer `updated_at` -> Local record is updated.
2. **Old/equal remote update vs existing**: Remote has older or equal `updated_at` -> Local record is preserved.
3. **Missing local record**: Remote record exists -> Stored in Isar.
4. **Isar read by slug**: `getSetting(slug)` reads from Isar and matches expected content.
5. **Controllers integration**: All 4 controllers (`AboutController`, `PrivacyController`, `WhatWeDoController`, `TermController`) fetch their content from Isar.

---

### Task 1: Add dependencies & annotate Setting collection

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/data/models/setting.dart`
- Create/Generate: `lib/data/models/setting.g.dart`

**Steps:**
- [ ] Add `isar: ^3.1.0+1` and `isar_flutter_libs: ^3.1.0+1` to `dependencies`, `isar_generator: ^3.1.0+1` and `build_runner: ^2.4.9` to `dev_dependencies`.
- [ ] Annotate `Setting` in `lib/data/models/setting.dart` with `@collection` and `Id id = Isar.autoIncrement` (or backend id) and `@Index(unique: true, replace: true) String slug`.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` to generate `setting.g.dart`.
- [ ] Write a test in `test/setting_model_test.dart` verifying serialization and deserialization.

---

### Task 2: Create IsarService and SettingsLocalDataSource

**Files:**
- Create: `lib/services/isar_service.dart`
- Create: `test/isar_service_test.dart`

**Steps:**
- [ ] Write failing test in `test/isar_service_test.dart` verifying Isar database opening, storing a `Setting`, querying by slug, and closing.
- [ ] Implement `IsarService` in `lib/services/isar_service.dart`:
  - Open Isar with `SettingSchema`.
  - Provide `getSettingBySlug(String slug)` returning `Future<Setting?>`.
  - Provide `getAllSettings()` returning `Future<List<Setting>>`.
  - Provide `putSetting(Setting setting)` returning `Future<void>`.
  - Provide `putAllSettings(List<Setting> settings)` returning `Future<void>`.
- [ ] Run tests and ensure they pass.

---

### Task 3: Implement Sync Logic in SettingsRepository

**Files:**
- Modify: `lib/data/repositories/settings_repository.dart`
- Create: `test/settings_repository_test.dart`

**Steps:**
- [ ] Write failing tests in `test/settings_repository_test.dart`:
  - Syncing fetches `/settings` from API.
  - If local setting does not exist, insert remote setting into Isar.
  - If remote `updated_at` is newer than local `updated_at`, update Isar.
  - If remote `updated_at` is older or equal, do NOT overwrite Isar.
  - `getSetting(slug)` reads from Isar.
- [ ] Implement `syncSettings()` and updated `getSetting(slug)` in `SettingsRepository`.
- [ ] Run tests to verify all sync and update conditions pass.

---

### Task 4: Connect Controllers and App Initialization

**Files:**
- Modify: `lib/core/app_binding.dart`
- Modify: `lib/main.dart`
- Modify: `lib/controllers/about_controller.dart`
- Modify: `lib/controllers/privacy_controller.dart`
- Modify: `lib/controllers/what_we_do_controller.dart`
- Modify: `lib/controllers/term_controller.dart`
- Create/Modify: `test/settings_controllers_test.dart`

**Steps:**
- [ ] Initialize `IsarService` in `main.dart` / `AppBinding`.
- [ ] Update `AboutController`, `PrivacyController`, `WhatWeDoController`, and `TermController` to read from the Isar-backed repository.
- [ ] Add tests in `test/settings_controllers_test.dart` verifying all 4 controllers load their respective settings (`about-us`, `privacy`, `what-we-do`, `terms`) from Isar.
- [ ] Run all project tests (`flutter test`) to verify zero regressions.
