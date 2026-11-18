import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/about_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown while initial sync is in flight or when unavailable.
const _kAboutFallbackHtml = '''
<h2>About Release Today</h2>
<p>Intelligent news aggregation, summarization, and search powered by AI.</p>
<p>We help you discover, search, and stay on top of the stories that matter,
with smart topic tracking and personalized recommendations.</p>
''';

/// About us page. Reads cached/synced content from [AboutController] and falls
/// back to static content when unavailable so navigation is always instant.
class AboutPage extends GetView<AboutController> {
  const AboutPage({super.key});

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
                      : _kAboutFallbackHtml;
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
