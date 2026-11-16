import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/env.dart';
import '../../core/meta_tags.dart';
import '../../core/theme.dart';
import '../../data/models/article.dart';
import '../../widgets/article_share_button.dart';

/// Deep-link destination for a shared article: shows photo, title, date,
/// summary and a link to the original publisher.
///
/// When opened from a cold-start deep link that carries only an id (no API
/// endpoint exists to fetch an article by id), [article] is null and the page
/// opens the backend share page `{Env.shareBaseUrl}/s/[articleId]` in a
/// browser instead.
class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({super.key, this.article, this.articleId});

  final ArticleData? article;
  final String? articleId;

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  bool _fallbackOpened = false;

  @override
  void initState() {
    super.initState();
    if (widget.article != null) {
      setArticleMetaTags(
        title: widget.article!.title ?? 'NewsAI',
        description: widget.article!.summary?.trim().isNotEmpty == true
            ? widget.article!.summary
            : widget.article!.title,
        imageUrl: widget.article!.imageUrl,
      );
    } else if (widget.articleId != null) {
      _openSharePageFallback();
    }
  }

  Future<void> _openSharePageFallback() async {
    if (_fallbackOpened || widget.articleId == null) return;
    _fallbackOpened = true;
    final link = '${Env.shareBaseUrl}/s/${widget.articleId}';
    final ok = await launchUrl(Uri.parse(link), webOnlyWindowName: '_blank');
    if (!ok && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    return Scaffold(
      appBar: AppBar(
        title: article == null
            ? const Text('Article')
            : Text(article.title ?? 'Article', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: article == null ? _FallbackView(articleId: widget.articleId ?? '') : _ArticleView(article: article),
    );
  }
}

class _ArticleView extends StatelessWidget {
  const _ArticleView({required this.article});

  final ArticleData article;

  String get dateText {
    if (article.publishedAtText.isEmpty) return '';
    try {
      return DateFormat('dd/MMM/yyyy').format(DateTime.parse(article.publishedAtText).toLocal());
    } catch (_) {
      return article.publishedAtText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((article.imageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                article.imageUrl!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  height: 260,
                  color: AppColors.field,
                  alignment: Alignment.center,
                  child: Image.asset('assets/icons/ic_news.png'),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            article.title ?? '',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 8),
          if (dateText.isNotEmpty || article.source != null && article.source!.isNotEmpty) ...[
            Row(
              children: [
                if (dateText.isNotEmpty)
                  Text(
                    dateText,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.ink.withValues(alpha: 0.5)),
                  ),
                if (article.source != null && article.source!.isNotEmpty) ...[
                  if (dateText.isNotEmpty) const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.badge.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      article.source!,
                      style: const TextStyle(
                        color: AppColors.badge,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (article.summary != null && article.summary!.isNotEmpty) ...[
            Text(
              article.summary!,
              style: textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.ink.withValues(alpha: 0.9)),
            ),
            const SizedBox(height: 20),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: ArticleShareButton(article: article),
          ),
          const SizedBox(height: 16),
          if (article.url != null && article.url!.isNotEmpty)
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(article.url!);
                if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
                  await launchUrl(uri, webOnlyWindowName: '_blank');
                }
              },
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Read original article'),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _FallbackView extends StatelessWidget {
  const _FallbackView({required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined, size: 48, color: AppColors.line),
          const SizedBox(height: 16),
          Text(
            'Article #$articleId',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Opening the shared article on the web…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final link = '${Env.shareBaseUrl}/s/$articleId';
              await launchUrl(Uri.parse(link), webOnlyWindowName: '_blank');
            },
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Open article on the web'),
          ),
        ],
      ),
    );
  }
}
