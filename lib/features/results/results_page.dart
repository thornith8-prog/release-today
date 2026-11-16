import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gif_view/gif_view.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../controllers/results_controller.dart';
import '../../controllers/search_bar_controller.dart';
import '../../controllers/topic_entry_controller.dart';
import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import '../../data/models/article.dart';
import '../../widgets/article_share_button.dart';
import '../../data/models/chat_turn.dart';
import '../../data/repositories/news_repository.dart';
import '../../data/repositories/topic_entry_repository.dart';

/// A single message in the chat conversation.
enum _ChatRole { user, assistant }

/// Chat-style results page (single column, like ChatGPT).
///
/// - User message bubble (right): the search query / prompt.
/// - Assistant message bubble (left): the results, shown as clean result items.
///
/// Multi-turn continuous chat:
/// - When user submits a follow-up query from the search bar, it appends to
///   the current list rather than destroying the page.
class ResultsPage extends StatefulWidget {
  const ResultsPage({
    super.key,
    this.query,
    this.searchTopicId,
    this.topicId,
    this.topicName,
  });

  final String? query;
  final int? searchTopicId;
  final int? topicId;
  final String? topicName;

  bool get isTopic => topicId != null;

  String get prompt => isTopic ? (topicName ?? 'Topic') : (query ?? '');

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late final ScrollController _scroll;
  bool _hasScrolledForInitialData = false;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _syncSearchTopicContext();
    _setupSearchSubmission();
  }

  @override
  void didUpdateWidget(covariant ResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topicId != widget.topicId ||
        oldWidget.query != widget.query ||
        oldWidget.isTopic != widget.isTopic) {
      _hasScrolledForInitialData = false;
    }
    _syncSearchTopicContext();
    _setupSearchSubmission();
  }

  void _syncSearchTopicContext() {
    if (!Get.isRegistered<SearchBarController>()) return;
    final activeId = widget.isTopic ? widget.topicId : widget.searchTopicId;
    Get.find<SearchBarController>().setActiveTopic(activeId);
  }

  void _setupSearchSubmission() {
    if (!Get.isRegistered<SearchBarController>()) return;
    Get.find<SearchBarController>().onSearchSubmitted = _handleSearchSubmission;
  }

  void _teardownSearchSubmission() {
    if (!Get.isRegistered<SearchBarController>()) return;
    final sbc = Get.find<SearchBarController>();
    if (sbc.onSearchSubmitted == _handleSearchSubmission) {
      sbc.onSearchSubmitted = null;
    }
  }

  void _handleSearchSubmission(String query) async {
    if (widget.isTopic) {
      final tag = 'topic-${widget.topicId}';
      if (Get.isRegistered<TopicEntryController>(tag: tag)) {
        final c = Get.find<TopicEntryController>(tag: tag);
        await c.appendSearch(query);
        _scrollToLastBubble(c.turns.toList());
      }
    } else {
      final tag = '${widget.query ?? ""}-${widget.searchTopicId ?? ""}';
      if (Get.isRegistered<ResultsController>(tag: tag)) {
        final c = Get.find<ResultsController>(tag: tag);
        await c.appendSearch(query);
        _scrollToLastBubble(c.turns.toList());
      }
    }
  }

  @override
  void dispose() {
    _teardownSearchSubmission();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(target);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        if (_scroll.position.pixels < _scroll.position.maxScrollExtent) {
          if (animate) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          } else {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        }
      });
    });
  }

  void _scrollToLastPrompt(List<ChatTurn> turns, {bool animate = true}) {
    if (turns.isEmpty) {
      _scrollToBottom(animate: animate);
      return;
    }
    final lastTurn = turns.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = lastTurn.promptKey.currentContext;
      if (context == null || !_scroll.hasClients) {
        _scrollToBottom(animate: animate);
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  /// Scrolls so the last assistant message bubble (the last [_ChatBubble])
  /// is visible at the top of the chat list when a new search is appended.
  /// Falls back to scrolling to the bottom when there are no turns or the
  /// bubble context isn't ready.
  void _scrollToLastBubble(List<ChatTurn> turns, {bool animate = true}) {
    if (turns.isEmpty) {
      _scrollToBottom(animate: animate);
      return;
    }
    final lastTurn = turns.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = lastTurn.responseKey.currentContext;
      if (context == null || !_scroll.hasClients) {
        _scrollToBottom(animate: animate);
        return;
      }
      Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: animate ? const Duration(milliseconds: 300) : Duration.zero,
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = Breakpoints.pagePadding(context);

    if (widget.isTopic) {
      return GetX<TopicEntryController>(
        tag: 'topic-${widget.topicId}',
        init: TopicEntryController(
          Get.isRegistered<ApiTopicEntryRepository>()
              ? Get.find<ApiTopicEntryRepository>()
              : Get.find<TopicEntryRepository>(),
          topicId: widget.topicId!,
        ),
        builder: (c) {
          Widget? errorView;
          if (c.error.value != null && c.turns.isEmpty && c.entries.isEmpty) {
            errorView = _ErrorBanner(
              message: c.error.value!,
              onRetry: () {
                _hasScrolledForInitialData = false;
                c.load();
              },
            );
          }

          final effectivePrompt = (widget.topicName != null &&
                  widget.topicName!.trim().isNotEmpty &&
                  widget.topicName != 'Topic')
              ? widget.topicName!
              : (c.topicPrompt.value ?? widget.prompt);

          final isAnyLoading =
              c.isLoading.value || c.turns.any((t) => t.isLoading.value);

          if (!c.isLoading.value && c.turns.isNotEmpty && !_hasScrolledForInitialData) {
            _hasScrolledForInitialData = true;
            _scrollToLastPrompt(c.turns.toList());
          }

          return _ChatPage(
            pad: pad,
            prompt: effectivePrompt,
            topErrorView: errorView,
            turns: c.turns.toList(),
            loading: isAnyLoading,
            scrollController: _scroll,
            onRetryTurn: (turn) => c.retryTurn(turn),
            hasMore: c.hasMore,
            isLoadingMore: c.isLoadingMore.value,
            onLoadMore: c.loadMore,
          );
        },
      );
    }

    return GetX<ResultsController>(
      tag: '${widget.query ?? ""}-${widget.searchTopicId ?? ""}',
      init: ResultsController(
        query: widget.query ?? '',
        topicId: widget.searchTopicId,
        repository: Get.find<ApiNewsRepository>(),
      ),
      builder: (c) {
        Widget? errorView;
        if (c.error.value != null && c.turns.isEmpty && c.articles.isEmpty) {
          errorView = _ErrorBanner(
            message: c.error.value!,
            onRetry: () {
              _hasScrolledForInitialData = false;
              c.load();
            },
          );
        }

        final isAnyLoading =
            c.isLoading.value || c.turns.any((t) => t.isLoading.value);

        if (!c.isLoading.value &&
            (c.turns.isNotEmpty || c.articles.isNotEmpty) &&
            !_hasScrolledForInitialData) {
          _hasScrolledForInitialData = true;
          _scrollToLastPrompt(c.turns.toList());
        }

        return _ChatPage(
          pad: pad,
          prompt: widget.prompt,
          topErrorView: errorView,
          turns: c.turns.toList(),
          loading: isAnyLoading,
          scrollController: _scroll,
          onRetryTurn: (turn) => c.retryTurn(turn),
          hasMore: false,
          isLoadingMore: false,
          onLoadMore: null,
        );
      },
    );
  }
}

/// The chat page shell: header + scrolling multi-turn conversation list.
class _ChatPage extends StatelessWidget {
  const _ChatPage({
    required this.pad,
    required this.prompt,
    required this.topErrorView,
    required this.turns,
    required this.loading,
    required this.scrollController,
    required this.onRetryTurn,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  final double pad;
  final String prompt;
  final Widget? topErrorView;
  final List<ChatTurn> turns;
  final bool loading;
  final ScrollController scrollController;
  final void Function(ChatTurn) onRetryTurn;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  Widget _buildTurn(BuildContext context, ChatTurn turn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // User message bubble (right)
        _ChatBubble(
          key: turn.promptKey,
          role: _ChatRole.user,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  turn.prompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(turn.timestamp.toLocal()),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Assistant response bubble (left)
        Obx(() {
          if (turn.isLoading.value && turn.articles.isEmpty) {
            return const _ChatBubble(
              role: _ChatRole.assistant,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _TypingIndicator(),
              ),
            );
          }
          if (turn.error.value != null && turn.articles.isEmpty) {
            return _ErrorBanner(
              message: turn.error.value!,
              onRetry: () => onRetryTurn(turn),
            );
          }
          if (turn.articles.isEmpty) {
            return const _EmptyChat(
              message: 'No results found. Try a different search.',
            );
          }
          return _ChatBubble(
            key: turn.responseKey,
            role: _ChatRole.assistant,
            child: _ResultItems(
              items: turn.articles.map((a) => _Result(article: a)).toList(),
              onLoadMore: () {},
              hasMore: false,
              isLoadingMore: false,
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.badge,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Release Today',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      prompt,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // if (loading)
              //   const SizedBox(
              //     height: 18,
              //     width: 18,
              //     child: CircularProgressIndicator(strokeWidth: 2),
              //   ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (topErrorView != null) topErrorView!,
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 90),
            children: [
              if (hasMore && onLoadMore != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: onLoadMore,
                      icon: isLoadingMore
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SizedBox.shrink(),
                      label: Text(
                        isLoadingMore ? 'Loading older entries…' : '',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
              if (turns.isNotEmpty)
                for (final turn in turns) _buildTurn(context, turn)
              else if (loading) ...[
                _ChatBubble(
                  role: _ChatRole.user,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _ChatBubble(
                  role: _ChatRole.assistant,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: _TypingIndicator(),
                  ),
                ),
              ] else
                const _EmptyChat(
                  message: 'No results found. Try a different search.',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A message bubble: user (right, colored) or assistant (left, card).
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    super.key,
    required this.role,
    required this.child,
  });

  final _ChatRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isUser = role == _ChatRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isUser ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          border: isUser ? null : Border.all(color: AppColors.line),
          boxShadow: isUser
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// Typing indicator shown while the assistant loads results.
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GifView.asset(
          'assets/gifs/gif_loading.gif',
          width: 30,
          height: 30,
          frameRate: 150,
          errorBuilder: (context, error, tryAgain) => const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Searching news…',
          style: TextStyle(
            color: AppColors.ink.withValues(alpha: 0.6),
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Error banner shown when the assistant fails to load.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty chat state when there are no results.
class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline,
                size: 28, color: AppColors.line),
            const SizedBox(height: 10),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A search result wrapping an article.
class _Result {
  const _Result({required this.article});

  final ArticleData article;

  String get title => article.title ?? '';

  String get imageUrl => article.imageUrl ?? '';

  String get summary => article.summary ?? '';

  String get source => article.source ?? '';

  String? get url => article.url;

  String get publishedAtText => article.publishedAtText;
}

/// List of result items rendered inside the assistant bubble.
///
/// Items are revealed one by one with a short gap between each until all
/// data is shown, giving the assistant response a progressive stream effect.
class _ResultItems extends StatefulWidget {
  const _ResultItems({
    required this.items,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoadingMore,
    this.streamInterval = const Duration(milliseconds: 120), // ignore: unused_element_parameter
    this.streamEnabled = false, // ignore: unused_element_parameter
  });

  final List<_Result> items;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;

  /// Delay between each revealed item.
  final Duration streamInterval;

  /// Whether to stream items in or show them all at once.
  final bool streamEnabled;

  static final Set<String> _streamedHistory = <String>{};

  @override
  State<_ResultItems> createState() => _ResultItemsState();
}

class _ResultItemsState extends State<_ResultItems> {
  Timer? _timer;
  int _displayedCount = 0;
  bool _isComplete = false;

  /// Content-based key so identical item lists don't re-stream across rebuilds.
  String get _effectiveKey =>
      widget.items.map((i) => '${i.url ?? i.title}::${i.summary.length}').join('\n');

  bool _sameItems(List<_Result> a, List<_Result> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].url != b[i].url || a[i].title != b[i].title) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _resetDisplay();
  }

  @override
  void didUpdateWidget(covariant _ResultItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameItems(oldWidget.items, widget.items)) {
      _resetDisplay();
    }
  }

  void _resetDisplay() {
    _timer?.cancel();
    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!widget.streamEnabled ||
        widget.items.isEmpty ||
        inTest ||
        _ResultItems._streamedHistory.contains(_effectiveKey)) {
      _displayedCount = widget.items.length;
      _isComplete = true;
    } else {
      _displayedCount = 0;
      _isComplete = false;
      _startStreaming();
    }
  }

  void _startStreaming() {
    _timer = Timer.periodic(widget.streamInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_displayedCount < widget.items.length) {
          _displayedCount++;
        }
        if (_displayedCount >= widget.items.length) {
          _isComplete = true;
          _ResultItems._streamedHistory.add(_effectiveKey);
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in widget.items.take(_displayedCount))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _ResultTile(result: item),
          ),
        if (_isComplete && widget.isLoadingMore)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        if (widget.hasMore &&
            !widget.isLoadingMore &&
            widget.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onLoadMore,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Load more', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.badge,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Shimmer animation placeholder for image loading.
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

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
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
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

/// Renders text with a ChatGPT / Gemini-style typewriter stream animation.
class StreamingText extends StatefulWidget {
  const StreamingText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
    this.charChunk = 2,
    this.speed = Duration.zero,
    this.showCursor = true,
    this.streamKey,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;
  final int charChunk;
  final Duration speed;
  final bool showCursor;
  final String? streamKey;

  static final Set<String> _streamedHistory = <String>{};

  static void resetCache() => _streamedHistory.clear();

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  Timer? _timer;
  int _charCount = 0;
  bool _isComplete = false;

  String get _effectiveKey =>
      widget.streamKey ?? '${widget.text.hashCode}_${widget.text.length}';

  @override
  void initState() {
    super.initState();
    final inTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (inTest || StreamingText._streamedHistory.contains(_effectiveKey)) {
      _charCount = widget.text.length;
      _isComplete = true;
    } else {
      _startStreaming();
    }
  }

  @override
  void didUpdateWidget(covariant StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (StreamingText._streamedHistory.contains(_effectiveKey)) {
        _charCount = widget.text.length;
        _isComplete = true;
      } else {
        _startStreaming();
      }
    }
  }

  void _startStreaming() {
    _timer?.cancel();
    if (widget.text.isEmpty) {
      _charCount = 0;
      _isComplete = true;
      return;
    }
    if (widget.speed.inMilliseconds <= 0) {
      _charCount = widget.text.length;
      _isComplete = true;
      return;
    }

    _charCount = 0;
    _isComplete = false;

    _timer = Timer.periodic(widget.speed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _charCount =
            (_charCount + widget.charChunk).clamp(0, widget.text.length);
        if (_charCount >= widget.text.length) {
          _isComplete = true;
          StreamingText._streamedHistory.add(_effectiveKey);
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        softWrap: widget.softWrap,
        style: widget.style,
      );
    }

    final visibleText = widget.text.substring(0, _charCount);

    return Text.rich(
      TextSpan(
        text: visibleText,
        style: widget.style,
        children: [
          if (widget.showCursor)
            TextSpan(
              text: ' ▍',
              style: (widget.style ?? const TextStyle()).copyWith(
                color: AppColors.field,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
    );
  }
}

/// A single result tile shown inside the assistant chat bubble.
class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final _Result result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final itemKey = result.url != null && result.url!.isNotEmpty
        ? result.url!
        : result.title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: result.url != null && result.url!.isNotEmpty
            ? () async {
                final uri = Uri.tryParse(result.url!);
                if (uri != null &&
                    (uri.scheme == 'http' || uri.scheme == 'https')) {
                  await launchUrl(uri, webOnlyWindowName: '_blank');
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    result.imageUrl,
                    width: 150,
                    height: 80,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const ShimmerLoading(
                        width: 150,
                        height: 80,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      );
                    },
                    errorBuilder: (context, error, stack) => Image.asset(
                      'assets/icons/ic_news.png',
                      width: 150,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamingText(
                      text: result.title,
                      streamKey: 'title_$itemKey',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    if (result.summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      StreamingText(
                        text: result.summary,
                        streamKey: 'summary_$itemKey',
                        maxLines: null,
                        softWrap: true,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (result.source.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.badge.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              result.source,
                              style: const TextStyle(
                                color: AppColors.badge,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (result.publishedAtText.isNotEmpty) ...[
                          Text(
                            _getCurrentDate(result.publishedAtText),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.ink.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Separate tap target: sharing does not open the publisher link.
              ArticleShareButton(article: result.article),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentDate(String date) {
    final sqlParsedDate = DateTime.tryParse(date)?.toLocal();
    if (sqlParsedDate == null) return date;
    return DateFormat('dd/MMM/yyyy').format(sqlParsedDate);
  }
}
