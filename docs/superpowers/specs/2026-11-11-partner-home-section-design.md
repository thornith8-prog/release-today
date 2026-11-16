# Partner Home Section Design

## Intent & Why
Display active partner brands directly below **The latest news** section on the home screen (`HomePage`), fetched from `GET https://news-ai-d115c798.fastapicloud.dev/partners?page=1&limit=50` using the existing `Partner` model (`lib/data/models/partner.dart`). Each partner item renders as a small circular logo that opens the partner's website (`url`) in a new browser tab when tapped.

## Goals, Non-goals, and Anti-goals
- **Goals:**
  - Load partners from `/partners?page=1&limit=50` via `ApiClient` and parse using `Partner.fromJson`.
  - Filter items to active partners (`isActive != false`) and sort ascending by `displayOrder` (fallback `0`).
  - Render a `Partners` section below `The latest news` on `HomePage` with small circular partner items (`48x48` circle, border, CORS-fallback `Image.network`, fallback icon `/icons/ic_news.png`, and `Tooltip` with `name`).
  - Open `item.url` (validated `http`/`https` scheme) in a new browser tab on tap.
- **Non-goals:**
  - Separate "More partners" screen or infinite-scroll pagination beyond `page=1&limit=50`.
- **Anti-goals:**
  - Coupling partner loading state with `HomeController` such that a partner fetch error breaks or hides the latest news carousel.

## Constraints
- Reuse existing `Partner` and `Items` classes in `lib/data/models/partner.dart`.
- Reuse `ApiClient` (`lib/services/api_client.dart`) and `Env` (`lib/core/env.dart`) for base URL and CORS proxy support.
- Validate external URLs (`uri.scheme == 'http' || uri.scheme == 'https'`) before calling `launchUrl`.

## Approaches
1. **Dedicated `ApiPartnerRepository` + `PartnerController` (Selected):** Follows the existing repository/controller pattern (`ApiNewsRepository`, `ApiTopicRepository`, `TopicsController`) registered in `AppBinding`. Keeps partner loading/error state independent of `HomeController`.
2. **Inline in `HomeController`:** Fewer files, but mixes partner state into an `ArticlesController` subclass.

## Architecture & Decisions
- **Env (`lib/core/env.dart` & `.env`):** Add `Env.partnersPath` reading `NEWS_API_PARTNERS_PATH` with fallback `'/partners'`.
- **Repository (`lib/data/repositories/partner_repository.dart`):** `PartnerRepository` interface and `ApiPartnerRepository(ApiClient api)` with `Future<Partner> partners({int page = 1, int limit = 50})`.
- **Controller (`lib/controllers/partner_controller.dart`):** `PartnerController(PartnerRepository repository)` holding `partners = <Items>[].obs`, `isLoading = true.obs`, `error = RxnString()`, filtering `isActive != false` and sorting by `displayOrder`.
- **Widget (`lib/widgets/partner_circle.dart`):** `PartnerCircle({required Items partner})` rendering a `48x48` circular `Material`/`InkWell` with `Tooltip(message: partner.name ?? '')`, `Image.network` with `WebHtmlElementStrategy.fallback`, fallback asset `icons/ic_news.png`, and `onTap` launching validated `http`/`https` `partner.url`.
- **HomePage (`lib/features/home/home_page.dart`) & AppBinding (`lib/core/app_binding.dart`):** Register `ApiPartnerRepository` and `PartnerController` as permanent singletons in `AppBinding`, and render the `Partners` section below the latest news carousel in `HomePage`.
