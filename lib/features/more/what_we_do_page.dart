import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/what_we_do_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/html_content_view.dart';


/// What we do page. Fetches dynamic content from `GET /settings/what-we-do`
/// via [WhatWeDoController] and falls back to static content when unavailable.
class WhatWeDoPage extends GetView<WhatWeDoController> {
  const WhatWeDoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pad = Breakpoints.pagePadding(context);

    return Obx(() => Center(
          child: controller.isLoading.isTrue
              ? Transform.scale(
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : ConstrainedBox(
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
