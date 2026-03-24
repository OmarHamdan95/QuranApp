import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Main scaffold wrapping the bottom navigation shell.
///
/// Uses [StatefulNavigationShell] to preserve tab state across navigation.
/// Each tab maintains its own navigation stack.
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'الرئيسية',
              tooltip: 'الرئيسية',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: 'القرآن',
              tooltip: 'القرآن',
            ),
            NavigationDestination(
              icon: const Icon(Icons.mosque_outlined),
              selectedIcon: const Icon(Icons.mosque),
              label: 'الصلاة',
              tooltip: 'الصلاة',
            ),
            NavigationDestination(
              icon: const Icon(Icons.school_outlined),
              selectedIcon: const Icon(Icons.school),
              label: 'الحفظ',
              tooltip: 'الحفظ',
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz_outlined),
              selectedIcon: const Icon(Icons.more_horiz),
              label: 'المزيد',
              tooltip: 'المزيد',
            ),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          indicatorColor: isDark
              ? AppColors.primaryDark.withValues(alpha: 0.3)
              : AppColors.primaryContainer,
        ),
      ),
    );
  }
}
