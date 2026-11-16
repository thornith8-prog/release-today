import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';

/// Renders basic semantic HTML elements (`h1-h4`, `p`, `ul`, `ol`, `li`, `hr`, `a`, `b`, `i`)
/// matching the app's responsive typography and colors without third-party dependencies.
class HtmlContentView extends StatelessWidget {
  final String html;

  const HtmlContentView({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    final trimmed = html.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    final blocks = _parseBlocks(trimmed);
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0 && blocks[i].topSpacing > 0)
            SizedBox(height: blocks[i].topSpacing),
          blocks[i].build(context),
        ],
      ],
    );
  }

  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  static List<_HtmlBlock> _parseBlocks(String input) {
    final blocks = <_HtmlBlock>[];
    // Regex matching common block tags
    final blockRegex = RegExp(
      r'<(h[1-4]|p|ul|ol|hr|div)([^>]*)>(.*?)(?:<\/\1>|(?=<(?:h[1-4]|p|ul|ol|hr|div)[^>]*>|$))',
      caseSensitive: false,
      dotAll: true,
    );

    int lastEnd = 0;
    for (final match in blockRegex.allMatches(input)) {
      if (match.start > lastEnd) {
        final dangling = input.substring(lastEnd, match.start).trim();
        if (dangling.isNotEmpty) {
          blocks.add(_ParagraphBlock(dangling));
        }
      }

      final tag = match.group(1)!.toLowerCase();
      final inner = match.group(3) ?? '';

      if (tag.startsWith('h')) {
        final level = int.tryParse(tag.substring(1)) ?? 2;
        blocks.add(_HeadingBlock(inner.trim(), level));
      } else if (tag == 'hr') {
        blocks.add(const _DividerBlock());
      } else if (tag == 'ul' || tag == 'ol') {
        blocks.add(_ListBlock(inner.trim(), isOrdered: tag == 'ol'));
      } else {
        final text = inner.trim();
        if (text.isNotEmpty) {
          blocks.add(_ParagraphBlock(text));
        }
      }

      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      final trailing = input.substring(lastEnd).trim();
      if (trailing.isNotEmpty) {
        blocks.add(_ParagraphBlock(trailing));
      }
    }

    return blocks;
  }
}

abstract class _HtmlBlock {
  const _HtmlBlock();
  double get topSpacing;
  Widget build(BuildContext context);
}

class _HeadingBlock extends _HtmlBlock {
  final String content;
  final int level;

  const _HeadingBlock(this.content, this.level);

  @override
  double get topSpacing => level <= 2 ? 24 : 16;

  @override
  Widget build(BuildContext context) {
    final base = level == 1
        ? Theme.of(context).textTheme.headlineSmall
        : level == 2
            ? Theme.of(context).textTheme.titleLarge
            : Theme.of(context).textTheme.titleMedium;

    final style = (base ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.ink,
    );

    return Text(
      HtmlContentView._decodeHtmlEntities(_stripTags(content)),
      style: style,
    );
  }

  static String _stripTags(String s) => s.replaceAll(RegExp(r'<[^>]+>'), '');
}

class _ParagraphBlock extends _HtmlBlock {
  final String htmlContent;

  const _ParagraphBlock(this.htmlContent);

  @override
  double get topSpacing => 12;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.7,
          color: AppColors.ink.withValues(alpha: 0.9),
        ) ??
        const TextStyle(height: 1.7, color: AppColors.ink);

    final spans = _parseInlineSpans(context, htmlContent, bodyStyle);

    return Text.rich(
      TextSpan(children: spans),
      style: bodyStyle,
    );
  }
}

class _ListBlock extends _HtmlBlock {
  final String rawHtml;
  final bool isOrdered;

  const _ListBlock(this.rawHtml, {required this.isOrdered});

  @override
  double get topSpacing => 12;

  @override
  Widget build(BuildContext context) {
    final itemRegex = RegExp(r'<li[^>]*>(.*?)<\/li>', caseSensitive: false, dotAll: true);
    final matches = itemRegex.allMatches(rawHtml).toList();

    final bodyStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: AppColors.ink.withValues(alpha: 0.9),
        ) ??
        const TextStyle(height: 1.6, color: AppColors.ink);

    if (matches.isEmpty) {
      // If no <li> found, fall back to paragraph
      final clean = HtmlContentView._decodeHtmlEntities(rawHtml.replaceAll(RegExp(r'<[^>]+>'), '')).trim();
      if (clean.isEmpty) return const SizedBox.shrink();
      return Text(clean, style: bodyStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < matches.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isOrdered ? 24 : 16,
                child: Text(
                  isOrdered ? '${i + 1}.' : '•',
                  style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(children: _parseInlineSpans(context, matches[i].group(1) ?? '', bodyStyle)),
                  style: bodyStyle,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DividerBlock extends _HtmlBlock {
  const _DividerBlock();

  @override
  double get topSpacing => 20;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1),
    );
  }
}

List<InlineSpan> _parseInlineSpans(
  BuildContext context,
  String raw,
  TextStyle baseStyle,
) {
  final spans = <InlineSpan>[];
  final tagRegex = RegExp(
    r'<(strong|b|em|i|a|br)([^>]*)>(.*?)(?:<\/\1>)?|<br\s*\/?>',
    caseSensitive: false,
    dotAll: true,
  );

  int lastIndex = 0;
  for (final match in tagRegex.allMatches(raw)) {
    if (match.start > lastIndex) {
      final text = raw.substring(lastIndex, match.start);
      if (text.isNotEmpty) {
        spans.add(TextSpan(
          text: HtmlContentView._decodeHtmlEntities(text),
          style: baseStyle,
        ));
      }
    }

    final matchStr = match.group(0)!;
    if (matchStr.toLowerCase().startsWith('<br')) {
      spans.add(const TextSpan(text: '\n'));
      lastIndex = match.end;
      continue;
    }

    final tag = match.group(1)?.toLowerCase() ?? '';
    final attrs = match.group(2) ?? '';
    final inner = match.group(3) ?? '';

    TextStyle spanStyle = baseStyle;
    if (tag == 'strong' || tag == 'b') {
      spanStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
    } else if (tag == 'em' || tag == 'i') {
      spanStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
    } else if (tag == 'a') {
      final hrefMatch = RegExp(r'''href=["']([^"']+)["']''', caseSensitive: false).firstMatch(attrs);
      final href = hrefMatch?.group(1);
      spanStyle = baseStyle.copyWith(
        color: Theme.of(context).primaryColor,
        decoration: TextDecoration.underline,
      );

      TapGestureRecognizer? recognizer;
      if (href != null && href.isNotEmpty) {
        recognizer = TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(href);
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          };
      }

      final innerText = inner.replaceAll(RegExp(r'<[^>]+>'), '');
      spans.add(TextSpan(
        text: HtmlContentView._decodeHtmlEntities(innerText),
        style: spanStyle,
        recognizer: recognizer,
      ));
      lastIndex = match.end;
      continue;
    }

    // Recursively parse inner spans if any nested formatting exists
    final cleanInner = inner.replaceAll(RegExp(r'<[^>]+>'), '');
    spans.add(TextSpan(
      text: HtmlContentView._decodeHtmlEntities(cleanInner),
      style: spanStyle,
    ));

    lastIndex = match.end;
  }

  if (lastIndex < raw.length) {
    final trailing = raw.substring(lastIndex);
    if (trailing.isNotEmpty) {
      spans.add(TextSpan(
        text: HtmlContentView._decodeHtmlEntities(trailing),
        style: baseStyle,
      ));
    }
  }

  return spans;
}
