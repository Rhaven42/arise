# Outils de création des contenus

Scripts Python (3.11+, Pillow pour les planches de contrôle) qui génèrent les contenus embarqués. Ils ne font pas partie de l'application.

| Script | Produit | Commande |
|---|---|---|
| `silhouettes.py` | `assets/svg/body_front.svg`, `assets/svg/body_back.svg` | `python3 tool/silhouettes.py assets/svg` |
| `motions.py` | `assets/animations/motions.json` + planche PNG des poses | `python3 tool/motions.py assets/animations/motions.json /tmp/poses.png` |
| `catalog.py` | `assets/catalog/exercises.json` (muscles lus dans `docs/ANATOMY.md` §2) | `python3 tool/catalog.py docs/ANATOMY.md assets/catalog/exercises.json` |

Les longueurs des segments de `motions.py` doivent rester identiques à `FigureProportions` (`figure_motion.dart`).
