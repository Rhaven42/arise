# ASSETS.md — Cahier des charges de l'artiste 3D

> Tout ce qu'un artiste devra fournir pour remplacer les éléments de substitution. **Uniquement des créations originales ou sous licence compatible avec une publication commerciale sur les stores** : aucun asset de Solo Leveling, de World of Warcraft, de Wowhead ni de toute autre œuvre protégée. La partie « création du personnage » est décrite au §2 (phase 6A) et sera complétée en phase 6B.

## 1. Animations des exercices (phase 2)

### État actuel
Mannequin 2D original dessiné par le code (`lib/features/exercises/presentation/animation/`), à partir des poses de `assets/animations/motions.json` (24 mouvements). Les silhouettes face/dos (`assets/svg/body_front.svg`, `body_back.svg`) portent une zone par muscle, identifiée par l'id du référentiel.

### Livrable attendu (version 3D)
- **Un modèle anatomique** homme et un modèle femme, « écorché » ou semi-réaliste, avec **un maillage séparé par muscle** pour les 33 muscles de docs/ANATOMY.md §1. Chaque maillage est nommé exactement comme l'identifiant (`pectoralis_upper`, `gluteus_medius`…), y compris les côtés gauche et droit (`_l` / `_r`).
- **Squelette humanoïde** compatible Mixamo (nommage standard), avec les doigts.
- **Une animation en boucle par mouvement** listé dans `motions.json` (`squat`, `push_up`, `pull_up`…), 1 à 4 secondes, qui démarre et finit sur la même pose. Animations Mixamo autorisées : elles doivent être **intégrées dans le modèle**, jamais livrées comme fichiers séparés réutilisables.
- **Format** : glTF binaire (`.glb`), un fichier par sexe, animations nommées comme les mouvements.
- **Budget mobile** : 25 000 triangles maximum par modèle, une texture 2048 × 2048 au plus, matériaux PBR simples. La couleur des muscles est appliquée par le code (vert vif / vert clair) : prévoir un matériau neutre par muscle.
- **Licence** : fournir la licence de chaque source (modèle de base, animations), compatible avec une application gratuite ou payante publiée sur Google Play et l'App Store, **sans obligation de partage à l'identique** (pas de CC BY-SA ni de NC).

### Intégration côté code
Une nouvelle implémentation de `ExerciseAnimationPlayer` lira le `.glb`, jouera l'animation dont le nom vaut `exercise.motion` et colorera les maillages des muscles de l'exercice. Aucun écran n'a besoin d'être modifié.

## 2. Personnage (phase 6A)

### État actuel
Six modèles de substitution originaux, générés par `tool/character/build_characters.py` dans Blender avec l'extension MPFB (maillage de base MakeHuman, licence CC0) : `assets/models/{human,elf,orc}_{female,male}.glb`. Aucun asset tiers protégé. Chaque fichier contient :
- `body` (matériau `skin`), `eyes`, et `tusks` pour les orques ;
- `outfit_tunic`, `outfit_tunic_skirt`, `outfit_pants`, `outfit_boots`, `outfit_belt` (tenue de départ) ;
- `hair_01` à `hair_10` (une seule visible à la fois, matériau `hair`) ;
- quatre formes (morph targets) sur tous ces maillages : `corp_low`, `corp_high`, `musc_low`, `musc_high`.

Le code colore `skin` et `hair`, choisit la coiffure par son nom, règle les formes et l'échelle (taille). Environ 1,8 Mo par modèle.

### Livrable attendu (version définitive)
- **Six personnages** (3 races × 2 sexes) de style fantasy héroïque semi-réaliste, homme et femme sur des **maillages distincts**, conformes à SPEC §3.1.
- **Mêmes noms d'objets, de matériaux et de formes** que ci-dessus, pour que le code fonctionne sans modification. D'autres formes pourront s'ajouter en phase 6B (visage, morphotype, posture).
- **Règle des équipements** : toute pièce de tenue, armure ou coiffure livrée pour la boutique doit porter les **quatre mêmes formes** (`corp_low`, `corp_high`, `musc_low`, `musc_high`), calculées sur le corps de la même race et du même sexe, pour suivre les proportions sans traverser le corps. Un exemplaire par race et par sexe.
- **Squelette humanoïde** compatible Mixamo, doigts compris (poses de l'éditeur en phase 6B).
- **Budget mobile** : 25 000 triangles au plus pour le corps, 8 000 par pièce d'équipement, textures 2048 × 2048 au plus.
- **Licence** : créations originales ou licences compatibles avec une publication commerciale ; pour les achats sur Fab, licence standard ou professionnelle uniquement (pas « Reference Only » ni l'ancienne licence Marketplace), avec la source et la licence de chaque asset notées ici.

