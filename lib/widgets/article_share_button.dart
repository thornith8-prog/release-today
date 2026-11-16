import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/article_share.dart';
import '../core/theme.dart';
import '../data/models/article.dart';

enum _ShareAction { copy, telegram, facebook, linkedin, x }

/// Small circular share icon that opens a menu: Copy link, Telegram,
/// Facebook, LinkedIn, X. All options share the same NewsAI link
/// (see [ArticleShare]). Renders nothing when the article has no id.
class ArticleShareButton extends StatelessWidget {
  const ArticleShareButton({super.key, required this.article});

  final ArticleData article;

  static const _targets = {
    _ShareAction.telegram: ShareTarget.telegram,
    _ShareAction.facebook: ShareTarget.facebook,
    _ShareAction.linkedin: ShareTarget.linkedin,
    _ShareAction.x: ShareTarget.x,
  };

  Future<void> _onSelected(BuildContext context, _ShareAction action) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (action == _ShareAction.copy) {
      final link = ArticleShare.shareUrl(article);
      if (link == null) return;
      try {
        await Clipboard.setData(ClipboardData(text: link));
        messenger?.showSnackBar(const SnackBar(content: Text('Link copied')));
      } catch (_) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Failed to copy link to clipboard')),
        );
      }
      return;
    }
    final uri = ArticleShare.targetUri(_targets[action]!, article);
    if (uri == null) return;
    final ok = await launchUrl(uri, webOnlyWindowName: '_blank');
    if (!ok) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Could not open the share page.')),
      );
    }
  }

  PopupMenuItem<_ShareAction> _item(
    _ShareAction value,
    String label,
    Widget icon,
  ) {
    return PopupMenuItem<_ShareAction>(
      value: value,
      child: Row(
        children: [
          SizedBox(width: 22, child: Center(child: icon)),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ArticleShare.shareUrl(article) == null) return const SizedBox.shrink();

    return PopupMenuButton<_ShareAction>(
      tooltip: 'Share',
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      onSelected: (a) => _onSelected(context, a),
      itemBuilder: (_) => [
        _item(_ShareAction.copy, 'Copy link',
            const Icon(Icons.link, size: 20, color: AppColors.ink)),
        const PopupMenuDivider(),
        _item(_ShareAction.telegram, 'Telegram',
            const Icon(Icons.telegram, size: 20, color: Color(0xFF229ED9))),
        _item(_ShareAction.facebook, 'Facebook',
            const Icon(Icons.facebook, size: 20, color: Color(0xFF1877F2))),
        _item(_ShareAction.linkedin, 'LinkedIn',
            const _Glyph('in', Color(0xFF0A66C2))),
        _item(_ShareAction.x, 'X', const _Glyph('𝕏', Colors.black)),
      ],
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.share, size: 18, color: AppColors.ink),
      ),
    );
  }
}

/// Text badge for brands that Material Icons doesn't include.
class _Glyph extends StatelessWidget {
  const _Glyph(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          height: 1,
        ),
      ),
    );
  }
}
