import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/what_we_do_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown when the backend has no `what-we-do` setting.
const _kWhatWeDoFallbackHtml = '''
<h1>What we do</h1>
<p>We help you discover, search, and stay on top of the stories that matter
with smart topic tracking and AI-powered recommendations.</p>
<ul>
  <li>Aggregate news from trusted sources.</li>
  <li>Let you follow topics and get notified of new entries.</li>
  <li>Provide AI-assisted search across your recent queries.</li>
</ul>
''';

/// What we do page. Fetches dynamic content from `GET /settings/what-we-do`
/// via [WhatWeDoController] and falls back to static content when unavailable.
class WhatWeDoPage extends GetView<WhatWeDoController> {
  const WhatWeDoPage({super.key});

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
                          _kWhatWeDoFallbackHtml,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
