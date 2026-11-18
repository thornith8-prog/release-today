import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controller.dart';
import '../../widgets/auth_dialog.dart';
import '../../widgets/pill_button.dart';

class TopBar extends GetView<AppController> {
  const TopBar({super.key, required this.onMenu, required this.wide});

  final VoidCallback onMenu;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 24 : 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: wide ? 'Toggle sidebar' : 'Menu',
            icon: Icon(wide ? Icons.view_sidebar_outlined : Icons.menu),
            onPressed: onMenu,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Obx(() {
                if (controller.user.value != null) {
                  return Row(
                    spacing: 10,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PillButton(
                          label: 'Contact Us', onPressed: controller.contactUs)
                    ],
                  );
                }
                return Row(
                  spacing: 10,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PillButton(
                      label: 'Sign in',
                      onPressed: () => showAuthDialog(
                        context,
                        initialMode: AuthDialogMode.signIn,
                      ),
                    ),
                    PillButton(
                      label: 'Sign up',
                      filled: true,
                      onPressed: () => showAuthDialog(
                        context,
                        initialMode: AuthDialogMode.signUp,
                      ),
                    ),
                    PillButton(
                        label: 'Contact Us', onPressed: controller.contactUs)
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
