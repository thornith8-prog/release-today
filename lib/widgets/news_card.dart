import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../data/models/article.dart';
import 'article_share_button.dart';
import 'status_views.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.article});

  final ArticleData article;

  Future<void> _open() async {
    final uri = Uri.tryParse(article.url ?? '');
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isNarrow = cardWidth < 240;
        final titleRight = isNarrow ? 44.0 : 56.0;
        final titleFontSize = isNarrow ? 14.0 : 16.0;
        final logoSize = isNarrow ? 32.0 : 36.0;

        return Material(
          color: AppColors.ink,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            onTap: _open,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if ((article.imageUrl ?? '').isNotEmpty)
                  Image.network(
                    article.imageUrl!,
                    fit: BoxFit.cover,
                    // Falls back to a plain  when the image host lacks CORS headers.
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const ShimmerLoading();
                    },
                    errorBuilder: (context, error, stack) =>
                        const SizedBox.shrink(),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0xD90A0E28), Color(0x000A0E28)],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: titleRight,
                  bottom: 10,
                  child: Container(
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.2),
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      article.title ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          height: 1.25),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: logoSize,
                    height: logoSize,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.badge, shape: BoxShape.circle),
                    child: (article.logoUrl != null && article.logoUrl!.isNotEmpty)
                        ? Image.network(
                            article.logoUrl!,
                            fit: BoxFit.cover,
                            // Falls back to a plain  when the image host lacks CORS headers.
                            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const ShimmerLoading(shape: BoxShape.circle);
                            },
                            errorBuilder: (context, error, stack) => Image.asset(
                              'assets/icons/ic_news.png',
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          )
                        : Image.asset(
                            'assets/icons/ic_news.png',
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                  ),
                ),
                Positioned(
                    top: 5,
                    right: 8,
                    child: Text(
                      _getCurrentDate(article.publishedAtText),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          height: 1.25),
                    )),
                // Separate tap target, so sharing doesn't also open the article.
                Positioned(
                  top: 4,
                  left: 4,
                  child: ArticleShareButton(article: article),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getCurrentDate(String date) {
    if (date.isEmpty) return '';
    try {
      DateTime sqlParsedDate = DateTime.parse(date);
      return DateFormat('dd/MMM/yyyy').format(sqlParsedDate);
    } catch (_) {
      return '';
    }
  }
}
