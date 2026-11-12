# ASSETS.md — Cahier des charges de l'artiste 3D

> Tout ce qu'un artiste devra fournir pour remplacer les éléments de substitution. **Uniquement des créations originales ou sous licence compatible avec une publication commerciale sur les stores** : aucun asset de Solo Leveling, de World of Warcraft, de Wowhead ni de toute autre œuvre protégée. La partie « création du personnage » est décrite au §2 (phase 6A) et sera complétée en phase 6B.

## 1. Animations des exercices (phase 2)

### État actuel
Démonstration par un **mannequin 2D animé** (12/11/2026, à la demande de la propriétaire du projet : les photos et les vidéos 3D étaient moins lisibles). Mannequin articulé dessiné par le code (`FigureAnimation`), muscles travaillés colorés, poses extrêmes en transparence, accessoires simples (barre, banc, box, mur).

- 75 mouvements dans `assets/animations/motions.json`, générés par `tool/motions.py` : chaque exercice du catalogue a le sien ou partage celui d'une variante identique vue de profil (pompes larges ou diamant, chin-up, curl marteau, fente arrière).
- Appuis vérifiés image par image (planche de contrôle et test : mains et pieds ne traversent pas le sol, prises fixes par cinématique inverse).
- Les photos (free-exercise-db) et les vidéos de capture de mouvement ont été retirées ; les clips 3D `ex_<mouvement>` restent dans les modèles et le visualiseur, inutilisés par les écrans.

### Livrable attendu (version 3D)
- **Un modèle anatomique** homme et un modèle femme, « écorché » ou semi-réaliste, avec **un maillage séparé par muscle** pour les 33 muscles de docs/ANATOMY.md §1. Chaque maillage est nommé exactement comme l'identifiant (`pectoralis_upper`, `gluteus_medius`…), y compris les côtés gauche et droit (`_l` / `_r`).
- **Squelette humanoïde** compatible Mixamo (nommage standard), avec les doigts.
- **Une animation en boucle par mouvement** listé dans `motions.json` (`squat`, `push_up`, `pull_up`…), 1 à 4 secondes, qui démarre et finit sur la même pose. Animations Mixamo autorisées : elles doivent être **intégrées dans le modèle**, jamais livrées comme fichiers séparés réutilisables.
- **Format** : glTF binaire (`.glb`), un fichier par sexe, animations nommées comme les mouvements.
- **Budget mobile** : 25 000 triangles maximum par modèle, une texture 2048 × 2048 au plus, matériaux PBR simples. La couleur des muscles est appliquée par le code (vert vif / vert clair) : prévoir un matériau neutre par muscle.
- **Licence** : fournir la licence de chaque source (modèle de base, animations), compatible avec une application gratuite ou payante publiée sur Google Play et l'App Store, **sans obligation de partage à l'identique** (pas de CC BY-SA ni de NC).

### Intégration côté code
Une nouvelle implémentation de `ExerciseAnimationPlayer` lira le `.glb`, jouera l'animation dont le nom vaut `exercise.motion` et colorera les maillages des muscles de l'exercice. Aucun écran n'a besoin d'être modifié.

## 2. Personnage (phases 6A et 6B)

### État actuel
Six modèles de substitution générés par `tool/character/build_characters.py` (Blender + extension MPFB, maillage de base MakeHuman, licence CC0) : `assets/models/{human,elf,orc}_{female,male}.glb`. Aucun asset tiers protégé. Chaque fichier contient :
- `body` (matériau `skin`, texture de peau réaliste ramenée à une teinte neutre : la couleur choisie dans l'application est appliquée par-dessus ; peaux MakeHuman `young_caucasian_male` / `young_caucasian_female`, CC0), `tusks` pour les orques ;
- `eye_sclera` (texture) et `eye_iris` (matériau `iris`, teinté par la couleur des yeux) — yeux MakeHuman « high-poly » (CC0) ;
- `lashes` (cils MakeHuman `eyelashes01`, CC0) ;
- tenue de départ en vraies pièces de vêtement, texturées, ajustées sur chaque morphologie : `outfit_tunic` (blouse lacée « Lace up blouse » de punkduck, **CC BY**, teinte lin), `outfit_pants` et `outfit_boots` (pantalon et bottes « viking » de RehmanPolanski, CC0) ; `outfit_under_top` et `outfit_under_pants` : maillot et collant sombres tirés de la peau, affichés seulement quand un objet de la boutique remplace la blouse ou le pantalon ;
- `hair_01` à `hair_10` (une seule visible, matériaux `hair_01`…`hair_10`, texture en niveaux de gris teintée par la couleur des cheveux) : Grump hair (Elvaerwyn, **CC BY**), ponytail01 (CC0), Unkempt french braid (Elvaerwyn, CC0), Braid bun (Elvaerwyn, **CC BY**), Alpha 7 long (punkduck, **CC BY**), culturalibre_hair_02 (CC0), short02 (CC0), Double braid (Elvaerwyn, CC0), Wavy bob (Elvaerwyn, **CC BY**), Alpha 7 curly (punkduck, **CC BY**) ;
- `brow_01` à `brow_06` (sourcils MakeHuman eyebrow006, 001, 002, 004, 012, 009, CC0, teintés comme les cheveux) ;
- `beard_01` à `beard_06` (hommes, barbes en mèches, matériaux `beard_01`…`beard_06` teintés par la couleur de la barbe) : Full beard (grinsegold, **CC BY**), Faun beard (culturalibre, CC0), Viking moustache (RehmanPolanski, CC0), Scruffy beard 1 (Elvaerwyn, **CC BY**), Viking beard (RehmanPolanski, CC0), Dal moustache (culturalibre, **CC BY**) ;
- `makeup_01` à `makeup_04` : pellicule du visage peinte en couleurs de sommets avec transparence (khôl, lèvres, joues, peinture de guerre) ;
- formes (morph targets) : `corp_low`, `corp_high`, `musc_low`, `musc_high`, et pour le visage `face_jaw_*`, `face_nose_*`, `face_mouth_*`, `face_cheeks_*`, `face_ears_*` (`_low` / `_high`). La musculature ne change pas le volume d'ensemble (SPEC §29.1) ;
- un squelette (os `Root`, `pelvis`, `spine_01`–`03`, `clavicle`, `upperarm`, `lowerarm`, `hand`, doigts, `neck_01`, `head`, `thigh`, `calf`, `foot`, `ball`, suffixes `_l` / `_r`) et trois animations : `pose_a` (référence), `pose_relaxed` (pose affichée : bras le long du corps, coudes et doigts fléchis, poids sur la jambe gauche, tête légèrement inclinée ; SPEC §32), `breath` (respiration, additive).

Toutes les ressources MakeHuman viennent des paquets officiels de makehumancommunity.org (pages des paquets : « makehuman_system_assets », « hair01 », « hair02 », « hair03 », « bodyparts05 », « bodyparts06 », « shirts02 », « suits02 »). Les ressources **CC BY** (licence Creative Commons Attribution) sont citées dans l'écran Paramètres → Crédits, avec leur auteur et leur page d'origine.

Fabrication : `ARISE_MH_ASSETS=<dossier où les paquets MakeHuman sont décompressés (sous-dossiers clothes, hair, eyebrows, eyelashes, eyes, skins…)> python3 tool/character/build_characters.py <sortie>` puis `tool/character/compress_models.sh <sortie> assets/models` (textures WebP, géométrie meshopt ; 4 à 5,2 Mo par modèle). Les vignettes de la boutique viennent de `tool/character/render_items.py assets/items`.

### Livrable attendu (version définitive)
- **Six personnages** (3 races × 2 sexes) de style fantasy héroïque semi-réaliste, homme et femme sur des **maillages distincts**, conformes à SPEC §3.1.
- **Mêmes noms d'objets, de matériaux, de formes, d'os et d'animations** que ci-dessus, pour que le code fonctionne sans modification. Les textures des cheveux, sourcils et iris restent en niveaux de gris (teinte appliquée par l'application).
- **Règle des équipements** : toute pièce de tenue, armure ou coiffure livrée pour la boutique doit porter les **quatre mêmes formes** (`corp_low`, `corp_high`, `musc_low`, `musc_high`), calculées sur le corps de la même race et du même sexe, pour suivre les proportions sans traverser le corps. Un exemplaire par race et par sexe.
- **Squelette humanoïde** aux noms ci-dessus, doigts compris, avec la pose détendue, la pose de référence en A et la boucle de respiration.
- **Équipements de la boutique** (phase 7) : chaque pièce est liée au même squelette (poids de peau) **et** porte les formes du corps, pour suivre à la fois la pose et la morphologie.
- **Budget mobile** : 25 000 triangles au plus pour le corps, 8 000 par pièce d'équipement, textures 2048 × 2048 au plus.
- **Licence** : créations originales ou licences compatibles avec une publication commerciale ; pour les achats sur Fab, licence standard ou professionnelle uniquement (pas « Reference Only » ni l'ancienne licence Marketplace), avec la source et la licence de chaque asset notées ici.

## 3. Équipement de la boutique (phase 7, refait le 11/11/2026)

### État actuel
Pièces générées par la fonction `_equipment` de `tool/character/build_characters.py`, incluses dans chacun des six modèles (variables `ARISE_MH_ASSETS` pour les paquets MakeHuman et `ARISE_PBR` pour les matières ambientCG décompressées).
- **Vraies pièces MakeHuman** ajustées sur chaque morphologie (mêmes formes que le corps, poids de peau transférés) : `item_leather_chest` (Male boho top 1, Elvaerwyn, **CC BY**), `item_leather_legs` (Wool pants, Margaret Toigo, CC0), `item_leather_hands`, `item_mail_hands`, `item_plate_hands` (gants courts, moyens et longs, Margaret Toigo, CC0), `item_leather_feet` (Medieval boots, punkduck, **CC BY**), `item_mail_chest` (Viking tunic, RehmanPolanski, CC0), `item_mail_feet` (Tight leather boots, madmanny, **CC BY**), `item_plate_head` (Templar knight helmet, javherre, CC0, lié à l'os `head`), `item_plate_feet` (Hero boots 4, culturalibre, CC0), `item_hood_twilight` (Monk robe hood, Donitz, CC0). Gants et bottes sont légèrement gonflés pour que le corps ne les traverse pas.
- **Pièces tirées du corps**, lissées pour perdre le relief du corps (plaques forgées) : `item_mail_head`, `item_mail_legs`, `item_plate_shoulders`, `item_plate_chest`, `item_plate_belt`, `item_plate_legs` ; ceinture `item_leather_belt` ; capes `item_cape_wanderer`, `item_cape_dawn` (nappes recalculées pour chaque morphologie, avec UV).
- **Armes rigides** liées à l'os `hand_r` : `item_sword_dawn`, `item_staff_ember` (orbe lumineux).
- **Matières** (ambientCG, CC0) : cuir Leather037, maille Chainmail004, acier Metal009, or Metal048A, tissu Fabric061 ; texture répétée en niveaux de gris × couleur de la pièce, relief (normal map) et rugosité pour les métaux. Matériaux `dye_<id>` pour les objets teignables (la couleur de base sert quand aucune teinture n'est choisie).
- Limites connues : la coiffe de maille et les jambières restent tirées du corps ; les capes ne flottent pas.

### Livrable attendu
- Chaque objet en version définitive, **un exemplaire par race et par sexe**, sous le même nom `item_<id>`, lié au même squelette (poids de peau) et portant les formes `corp_low`, `corp_high`, `musc_low`, `musc_high` (plus `face_*` pour les coiffes), afin de suivre la pose et la morphologie sans traverser le corps.
- Objets teignables : un matériau `dye_<id>` dont la couleur de base est multipliée par la teinte choisie (texture en niveaux de gris conseillée).
- Budget : 8 000 triangles par pièce, textures 1024 × 1024 (2048 pour les capes et les plastrons), même licence que le §2.


## 4. Récompenses des boss (phase 8A)

### État actuel
Les six objets exclusifs réutilisent une pièce de la boutique avec leur propre teinte (`baseId` et `tint` dans `lib/features/inventory/domain/equipment.dart`) : `guardian_jacket` (veste de cuir), `stag_cape` (cape du Vagabond), `wind_hood` et `tempest_hood` (capuche du Crépuscule), `colossus_leggings` (chausses de cuir), `comet_cape` (cape de l'Aube). Aucune pièce 3D supplémentaire n'est incluse dans les modèles.

### Livrable attendu
- Une pièce propre par objet, nommée `item_<id>` (par exemple `item_guardian_jacket`), avec les mêmes exigences que le §3 (squelette, formes de morphologie, matériau `dye_<id>`, budget). Il suffira alors de retirer `baseId` de l'objet dans le catalogue.
- Une vignette `assets/items/<id>.png` par objet (rendu de l'objet seul, comme pour la boutique).
- Une courte cinématique de victoire par boss (silhouette du boss, effet de lumière), en remplacement de la fenêtre animée du bilan.

## 5. Musiques et jingles

### État actuel
Créations de la propriétaire du projet, générées avec Suno sous abonnement payant (usage commercial autorisé) le 06/11/2026, puis normalisées en volume et compressées (MP3 112 kbit/s, fondu de fin pour la boucle) :
- `assets/music/title.mp3` (« Kingdoms of Aethelgard ») : écran titre et questionnaire ;
- `assets/music/system.mp3` (« Ascension of the Hero ») : Fenêtre du Système et écrans de jeu ;
- `assets/music/shop.mp3` (« Merchant's Warmth ») : boutique et inventaire ;
- `assets/sounds/level_up.mp3` (« Level Up! ») : jingle de passage de niveau, la musique s'efface dessous.

Les bips du lecteur de séance (`countdown`, `start`, `rest`, `finish`) restent générés par `tool/sounds.py`. Pas de musique pendant une séance. La musique se mélange aux autres sons du téléphone, respecte le mode silencieux et se règle dans Paramètres → Musique.

## 6. Auras et Ombres (phase 9)

### État actuel
- **Auras** : générées par le visualiseur (`tool/viewer/viewer.js`) : anneau lumineux au sol, halo et particules qui montent, dans la couleur de l'aura (`gameConfig.achievements.auras`).
- **Ombres** : copies du personnage du joueur, au corps presque noir, teintées et translucides, placées derrière lui (jusqu'à sept).

### Livrable possible (artiste)
- Effets d'aura plus riches (flammes, givre, feuilles, éclairs) : textures de particules en PNG 256 × 256 (fond transparent, licence CC0 ou CC BY), une par aura.
- Effet d'« éveil » d'une Ombre (fumée qui se lève) : courte texture animée en planche de 4 × 4 images.
