import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/more_controller.dart';
import '../../core/breakpoints.dart';
import '../../widgets/news_card.dart';
import '../../widgets/status_views.dart';

/// Paginated list of the latest news. Scrolling to the end loads the next page.
class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    final more = Get.find<MoreController>();
    more.syncWithHomeController();
    if (more.articles.isEmpty && !more.isLoading.value) {
      more.load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 200) {
      Get.find<MoreController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetX<MoreController>(
      builder: (controller) {
        final pad = Breakpoints.pagePadding(context);
        final titleStyle = Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w400);
        final Widget sliver;
        if (controller.isLoading.value && controller.articles.isEmpty) {
          sliver = const SliverToBoxAdapter(child: EmptyView());
        } else if (controller.error.value != null &&
            controller.articles.isEmpty) {
          sliver = SliverToBoxAdapter(
            child: ErrorView(
              message: controller.error.value!,
              onRetry: () => controller.load(force: true),
            ),
          );
        } else if (controller.articles.isEmpty) {
          sliver = SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.article_outlined, size: 48),
                  const SizedBox(height: 8),
                  const Text('No articles available',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => controller.load(force: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else {
          sliver = SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: Breakpoints.gridExtent(context),
              mainAxisExtent: 200,
              crossAxisSpacing: 22,
              mainAxisSpacing: 22,
            ),
            itemCount: controller.articles.length,
            itemBuilder: (context, i) =>
                NewsCard(article: controller.articles[i]),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('More news', style: titleStyle),
                        if (controller.error.value != null &&
                            controller.articles.isNotEmpty)
                          TextButton.icon(
                            onPressed: controller.loadMore,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                  sliver: sliver,
                ),
                if (controller.isLoadingMore.value &&
                    controller.articles.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
