import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/privacy_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

/// Static content shown when the backend has no `privacy` setting.
const _kPrivacyFallbackHtml = '''
<h1>Privacy &amp; Policy</h1>
<p>We respect your privacy. This page describes how we handle your data.</p>
<ul>
  <li>We do not sell your personal information.</li>
  <li>Search queries are stored only to improve your experience.</li>
  <li>You can delete your topics and recent searches at any time.</li>
</ul>
''';

/// Privacy page. Fetches dynamic content from `GET /settings/privacy` via
/// [PrivacyController] and falls back to static content when unavailable.
class PrivacyPage extends GetView<PrivacyController> {
  const PrivacyPage({super.key});

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
                          _kPrivacyFallbackHtml,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

