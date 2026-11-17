import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/telegram_controller.dart';
import '../../core/breakpoints.dart';

/// Support / demo page showing that Release Today runs as a Telegram Mini App.
///
/// Displays the Telegram user, theme and platform data exposed by
/// [`WebApp`](https://pub.dev/documentation/flutter_telegram_miniapp/) and
/// provides buttons that drive the Telegram host (main button, alert, confirm,
/// open link, close). Outside Telegram it renders a graceful fallback.
class TelegramSupportPage extends StatefulWidget {
  const TelegramSupportPage({super.key});

  @override
  State<TelegramSupportPage> createState() => _TelegramSupportPageState();
}

class _TelegramSupportPageState extends State<TelegramSupportPage> {
  @override
  void initState() {
    super.initState();
    Get.find<TelegramController>().init();
  }

  @override
  Widget build(BuildContext context) {
    return GetX<TelegramController>(
      builder: (controller) {
        final pad = Breakpoints.pagePadding(context);
        final theme = Theme.of(context);
        final textTheme = theme.textTheme;
        final inTelegram = controller.isInTelegram.value;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Icon(Icons.telegram, color: Color(0xFF0088CC)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Telegram Mini App',
                            style: textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusBanner(
                          inTelegram: inTelegram,
                          initializing: !controller.isInitialized.value,
                          error: controller.error.value,
                        ),
                        const SizedBox(height: 24),
                        if (inTelegram) ...[
                          _UserCard(
                            firstName: controller.userFirstName,
                            lastName: controller.userLastName,
                            username: controller.userUsername,
                            photoUrl: controller.userPhotoUrl,
                            isPremium: controller.userIsPremium,
                            colorScheme: controller.colorScheme,
                            platform: controller.platform,
                            version: controller.version,
                            initData: controller.initData,
                          ),
                          const SizedBox(height: 24),
                          _ActionBar(controller: controller),
                          const SizedBox(height: 16),
                          _InfoTile(
                            label: 'Expanded',
                            value: controller.isExpanded ? 'Yes' : 'No',
                          ),
                          _InfoTile(
                            label: 'Viewport height',
                            value:
                                '${controller.viewportHeight.toStringAsFixed(0)} px',
                          ),
                        ] else ...[
                          const _NotInTelegramBox(),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.inTelegram,
    required this.initializing,
    this.error,
  });

  final bool inTelegram;
  final bool initializing;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final color = inTelegram
        ? Colors.green.shade700
        : (error != null ? Colors.red.shade700 : Colors.grey.shade700);
    final bg = color.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            inTelegram ? Icons.check_circle : (error != null ? Icons.error : Icons.info),
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  initializing
                      ? 'Initializing Mini App…'
                      : inTelegram
                          ? 'Running inside Telegram'
                          : 'Not running inside Telegram',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (error != null && error!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    error!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    this.isPremium = false,
    this.colorScheme,
    this.platform,
    this.version,
    this.initData,
  });

  final String? firstName;
  final String? lastName;
  final String? username;
  final String? photoUrl;
  final bool isPremium;
  final String? colorScheme;
  final String? platform;
  final String? version;
  final String? initData;

  String? get _displayName {
    if (firstName == null) return null;
    return lastName != null && lastName!.isNotEmpty
        ? '$firstName $lastName'
        : firstName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (photoUrl != null && photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(photoUrl!),
                )
              else
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF0088CC),
                  child: Icon(Icons.person, color: Colors.white),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName ?? 'Telegram user',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (username != null && username!.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (isPremium)
                const Icon(Icons.star, color: Colors.amber, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          _InfoTile(label: 'Theme', value: colorScheme ?? '—'),
          _InfoTile(label: 'Platform', value: platform ?? '—'),
          _InfoTile(label: 'Bot API version', value: version ?? '—'),
          if (initData != null && initData!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Init data (raw):',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                initData!,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.controller});

  final TelegramController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: () => controller.setMainButtonVisible(true),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Show main button'),
        ),
        OutlinedButton.icon(
          onPressed: () => controller.setMainButtonVisible(false),
          icon: const Icon(Icons.remove, size: 18),
          label: const Text('Hide main button'),
        ),
        OutlinedButton.icon(
          onPressed: () => controller.setBackButtonVisible(true),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Show back button'),
        ),
        FilledButton.icon(
          onPressed: () => controller.showAlert(message: 'Hello from Release Today!'),
          icon: const Icon(Icons.announcement, size: 18),
          label: const Text('Show alert'),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await controller.showConfirm(message: 'Confirm action?');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Confirm: $ok'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          icon: const Icon(Icons.help_outline, size: 18),
          label: const Text('Show confirm'),
        ),
        OutlinedButton.icon(
          onPressed: () => controller.openLink(
            url: 'https://telegram.org',
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Open link'),
        ),
      ],
    );
  }
}

class _NotInTelegramBox extends StatelessWidget {
  const _NotInTelegramBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outside Telegram',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This page is designed to run as a Telegram Mini App. Open it from '
            'within Telegram (via your bot) to see the user, theme and platform '
            'data and to use the Telegram host buttons.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }
}
