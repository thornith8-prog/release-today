import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controller.dart';
import '../../core/breakpoints.dart';
import '../../core/theme.dart';
import 'prompt_search_bar.dart';
import 'sidebar.dart';
import 'top_bar.dart';

/// Responsive frame around every page.
/// - desktop (>=1024): collapsible permanent sidebar
/// - tablet / mobile: sidebar lives in a drawer opened from the menu button
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Only the drawer key is local UI state; everything else is in AppController.
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _app = Get.find<AppController>();

  void _onMenu(bool wide) {
    if (wide) {
      _app.toggleSidebar();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) == ScreenSize.desktop;

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              width: 300,
              backgroundColor: Colors.white,
              child: SafeArea(
                child: AppSidebar(
                    onNavigate: () => _scaffoldKey.currentState?.closeDrawer()),
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide) Obx(() => _AnimatedSidebar(open: _app.sidebarOpen.value)),
            Expanded(
              child: Column(
                children: [
                  TopBar(wide: wide, onMenu: () => _onMenu(wide)),
                  Expanded(child: widget.child),
                  const PromptSearchBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gemini-style collapsible sidebar: the panel width eases between 280 and 0
/// while its content keeps a fixed layout (no text reflow) and fades, so the
/// main area slides over smoothly instead of jumping.
class _AnimatedSidebar extends StatelessWidget {
  const _AnimatedSidebar({required this.open});

  final bool open;

  static const double _width = 280;
  static const Duration _duration = Duration(milliseconds: 300);
  static const Curve _curve = Curves.easeInOutCubicEmphasized;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      curve: _curve,
      width: open ? _width : 0,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: _width,
          maxWidth: _width,
          child: AnimatedOpacity(
            duration: _duration,
            // Fade out quickly when closing, fade in a touch later when opening.
            curve: open
                ? const Interval(0.3, 1, curve: Curves.easeOut)
                : const Interval(0, 0.6, curve: Curves.easeIn),
            opacity: open ? 1 : 0,
            child: IgnorePointer(
              ignoring: !open,
              child: ExcludeFocus(
                excluding: !open,
                child: ExcludeSemantics(
                  excluding: !open,
                  child: Container(
                    width: _width,
                    decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: AppColors.line)),
                    ),
                    child: const AppSidebar(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
