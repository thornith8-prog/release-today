import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/about_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';

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
                      html: controller.setting.value?.contentHtml ?? '',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
