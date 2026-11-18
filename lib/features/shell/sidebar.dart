import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../controllers/app_controller.dart';
import '../../controllers/topics_controller.dart';
import '../../core/navigation.dart';
import '../../core/theme.dart';
import '../../data/models/topic.dart';
import '../../widgets/auth_dialog.dart';

class AppSidebar extends GetView<AppController> {
  const AppSidebar({
    super.key,
    this.onNavigate,
    this.currentPath = '/',
  });

  /// Called after a navigation, so the mobile drawer can close itself.
  final VoidCallback? onNavigate;

  /// Active route path used to highlight the selected sidebar item.
  final String currentPath;

  static final ShapeBorder _tileShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  Widget _buildNavTile({
    required Widget leading,
    required Widget title,
    required bool selected,
    required VoidCallback onTap,
    bool dense = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: dense,
        selected: selected,
        shape: _tileShape,
        selectedColor: AppColors.ink,
        selectedTileColor: AppColors.ink.withValues(alpha: 0.08),
        leading: leading,
        title: title,
        onTap: () {
          onNavigate?.call();
          onTap();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            children: [
              _buildNavTile(
                leading: SizedBox.square(
                  dimension: 24,
                  child: SvgPicture.asset('assets/icons/icon_home.svg'),
                ),
                title: Text('Home', style: textTheme.titleSmall),
                selected: currentPath == '/',
                onTap: AppNav.goHome,
              ),
              Obx(() {
                if (controller.user.value == null) {
                  return const SizedBox.shrink();
                }
                return GetX<TopicsController>(
                  builder: (tc) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: SizedBox.square(
                          dimension: 24,
                          child:
                              SvgPicture.asset('assets/icons/icon_recent.svg'),
                        ),
                        title: Text('Recent', style: textTheme.titleSmall),
                      ),
                      if (tc.error.value != null && tc.topicsItem.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Text(
                            tc.error.value!,
                            style: textTheme.bodySmall
                                ?.copyWith(color: AppColors.avatar),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      for (final t in tc.topicsItem)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 1),
                          child: ListTile(
                            dense: true,
                            shape: _tileShape,
                            selected: t.id != null &&
                                currentPath == '/topics/${t.id}/entries',
                            selectedColor: AppColors.ink,
                            selectedTileColor:
                                AppColors.ink.withValues(alpha: 0.08),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            leading: const Icon(Icons.label_outline, size: 20),
                            title: Text(t.label,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: t.description != null &&
                                    t.description!.isNotEmpty
                                ? Text(t.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodySmall)
                                : null,
                            trailing: (t.id != null)
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.avatar),
                                    tooltip: 'Delete topic',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 16,
                                    onPressed: () =>
                                        _confirmDeleteTopic(context, tc, t),
                                  )
                                : null,
                            onTap: () {
                              onNavigate?.call();
                              if (t.id != null) {
                                AppNav.goTopicEntries(t.id!, t.label);
                              } else {
                                AppNav.goSearch(t.label);
                              }
                            },
                          ),
                        ),
                      if (tc.isLoadingMore.value)
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      if (tc.hasMore &&
                          !tc.isLoadingMore.value &&
                          tc.topicsItem.isNotEmpty)
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          title: const Text('Load more topics',
                              style: TextStyle(fontSize: 13)),
                          onTap: tc.loadMore,
                        ),
                    ],
                  ),
                );
              }),
              _buildNavTile(
                dense: true,
                leading: SizedBox.square(
                  dimension: 24,
                  child: SvgPicture.asset('assets/icons/icon_about_us.svg'),
                ),
                title: const Text('About us'),
                selected: currentPath == '/about',
                onTap: AppNav.goAbout,
              ),
              _buildNavTile(
                dense: true,
                leading: SizedBox.square(
                  dimension: 24,
                  child: SvgPicture.asset('assets/icons/icon_what_we_do.svg'),
                ),
                title: const Text('What we do'),
                selected: currentPath == '/what-we-do',
                onTap: AppNav.goWhatWeDo,
              ),
              _buildNavTile(
                dense: true,
                leading: SizedBox.square(
                  dimension: 24,
                  child: SvgPicture.asset('assets/icons/icon_term.svg'),
                ),
                title: const Text('Terms & conditions'),
                selected: currentPath == '/terms',
                onTap: AppNav.goTerms,
              ),
              _buildNavTile(
                dense: true,
                leading: SizedBox.square(
                  dimension: 24,
                  child: SvgPicture.asset('assets/icons/icon_privacy.svg'),
                ),
                title: const Text('Privacy & policy'),
                selected: currentPath == '/privacy',
                onTap: AppNav.goPrivacy,
              ),
              _buildNavTile(
                dense: true,
                leading: const Icon(Icons.send,
                    size: 20, color: Color(0xFF0088CC)),
                title: const Text('Telegram Mini App'),
                selected: currentPath == '/telegram-support',
                onTap: AppNav.goTelegramSupport,
              ),
            ],
          ),
        ),
        _userProfiles(context, textTheme),
      ],
    );
  }

  Widget _userProfiles(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        _userProfile(context, textTheme),
        const Center(
          child: Text(
            'Version: 1.0.0-Belta',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _userProfile(BuildContext context, TextTheme textTheme) {
    return Obx(() {
      final user = controller.user.value;
      if (user == null) return _signedOutProfile(context, textTheme);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: InkWell(
            onTap: () => _showProfileDialog(context, user),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.avatar,
                    child: Text(
                      user.name.characters.first.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      user.name,
                      style: textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  /// Always-rendered bottom section: prompts the user to sign in when no
  /// session exists, keeping the profile area pinned at the bottom either way.
  Widget _signedOutProfile(BuildContext context, TextTheme textTheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          onTap: () => showAuthDialog(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.avatar,
                  child: Icon(
                    Icons.login,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sign in',
                    style: textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, AppUser user) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (ctx) => Dialog(
        alignment: Alignment.bottomLeft,
        backgroundColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        insetPadding:
            const EdgeInsets.only(left: 12, bottom: 84, right: 12, top: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 256),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.avatar,
                          child: Text(
                            user.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user.email != null &&
                                  user.email!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  user.email!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.ink
                                            .withValues(alpha: 0.6),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Signed in via ${user.provider}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (user.isVerified) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: AppColors.badge,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Verified account',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.badge,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading:
                    const Icon(Icons.logout, size: 20, color: AppColors.avatar),
                title: const Text('Sign out'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.logout();
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTopic(
    BuildContext context,
    TopicsController tc,
    TopicItems topic,
  ) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete topic?'),
          content: Text(
            'Are you sure you want to delete "${topic.label}"? This will remove all its search history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true && topic.id != null) {
        final success = await tc.deleteTopic(topic.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Topic "${topic.label}" deleted'
                    : 'Failed to delete topic',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }
}
