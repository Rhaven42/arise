import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_spacing.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:flutter/material.dart';

/// Emplacement de la barre d'action.
class DockItem {
  const DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Key? key;
}

/// Barre d'action en bas d'écran, façon barre de sorts : deux
/// emplacements de chaque côté d'un grand bouton central doré.
class ActionDock extends StatelessWidget {
  const ActionDock({required this.items, required this.center, super.key})
    : assert(items.length == 4, 'Quatre emplacements autour du centre');

  final List<DockItem> items;
  final DockItem center;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AriseColors.panelBottom, AriseColors.backdropBottom],
        ),
        border: Border(top: BorderSide(color: AriseColors.bronzeEdge)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AriseSpacing.sm,
            AriseSpacing.sm,
            AriseSpacing.sm,
            AriseSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 2; i++) _Slot(item: items[i], hotkey: i + 1),
              _CenterButton(item: center),
              for (var i = 2; i < 4; i++) _Slot(item: items[i], hotkey: i + 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.item, required this.hotkey});

  final DockItem item;
  final int hotkey;

  @override
  Widget build(BuildContext context) {
    final on = item.selected;
    final color = on ? AriseColors.goldBright : AriseColors.parchmentMuted;
    return Semantics(
      button: true,
      selected: on,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        key: item.key,
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AriseSpacing.radius),
        child: Container(
          width: 64,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AriseSpacing.radius),
            gradient: const RadialGradient(
              center: Alignment(0, -0.4),
              colors: [Color(0xFF3A322B), AriseColors.panelBottom],
            ),
            border: Border.all(
              color: on ? AriseColors.goldBright : AriseColors.bronzeEdge,
            ),
            boxShadow: on
                ? [
                    BoxShadow(
                      color: AriseColors.goldBright.withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                left: 5,
                top: 2,
                child: Text(
                  '$hotkey',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AriseColors.parchmentMuted,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon, color: AriseColors.gold, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AriseTypography.display,
                        fontVariations: AriseTypography.weight(700),
                        fontSize: 9.5,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.item});

  final DockItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        key: item.key,
        onTap: item.onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(0, -0.3),
              colors: [
                AriseColors.goldPale,
                AriseColors.gold,
                Color(0xFF7A5A22),
              ],
              stops: [0, 0.45, 1],
            ),
            border: Border.all(color: const Color(0xFFFFF3C9), width: 2),
            boxShadow: [
              const BoxShadow(color: Color(0xFF2A1D0A), spreadRadius: 3),
              BoxShadow(
                color: AriseColors.goldBright.withValues(alpha: 0.6),
                blurRadius: 22,
              ),
            ],
          ),
          child: Icon(item.icon, color: AriseColors.onGold, size: 34),
        ),
      ),
    );
  }
}
