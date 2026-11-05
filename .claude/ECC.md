# Extraits d'ECC (Everything Claude Code)

Source : dépôt GitHub `affaan-m/ECC` (branche `main`, copie fournie par la propriétaire du projet le 05/11/2026), licence MIT (`ECC_LICENSE`).

Seules les parties utiles à un projet Flutter / Dart ont été reprises :

| Élément | Rôle |
|---|---|
| `skills/dart-flutter-patterns` | modèles Flutter / Dart (état, navigation, tests, performances) |
| `skills/flutter-dart-code-review` | grille de relecture du code Flutter |
| `agents/flutter-reviewer.md` | agent de relecture (rapporte, ne modifie pas) |
| `agents/dart-build-resolver.md` | agent de résolution des erreurs de compilation et d'analyse |
| `rules/dart/` | conventions Dart (style, modèles, sécurité, tests) |

Non repris : les hooks (ils lancent des commandes à chaque modification et supposent Flutter installé localement, alors que la CI fait foi), les installateurs, les tableaux de bord et les compétences sans rapport avec ARISE.

**Priorité** : en cas de désaccord, `CLAUDE.md` et `docs/` l'emportent sur ces extraits (par exemple : Riverpod + `riverpod_generator`, Drift, `very_good_analysis`, commentaires en français).
