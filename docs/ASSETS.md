# ASSETS.md — Illustrations, animations et sons

> Origine des illustrations, des animations et des sons, et ce qu'un artiste pourrait fournir. **Uniquement des créations originales ou sous licence compatible avec une publication commerciale sur les stores** : aucun asset de Solo Leveling, de World of Warcraft, de Wowhead ni de toute autre œuvre protégée.

## 1. Animations des exercices (phase 2)

### État actuel
Démonstration par un **mannequin 2D animé** (12/11/2026, à la demande de la propriétaire du projet : les photos et les vidéos 3D étaient moins lisibles). Mannequin articulé dessiné par le code (`FigureAnimation`), muscles travaillés colorés, poses extrêmes en transparence, accessoires simples (barre, banc, box, mur).

- 75 mouvements dans `assets/animations/motions.json`, générés par `tool/motions.py` : chaque exercice du catalogue a le sien ou partage celui d'une variante identique vue de profil (pompes larges ou diamant, chin-up, curl marteau, fente arrière).
- Appuis vérifiés image par image (planche de contrôle et test : mains et pieds ne traversent pas le sol, prises fixes par cinématique inverse).
- Contrôle de tout le cycle (19/11/2026) : `python3 tool/check_motions.py assets/animations/motions.json` et le test `motion_quality_test.dart` vérifient sur 480 images par mouvement que rien ne passe sous le sol dessiné, que genoux et coudes ne plient jamais à l'envers (coude ≤ 155°), qu'il n'y a pas d'à-coup et que les appuis restent fixes.
- Les photos, les vidéos de capture de mouvement et les vidéos 3D du prof médiéval ont été retirées (19/11/2026).

### Livrable attendu (version 3D)
- **Un modèle anatomique** homme et un modèle femme, « écorché » ou semi-réaliste, avec **un maillage séparé par muscle** pour les 33 muscles de docs/ANATOMY.md §1. Chaque maillage est nommé exactement comme l'identifiant (`pectoralis_upper`, `gluteus_medius`…), y compris les côtés gauche et droit (`_l` / `_r`).
- **Squelette humanoïde** compatible Mixamo (nommage standard), avec les doigts.
- **Une animation en boucle par mouvement** listé dans `motions.json` (`squat`, `push_up`, `pull_up`…), 1 à 4 secondes, qui démarre et finit sur la même pose. Animations Mixamo autorisées : elles doivent être **intégrées dans le modèle**, jamais livrées comme fichiers séparés réutilisables.
- **Format** : glTF binaire (`.glb`), un fichier par sexe, animations nommées comme les mouvements.
- **Budget mobile** : 25 000 triangles maximum par modèle, une texture 2048 × 2048 au plus, matériaux PBR simples. La couleur des muscles est appliquée par le code (vert vif / vert clair) : prévoir un matériau neutre par muscle.
- **Licence** : fournir la licence de chaque source (modèle de base, animations), compatible avec une application gratuite ou payante publiée sur Google Play et l'App Store, **sans obligation de partage à l'identique** (pas de CC BY-SA ni de NC).

### Intégration côté code
Une nouvelle implémentation de `ExerciseAnimationPlayer` lira le `.glb`, jouera l'animation dont le nom vaut `exercise.motion` et colorera les maillages des muscles de l'exercice. Aucun écran n'a besoin d'être modifié.

## 2. Héros en pixel art (19/11/2026)

### État actuel
Le héros est dessiné en **pixel art**, en pied, à partir d'images générées avec **SpriteCook** sur le compte de la propriétaire du projet (modèle `gpt-image-2`, qualité basse, 2 crédits l'image). Toutes les images brutes sont dans `tool/sprites/raw/` et leur identifiant SpriteCook dans `tool/sprites/spritecook_manifest.json`.

- **Corps** : 20 (10 races × 2 sexes), même pose et même cadrage, tous dérivés d'un humain chauve. Races : humain, elfe, haut-elfe, orc, nain, gnome, gobelin, démon, minotaure, mort-vivant.
- **Coiffures** : 14 par sexe ; **barbes** : 10. Certaines coiffures sont masquées pour une race et un sexe où elles se posent mal (`hiddenHairStyles`, `character_rules.dart`) ; la coiffure féminine n° 13 est retirée partout (crâne nu entre les chignons). Elles sont générées en magenta vif sur l'humain, détourées par leur teinte (pic de teinte magenta-rose, morceaux reliés au crâne), puis recolorées dans l'appli (la luminance garde le modelé, avec une teinte douce qui empêche les reflets de virer au blanc). Dans une barbe, la bouche reste transparente : celle du visage apparaît sous la moustache. Le modèle redessine souvent la tête plus grande ou décalée : chaque barbe est recalée sur le visage redessiné (yeux, nez, bouche, `face_align` de `layers.py`, sauf le gnome, recalé sur le corps), pour que la moustache tombe sous le nez. Au-dessus du menton, la barbe est coupée au contour de la joue (`jawMargin`). Les vignettes des tenues et des pièces reprennent l'image générée telle quelle (le personnage qui les porte, comme sur SpriteCook) ; une pièce est cadrée sur sa zone (`ICON_SLOT_ROWS` de `build.py`). Les coiffures comblent la bande de crâne nu entre le sommet de la tête et les cheveux (`fill_crown`). Pour les races au visage trop différent de l'humain (nain, gnome, gobelin, minotaure, orc), chaque barbe est générée directement sur le visage masculin de la race (`raw/beard_<race>_NN.png` → `beards/<race>/bNN.png`, liste `RACE_BEARDS` de `build.py`) et posée telle quelle ; les autres races reçoivent la barbe humaine adaptée à leur mâchoire.
- **Placement sur la tête** (repères de `tool/sprites/heads.json`) : crâne (bords mesurés sur le front), ligne des sourcils, menton (`necks` quand la ligne la plus étroite tombe sur la bouche) et demi-largeur de la tête à chaque ligne (`profile` dans `sprites.json`). La coiffure va du sommet aux sourcils de la race (la frange s'arrête au-dessus des yeux) et épouse la largeur du crâne ligne par ligne ; sous les sourcils, elle garde la largeur du front (pas de marche aux joues) ; la barbe garde sa forme : une seule échelle (largeur moyenne de la mâchoire, oreilles exclues pour le gobelin via `PROFILE_LIMIT`), la même à la verticale, calée sur le menton. Aucune mèche n'est dessinée sur le centre du visage (yeux, nez, bouche : `faceInner`) entre sourcils et cou ; les mèches qui tombent sur les joues restent entières ; les cornes (démon, minotaure) passent devant la coiffure.
- **Peau** : marquée dans chaque corps (alpha 254) et recolorée dans la teinte choisie (palettes par race). Détection : couleurs plus proches du visage que des habits de base, reliées au visage ; sous la poitrine, seulement les bras et les mains au bord de la silhouette. Quand la couleur ne suffit pas (pantalon plus large que les mains de l'orque, fourrure du minotaure couleur pantalon), les avant-bras sont relevés à la main (`arms` dans `heads.json`).
- **Tenues** : 33, générées sur 5 gabarits (homme moyen, femme moyenne, grand, trapu, petit). Chaque corps reçoit le gabarit qui le déforme le moins ; la tenue remplace tout le corps sous le cou. Sa peau nue (cou, mains, avant-bras) est marquée par l'alpha 254 et prend la teinte du héros, si bien que le cou se raccorde à la tête et que l'arme suit la main de la tenue.
- **Pièces séparées** : 20 (`tool/sprites/pieces.json`), générées sur les 5 gabarits en ne changeant qu'une pièce du corps de base (« Only change the shirt… »). `piece_layer` les découpe par différence avec le corps de base, dans la bande de lignes de la pièce : le bas reprend tout le pantalon de base, les chaussures ne gardent que ce qui touche le sol, les gants seulement ce qui a changé autour des mains. Elles se dessinent dans l'ordre bas, chaussures, haut, gants ; une tenue complète retire le haut et le bas, les chaussures et les gants se portent avec tout.
- **Armes** : 12, dessinées à la verticale, tenues à la main (point de prise par famille d'armes).
- **Construction** : `python3 tool/sprites/build.py` produit `assets/sprites/` (calques, vignettes de la boutique et repères `sprites.json`) ; `python3 tool/sprites/preview.py sortie.png` assemble des héros au hasard avec la même logique que l'appli (`SpriteComposer`).

### Ajouter un élément
- **Tenue et menton** : chaque corps a un repère `chin` (bas réel de la mâchoire). Une tenue remplace le corps sous ce menton ; la peau du cou du personnage reste sur une petite bande (`neckBandRatio`) et la peau du visage est redessinée par-dessus les cols.
- **Armes** : le point de la main est le creux du poing (`hand` dans `sprites.json`) ; tout le poing est redessiné devant la poignée ; au repos, le pommeau dépasse juste au-dessus du poing (`pommelAbove`) ; les armes courtes (épées, dagues, cimeterres, haches, masses, marteaux, baguettes : `loweredWeapons`) sont tenues au repos, lame vers le bas ; les armes d'hast, bâtons, arcs et le mousquet restent debout.
- **Pièce séparée** : la peau que l'édition dévoile (bras nus, col ouvert) reste transparente : le corps de base et sa chemise apparaissent dessous.
- **Barbe d'une race** : éditer le corps masculin de la race avec le même texte que la barbe humaine, enregistrer `raw/beard_<race>_NN.png`, ajouter la race à `RACE_BEARDS`, déclarer `assets/sprites/beards/<race>/` dans `pubspec.yaml` (un test le vérifie), relancer `build.py`.
- **Coiffure ou barbe** : éditer l'humain chauve (`human_male` ou `human_female`, voir le manifeste) avec « Only add hair … dyed a vivid saturated magenta pink color », enregistrer l'image dans `raw/hair_mNN.png`, `raw/hair_fNN.png` ou `raw/beard_NN.png`, relancer `build.py`.
- **Pièce séparée** : ajouter sa description dans `tool/sprites/pieces.json`, l'éditer sur les 5 gabarits (`raw/piece_<id>_<gabarit>.png`), relancer `build.py`, puis l'ajouter à `pieceCatalog` et aux textes.
- **Tenue** : ajouter sa description dans `tool/sprites/outfits.json`, l'éditer sur les 5 gabarits (`raw/armor_<id>_<gabarit>.png`), relancer `build.py`, puis l'ajouter au catalogue (`equipment.dart`) et aux textes.
- **Race** : éditer l'humain chauve dans la même pose, puis relever dans `heads.json` son crâne (sommet), ses sourcils et, si besoin, son menton et ses avant-bras ; vérifier la peau en la teignant en bleu avec `preview.py`.

### Limites connues
- Pas de couleur des yeux ni de maquillage : sur des yeux de 2 à 3 pixels, la recoloration n'est ni fiable sur toutes les races ni visible.
- Une coiffure longue posée sur un petit corps (gnome, gobelin) descend plus bas, à l'échelle de sa tête.
- Sur le minotaure, la coiffure se pose entre les cornes, sur un front plat : les coiffures volumineuses y paraissent plus massives.
- Le style de chaque tenue varie légèrement d'un gabarit à l'autre (générée séparément sur chaque corps).

## 3. Équipement de la boutique

38 tenues complètes (dont 5 sombres), 20 pièces séparées (5 hauts, 5 bas, 5 paires de chaussures, 5 paires de gants : `pieceCatalog`) et 20 armes, dont arcs, mousquet, lance, baguette et faux (`outfitCatalog`, `weaponCatalog`), plus 6 récompenses de boss qui reprennent une tenue avec leur propre teinte. Les anciennes pièces 3D possédées sont converties à la relecture (`legacyItemIds`) : chaque pièce d'un ensemble devient la tenue complète, les armes retirées deviennent l'arme la plus proche.

## 5. Musiques et jingles

### État actuel
Créations de la propriétaire du projet, générées avec Suno sous abonnement payant (usage commercial autorisé) le 06/11/2026, puis normalisées en volume et compressées (MP3 112 kbit/s, fondu de fin pour la boucle) :
- `assets/music/title.mp3` (« Kingdoms of Aethelgard ») : écran titre et questionnaire ;
- `assets/music/system.mp3` (« Ascension of the Hero ») : Fenêtre du Système et écrans de jeu ;
- `assets/music/shop.mp3` (« Merchant's Warmth ») : boutique et inventaire ;
- `assets/sounds/level_up.mp3` (« Level Up! ») : jingle de passage de niveau, la musique s'efface dessous.

Musiques des univers (mêmes origine et droits, même compression ; noms des fichiers envoyés par la propriétaire) :
- `assets/music/arcane/` (Magie) : `title.mp3` (« Ouverture Magie »), `system.mp3` (« Stats Magie »), `shop.mp3` (« Boutique Magie »), `level_up.mp3` (« Level Up Magie ») ;
- `assets/music/north/` (Viking) : `system.mp3` (« Stats Viking »).
Une piste absente d'un univers reprend celle du Médiéval (`MusicVariant`, `world_style.dart`). Pour en ajouter une : la déposer sous le même nom dans le dossier de l'univers et l'ajouter à `musicVariantOf`.

Polices des univers (SIL Open Font License, fichier `OFL.txt` à côté de chacune, tirées de google/fonts) : Metamorphous (Magie), Uncial Antiqua (Viking), Pirata One (Pirate).

Les bips du lecteur de séance (`countdown`, `start`, `rest`, `finish`) restent générés par `tool/sounds.py`. Pas de musique pendant une séance. La musique se mélange aux autres sons du téléphone, respecte le mode silencieux et se règle dans Paramètres → Musique.

## 6. Auras et Ombres (phase 9)

### État actuel
- **Auras** : halo flou derrière le héros, dans la couleur de l'aura (`gameConfig.achievements.auras`).
- **Ombres** : silhouettes du héros, teintées et translucides, en retrait de chaque côté (jusqu'à sept).
