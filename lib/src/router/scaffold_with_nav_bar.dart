import 'dart:ui';

import 'package:congregate/src/features/business/presentation/view/create_business_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:motor/motor.dart';

class RootShell extends StatelessWidget {
  const RootShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavBarItem>[
    _NavBarItem(
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      label: 'Following',
    ),
    _NavBarItem(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      label: 'Businesses',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selectedIndex = navigationShell.currentIndex;

    final navColors = M3EFloatingToolbarColors(
      toolbarContainerColor: cs.primary,
      toolbarContentColor: cs.onPrimary,
      fabContainerColor: cs.primaryContainer,
      fabContentColor: cs.onPrimaryContainer,
    );

    final decoration = M3EFloatingToolbarDecoration(
      motion: const M3EMotion.custom(stiffness: 900, damping: 0.5),
      colors: navColors,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      expandedShadowElevation: 6,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_items.length, (i) {
        final item = _items[i];
        return _M3ENavBarTab(
          key: ValueKey(item.label),
          item: item,
          isSelected: i == selectedIndex,
          onTap: () => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
        );
      }),
    );

    final fabs = _fabsForIndex(context, selectedIndex);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final extra in fabs.extras) ...[
                    extra,
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: fabs.attached == null
                        ? M3EHorizontalFloatingToolbar(
                            expanded: true,
                            decoration: decoration,
                            content: content,
                          )
                        : M3EFabHorizontalFloatingToolbar(
                            expanded: true,
                            decoration: decoration,
                            fabPosition:
                                M3EFloatingToolbarHorizontalFabPosition.end,
                            floatingActionButton: fabs.attached!,
                            content: content,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ShellFabs _fabsForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        return const _ShellFabs(attached: null, extras: []);
      case 1:
        return _ShellFabs(
          attached: M3EFloatingToolbarDefaults.standardFab(
            context: context,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const CreateBusinessSheet(),
            ),
            child: const Icon(Icons.add_business_outlined),
          ),
          extras: const [],
        );
      default:
        return const _ShellFabs(attached: null, extras: []);
    }
  }
}

class _ShellFabs {
  const _ShellFabs({required this.attached, required this.extras});
  final Widget? attached;
  final List<Widget> extras;
}

class _NavBarItem {
  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _M3ENavBarTab extends StatefulWidget {
  const _M3ENavBarTab({
    required this.item,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final _NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_M3ENavBarTab> createState() => _M3ENavBarTabState();
}

class _M3ENavBarTabState extends State<_M3ENavBarTab>
    with SingleTickerProviderStateMixin {
  late final SingleMotionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SingleMotionController(
      motion: const M3EMotion.custom(stiffness: 800, damping: 0.4).toMotion(),
      vsync: this,
      initialValue: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(covariant _M3ENavBarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      _controller.animateTo(widget.isSelected ? 1.0 : 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value.clamp(0.0, 1.0);
        final width = lerpDouble(48, 140, progress)!;

        final bgColor = widget.isSelected
            ? theme.colorScheme.surface
            : Colors.transparent;

        final contentColor = widget.isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onPrimary;

        return Container(
          width: width,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return contentColor.withValues(alpha: 0.12);
                }
                if (states.contains(WidgetState.hovered)) {
                  return contentColor.withValues(alpha: 0.08);
                }
                if (states.contains(WidgetState.focused)) {
                  return contentColor.withValues(alpha: 0.12);
                }
                return null;
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isSelected
                        ? widget.item.selectedIcon
                        : widget.item.icon,
                    color: contentColor,
                    size: 24,
                  ),
                  if (progress > 0.01)
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Opacity(
                          opacity: progress,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              widget.item.label,
                              style: TextStyle(
                                color: contentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
