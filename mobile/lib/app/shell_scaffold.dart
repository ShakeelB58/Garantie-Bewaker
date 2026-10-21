import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Hoofdindeling met de onderste balk: vier tabbladen en in het midden een
/// ronde knop om een aankoop toe te voegen.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (
      icon: Icons.home_outlined,
      selected: Icons.home,
      label: 'Home',
      key: 'home',
    ),
    (
      icon: Icons.inventory_2_outlined,
      selected: Icons.inventory_2,
      label: 'Producten',
      key: 'products',
    ),
    (
      icon: Icons.description_outlined,
      selected: Icons.description,
      label: 'Documenten',
      key: 'documents',
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings,
      label: 'Instellingen',
      key: 'settings',
    ),
  ];

  void _select(int index) => navigationShell.goBranch(
    index,
    // Opnieuw op het actieve tabblad tikken brengt je terug naar het begin.
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    Widget tab(int index) {
      final t = _tabs[index];
      return Expanded(
        child: _TabItem(
          key: Key('nav.${t.key}'),
          icon: t.icon,
          selectedIcon: t.selected,
          label: t.label,
          selected: navigationShell.currentIndex == index,
          onTap: () => _select(index),
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Material(
        color: AppColors.surface,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  tab(0),
                  tab(1),
                  Expanded(
                    // heightFactor: anders wordt de balk zo hoog als het scherm.
                    child: Center(
                      heightFactor: 1,
                      child: _AddButton(
                        onPressed: () => context.push(AppRoutes.addPurchase),
                      ),
                    ),
                  ),
                  tab(2),
                  tab(3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.teal : AppColors.textMuted;
    // Labels groeien beperkt mee, zodat de balk bij grote tekst niet overloopt.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Semantics(
        selected: selected,
        button: true,
        child: InkResponse(
          onTap: onTap,
          containedInkWell: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Aankoop toevoegen',
      child: Material(
        color: AppColors.teal,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          key: const Key('nav.add'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
