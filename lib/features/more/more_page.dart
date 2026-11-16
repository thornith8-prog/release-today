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
    _scrollController = ScrollController()
      ..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Get.find<MoreController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = Breakpoints.pagePadding(context);
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w400);

    return GetX<MoreController>(
      builder: (c) {
        final Widget sliver;
        if (c.isLoading.value && c.articles.isEmpty) {
          sliver = const SliverToBoxAdapter(child: EmptyView());
        } else if (c.error.value != null && c.articles.isEmpty) {
          sliver = SliverToBoxAdapter(child: ErrorView(message: c.error.value!, onRetry: c.load));
        } else if (c.articles.isEmpty) {
          sliver = const SliverToBoxAdapter(child: EmptyView());
        } else {
          sliver = SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: Breakpoints.gridExtent(context),
              mainAxisExtent: 200,
              crossAxisSpacing: 22,
              mainAxisSpacing: 22,
            ),
            itemCount: c.articles.length,
            itemBuilder: (context, i) => NewsCard(article: c.articles[i]),
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
                        if (c.error.value != null && c.articles.isNotEmpty)
                          TextButton.icon(
                            onPressed: c.loadMore,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(padding: EdgeInsets.fromLTRB(pad, 16, pad, 24), sliver: sliver),
                if (c.isLoadingMore.value && c.articles.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
