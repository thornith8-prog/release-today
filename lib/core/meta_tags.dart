/// Placeholder for the per-article Open Graph / Twitter Card tags.
///
/// The backend share page (`GET /s/{id}`, see docs/backend/share_route.py)
/// owns the social preview metadata, so the Flutter app does not mutate
/// document meta tags. Kept as a no-op hook so the article detail page can
/// call it uniformly on every platform.
void setArticleMetaTags({
  required String title,
  String? description,
  String? imageUrl,
}) {}
