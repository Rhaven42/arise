import 'package:arise/core/config/game_config.dart';
import 'package:arise/core/theme/arise_colors.dart';
import 'package:arise/core/theme/arise_typography.dart';
import 'package:arise/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Écusson de rang (E à S, puis Monarque).
class RankBadge extends StatelessWidget {
  const RankBadge({required this.rank, super.key, this.size = 56});

  final RankId rank;
  final double size;

  /// Couleur d'accent associée à chaque rang.
  static Color colorOf(RankId rank) => switch (rank) {
    RankId.e => AriseColors.parchmentMuted,
    RankId.d => AriseColors.success,
    RankId.c => AriseColors.mana,
    RankId.b => const Color(0xFFB08CE8),
    RankId.a => AriseColors.ember,
    RankId.s => AriseColors.gold,
    RankId.monarch => AriseColors.goldBright,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = l10n.rankName(rank.name);
    final accent = colorOf(rank);

    return Semantics(
      label: l10n.rankSemantics(name),
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [AriseColors.stoneLight, AriseColors.stoneDark],
            ),
            border: Border.all(color: accent, width: 3),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 10),
            ],
          ),
          child: rank == RankId.monarch
              ? Icon(Icons.workspace_premium, color: accent, size: size * 0.55)
              : Text(
                  name,
                  style: TextStyle(
                    fontFamily: AriseTypography.display,
                    fontVariations: AriseTypography.weight(900),
                    fontSize: size * 0.45,
                    color: accent,
                  ),
                ),
        ),
      ),
    );
  }
}
