import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/about_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown when the backend has no `about-us` setting.
const _kFallbackHtml = '''
<h1>About us</h1>
<p>Welcome to NewsAI — your AI-powered news companion.</p>
<p>We help you discover, search, and stay on top of the stories that matter,
with smart topic tracking and personalized recommendations.</p>
<h2>What we do</h2>
<ul>
  <li>Aggregate news from trusted sources.</li>
  <li>Let you follow topics and get notified of new entries.</li>
  <li>Provide AI-assisted search across your recent queries.</li>
</ul>
<h2>Contact</h2>
<p>Questions or feedback? Reach us at support@example.com.</p>
''';

/// About us page. Fetches dynamic content from `GET /settings/about-us` via
/// [AboutController] and falls back to static content when unavailable.
///
/// Uses `GetX` so the view only rebuilds when the controller's observable
/// state changes (once after load), keeping navigation between pages instant.
class AboutPage extends GetView<AboutController> {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = Breakpoints.pagePadding(context);

    return Obx(() => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                  sliver: SliverToBoxAdapter(
                    child: HtmlContentView(
                      html: controller.setting.value?.contentHtml ??
                          _kFallbackHtml,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
