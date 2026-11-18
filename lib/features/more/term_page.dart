import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/term_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown while initial sync is in flight or when unavailable.
const _kTermsFallbackHtml = '''
<h2>Terms &amp; Conditions</h2>
<p>By using Release Today, you agree to the following terms and conditions.</p>
<ul>
  <li>Content is provided for informational purposes only.</li>
  <li>We are not responsible for third-party publisher content.</li>
  <li>You may not use the service for unlawful purposes.</li>
</ul>
''';

/// Terms page. Reads cached/synced content from [TermController] and falls
/// back to static content when unavailable so navigation is instant.
class TermPage extends GetView<TermController> {
  const TermPage({super.key});

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
                      : _kTermsFallbackHtml;
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
