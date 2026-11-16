import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/search_bar_controller.dart';
import '../../core/theme.dart';

/// Prompt-style search pinned to the bottom of every page.
class PromptSearchBar extends GetView<SearchBarController> {
  const PromptSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(color: Color(0x1A1B2150), blurRadius: 24, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.badge),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: controller.submit,
                    decoration: const InputDecoration(
                      hintText: 'Search news...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.ink),
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: 'Search',
                  onPressed: () => controller.submit(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
