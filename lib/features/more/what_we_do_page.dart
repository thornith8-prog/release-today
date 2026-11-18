import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/what_we_do_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown while initial sync is in flight or when unavailable.
const _kWhatWeDoFallbackHtml = '''
<h2>What We Do</h2>
<p>We aggregate news across trusted outlets, analyze trending stories, and provide real-time updates.</p>
<ul>
  <li>Aggregate news from trusted sources.</li>
  <li>Let you follow topics and track ongoing coverage.</li>
  <li>Provide AI-assisted search across your recent queries.</li>
</ul>
''';

/// What we do page. Reads cached/synced content from [WhatWeDoController] and
/// falls back to static content when unavailable so navigation is instant.
class WhatWeDoPage extends GetView<WhatWeDoController> {
  const WhatWeDoPage({super.key});

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
                      : _kWhatWeDoFallbackHtml;
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
