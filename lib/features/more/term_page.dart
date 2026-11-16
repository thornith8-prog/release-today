import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/term_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown when the backend has no `terms` setting.
const _kTermsFallbackHtml = '''
<h1>Terms &amp; Conditions</h1>
<p>By using Release Today, you agree to the following terms and conditions.</p>
<ul>
  <li>Content is provided for informational purposes only.</li>
  <li>We are not responsible for third-party publisher content.</li>
  <li>You may not use the service for unlawful purposes.</li>
</ul>
''';

/// Terms page. Fetches dynamic content from `GET /settings/terms` via
/// [TermController] and falls back to static content when unavailable.
class TermPage extends GetView<TermController> {
  const TermPage({super.key});

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
                          _kTermsFallbackHtml,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

