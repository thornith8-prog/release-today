import '../data/models/article.dart';
import 'env.dart';

/// Social networks the share menu can post to.
enum ShareTarget { telegram, facebook, linkedin, x }

/// Builds the single public share link for an article and the
/// per-network "share this URL" intents that wrap it.
///
/// The share link (`{base}/s/{id}`) is served by the backend as a tiny HTML
/// page with Open Graph tags, so every network renders a proper preview and
/// visitors are forwarded to the publisher.
class ArticleShare {
  ArticleShare._();

  /// Returns `{base}/s/{id}`, or `null` when the article has no id.
  /// [baseUrl] defaults to [Env.shareBaseUrl]; override only in tests.
  static String? shareUrl(ArticleData article, {String? baseUrl}) {
    final id = article.id;
    if (id == null) return null;
    var base = (baseUrl ?? Env.shareBaseUrl).trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1).trim();
    }
    return '$base/s/$id';
  }

  /// Returns the network's share-intent URL for [article], or `null` when
  /// the article has no id. All values are encoded by [Uri].
  static Uri? targetUri(
    ShareTarget target,
    ArticleData article, {
    String? baseUrl,
  }) {
    final link = shareUrl(article, baseUrl: baseUrl);
    if (link == null) return null;
    final text = (article.title ?? '').trim();

    switch (target) {
      case ShareTarget.telegram:
        return Uri.https('t.me', '/share/url', {
          'url': link,
          if (text.isNotEmpty) 'text': text,
        });
      case ShareTarget.facebook:
        return Uri.https('www.facebook.com', '/sharer/sharer.php', {'u': link});
      case ShareTarget.linkedin:
        return Uri.https(
            'www.linkedin.com', '/sharing/share-offsite/', {'url': link});
      case ShareTarget.x:
        return Uri.https('twitter.com', '/intent/tweet', {
          'url': link,
          if (text.isNotEmpty) 'text': text,
        });
    }
  }
}
