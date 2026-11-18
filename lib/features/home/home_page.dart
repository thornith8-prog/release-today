import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../core/breakpoints.dart';
import '../../core/navigation.dart';
import '../../widgets/news_card.dart';
import '../../widgets/partner_circle.dart';
import '../../widgets/status_views.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomeController>();

  }

  double _heroSize(ScreenSize size) => switch (size) {
        ScreenSize.mobile => 28,
        ScreenSize.tablet => 36,
        ScreenSize.desktop => 44,
      };

  @override
  Widget build(BuildContext context) {
    final size = Breakpoints.of(context);
    final pad = Breakpoints.pagePadding(context);
    final cardWidth = Breakpoints.cardWidth(context);
    final carouselHeight = Breakpoints.carouselHeight(context);
    final titleStyle = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w400);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text('The latest news', style: titleStyle),
                        ),
                        const SizedBox(width: 12),
                        const InkWell(
                          onTap: AppNav.goMore,
                          child: Text('More'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (controller.isLoading.value &&
                          controller.articles.isEmpty) {
                        return ShimmerCarousel(
                          height: carouselHeight,
                          cardWidth: cardWidth,
                        );
                      }
                      if (controller.isLoading.value) {
                        return const LoadingView();
                      }
                      final error = controller.error.value;
                      if (error != null) {
                        return ErrorView(
                            message: error, onRetry: controller.load);
                      }
                      final articles = controller.articles;
                      if (articles.isEmpty) {
                        return ShimmerCarousel(
                          height: carouselHeight,
                          cardWidth: cardWidth,
                        );
                      }
                      return SizedBox(
                        height: carouselHeight,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: articles.length,
                            separatorBuilder: (context, i) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, i) => SizedBox(
                                width: cardWidth,
                                child: NewsCard(article: articles[i])),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    const Divider(height: 1,),
                    const SizedBox(height: 16),
                    Text('Truth by partner', style: titleStyle),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.isLoadingPartner.value) {
                        return const ShimmerPartnerRow();
                      }
                      final error = controller.errorPartner.value;
                      if (error != null) {
                        return ErrorView(
                          message: error,
                          onRetry: controller.loadPartner,
                        );
                      }
                      final partners = controller.partners;
                      if (partners.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return SizedBox(
                        height: 70,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          scrollDirection: Axis.horizontal,
                          itemCount: partners.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, i) =>
                              PartnerCircle(partner: partners[i]),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 32),
                  child: Text(
                    'Find the latest news here?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: _heroSize(size), fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
