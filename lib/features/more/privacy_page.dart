import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/privacy_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown while initial sync is in flight or when unavailable.
const _kPrivacyFallbackHtml = '''
<h2>Privacy Policy</h2>
<p>We respect your privacy. This page describes how we handle your data.</p>
<ul>
  <li>We do not sell your personal information.</li>
  <li>Search queries are stored only to improve your experience.</li>
  <li>You can delete your topics and recent searches at any time.</li>
</ul>
''';

/// Privacy page. Reads cached/synced content from [PrivacyController] and falls
/// back to static content when unavailable so navigation is instant.
class PrivacyPage extends GetView<PrivacyController> {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = Breakpoints.pagePadding(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
              sliver: SliverToBoxAdapter(
                child: Obx(() {
                  final raw = controller.setting.value?.contentHtml;
                  final html = (raw != null && raw.trim().isNotEmpty)
                      ? raw
                      : _kPrivacyFallbackHtml;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    ),
                    child: KeyedSubtree(
                      key: ValueKey<String>(html),
                      child: HtmlContentView(html: html),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
