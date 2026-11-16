import 'package:flutter/material.dart';

import '../core/breakpoints.dart';
import '../core/theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.height = 140});
  final double height;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: height, child: const Center(child: CircularProgressIndicator()));
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 32),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Shimmer animation placeholder for images and skeleton blocks.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final BoxShape shape;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!inTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius:
                widget.shape == BoxShape.circle ? null : widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0xFFEBEBF2),
                Color(0xFFF7F7FA),
                Color(0xFFEBEBF2),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value.clamp(0.0, 1.0),
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder for the horizontal "Truth by partner" logo row.
class ShimmerPartnerRow extends StatelessWidget {
  const ShimmerPartnerRow({
    super.key,
    this.height = 70,
    this.itemCount = 10,
    this.spacing = 12,
  });

  final double height;
  final int itemCount;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, i) => SizedBox(width: spacing),
        itemBuilder: (context, i) => ShimmerLoading(
          width: height,
          height: height,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shimmer loading grid with skeleton cards matching the news card layout.
class EmptyView extends StatefulWidget {
  const EmptyView({
    super.key,
    this.itemCount = 12,
    this.padding,
  });

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  State<EmptyView> createState() => _EmptyViewState();
}

class _EmptyViewState extends State<EmptyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!inTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFEBEBF2),
            Color(0xFFF7F7FA),
            Color(0xFFEBEBF2),
          ],
          stops: [
            (_controller.value - 0.3).clamp(0.0, 1.0),
            _controller.value.clamp(0.0, 1.0),
            (_controller.value + 0.3).clamp(0.0, 1.0),
          ],
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: widget.padding ?? const EdgeInsets.symmetric(vertical: 16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: Breakpoints.gridExtent(context),
            mainAxisExtent: 200,
            crossAxisSpacing: 22,
            mainAxisSpacing: 22,
          ),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) => ShimmerNewsCard(
            shimmerGradient: shimmerGradient,
          ),
        );
      },
    );
  }
}

/// Shimmer carousel matching horizontal news sections (e.g. The latest news).
class ShimmerCarousel extends StatefulWidget {
  const ShimmerCarousel({
    super.key,
    this.height,
    this.cardWidth,
    this.itemCount = 6,
    this.spacing = 14,
    this.padding = const EdgeInsets.only(bottom: 20),
  });

  final double? height;
  final double? cardWidth;
  final int itemCount;
  final double spacing;
  final EdgeInsetsGeometry padding;

  @override
  State<ShimmerCarousel> createState() => _ShimmerCarouselState();
}

class _ShimmerCarouselState extends State<ShimmerCarousel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!inTest) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight =
        widget.height ?? Breakpoints.carouselHeight(context);
    final effectiveWidth =
        widget.cardWidth ?? Breakpoints.cardWidth(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0xFFEBEBF2),
            Color(0xFFF7F7FA),
            Color(0xFFEBEBF2),
          ],
          stops: [
            (_controller.value - 0.3).clamp(0.0, 1.0),
            _controller.value.clamp(0.0, 1.0),
            (_controller.value + 0.3).clamp(0.0, 1.0),
          ],
        );

        return SizedBox(
          height: effectiveHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: widget.padding,
            itemCount: widget.itemCount,
            separatorBuilder: (context, i) =>
                SizedBox(width: widget.spacing),
            itemBuilder: (context, i) => SizedBox(
              width: effectiveWidth,
              child: ShimmerNewsCard(
                shimmerGradient: shimmerGradient,
                height: effectiveHeight,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerNewsCard extends StatelessWidget {
  const ShimmerNewsCard({
    super.key,
    required this.shimmerGradient,
    this.height = 200,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  final LinearGradient shimmerGradient;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: shimmerGradient,
            ),
          ),
          // Top right date badge skeleton
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 75,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Bottom left multi-line title skeleton
          Positioned(
            left: 10,
            right: 56,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Bottom right source logo circle skeleton
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
