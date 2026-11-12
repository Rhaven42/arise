# Tutoriel — Créer un personnage et des équipements sur Tripo pour Hero Protocol

Ce guide explique comment fabriquer, sur **Tripo Studio** (studio.tripo3d.ai), des modèles 3D que j'intègre ensuite dans l'application. Tu génères, tu télécharges, tu déposes dans le dossier Google Drive partagé : je m'occupe du reste (allègement, ajustement sur le personnage, vignettes de la boutique, crédits).

---

## 0. Les règles d'or (à lire une fois)

1. **Tout doit être original.** Ne demande jamais un objet ou un personnage d'un jeu, d'un film ou d'une série (« Legolas », « casque de World of Warcraft », « baguette de Harry Potter »…). Décris plutôt le style : « elfe des bois », « heaume de chevalier doré ».
2. **Un seul objet par génération.** Jamais un personnage qui porte l'objet : seulement l'objet, seul, au centre.
3. **Écris les descriptions en anglais**, Tripo comprend mieux. Les modèles ci-dessous sont prêts à copier-coller.
4. **Termine toujours par** : `realistic, game asset, single object, PBR textures`.
5. Ton abonnement **Pro** t'autorise à utiliser les modèles dans l'application.

---

## 1. Trouver « Texte vers 3D »

1. Ouvre **studio.tripo3d.ai** et connecte-toi.
2. En haut, clique sur **« Espace de travail 3D »** (le bouton avec la petite flèche ▾).
3. Choisis l'outil de **génération** (« Générer », « Génération 3D » ou « Create » selon la version).
4. Sélectionne l'onglet **« Texte »** (ou « Text to 3D »).
5. Colle ta description, puis clique sur **Générer**.
6. Tripo propose souvent **plusieurs essais** : garde le plus propre (formes nettes, pas de morceaux qui flottent, symétrique).

> Si un résultat est décevant, relance la même description : chaque génération est différente.

---

## 2. Partie A — Créer un personnage (exemple : une elfe)

### À savoir avant de commencer
Les personnages actuels de l'application (Humain, Elfe, Orque) sont construits avec MakeHuman : on peut régler leur corps, leur visage et leur coiffure avec des curseurs, et les vêtements s'ajustent tout seuls.
Un personnage Tripo, lui, est **figé** : il garde le corps et les vêtements de la génération. Il convient donc surtout à une **nouvelle race spéciale** (sans curseurs) ou à un **personnage non joueur** (marchand de la boutique, maître d'épreuve, boss).

### Étape 1 — La description
Copie et adapte :

```
full body female wood elf, standing in T-pose, arms straight out to the sides, feet slightly apart, neutral face, long pointed ears, long braided silver hair tied back, fitted green and brown leather ranger outfit, no weapon, no cape, no bag, realistic proportions, realistic, game character, PBR textures
```

Pour un elfe homme, remplace `female` par `male`. Pour une autre race, change `wood elf` par `dwarf`, `half-orc`, `horned demon`, etc.

**Points obligatoires**, sinon je ne pourrai pas l'animer :
- **T-pose** : bras tendus à l'horizontale, jambes droites ;
- **rien qui dépasse ou qui pend** : pas d'arme, pas de cape, pas de sac (ils seront des équipements à part) ;
- cheveux **attachés** et visage dégagé.

### Étape 2 — Vérifier le résultat
Tourne le modèle à la souris et vérifie :
- les **mains** ont bien cinq doigts séparés ;
- le corps est **symétrique** ;
- les **pieds** sont à plat.

### Étape 3 — Le squelette (« Rig »)
1. Sur ton modèle, cherche le bouton **« Rig »** / **« Animer »** / **« Auto-rig »**.
2. Choisis **« Humanoïde »** (ou « Biped »).
3. Ne choisis pas d'animation : je mets moi-même celles de l'application (marche, respiration, poses).

### Étape 4 — Télécharger
Bouton **Télécharger / Export** :
- format : **GLB** ;
- textures : **2K** ;
- si l'option existe : **« avec squelette »** (with rig / with skeleton).

Nomme le fichier clairement, par exemple `perso_elfe_rangeuse.glb`.

---

## 3. Partie B — Créer des équipements

### Comment décrire chaque type d'objet

| Type | Ce qu'il faut préciser | Exemple |
|---|---|---|
| **Casque** | `empty helmet, no head inside` | casque vide, ouverture du cou visible |
| **Plastron** | `breastplate only, no body inside, no arms` | uniquement la pièce rigide |
| **Épaulière** | `single left pauldron` | **une seule** : je fais la deuxième en miroir |
| **Gantelet** | `single right gauntlet, empty` | un seul gant |
| **Botte** | `single right armored boot, empty` | une seule botte |
| **Arme** | `full length, straight, side view` | arme entière, droite |
| **Bouclier** | `front view, flat back with handle` | vu de face |
| **Compagnon** | `standing pose, four legs on the ground` | l'animal seul, posture neutre |

> Les **vêtements souples** (robes, capes, tuniques) se font mieux de mon côté avec MakeHuman : ils doivent épouser le corps et bouger avec lui. Concentre-toi sur les **pièces rigides**, les **armes**, les **boucliers** et les **compagnons**.

### Descriptions prêtes à copier

**Chevalier**
```
medieval knight great helm, polished steel with gold trim and rivets, empty helmet, no head inside, realistic, game asset, single object, PBR textures
```
```
ornate steel breastplate with engraved gold lion crest, breastplate only, no body inside, realistic, game asset, single object, PBR textures
```
```
single left steel pauldron with layered plates and gold edges, realistic, game asset, single object, PBR textures
```
```
kite shield, blue and white heraldic pattern with a gold sun emblem, iron rim, front view, realistic, game asset, single object, PBR textures
```
```
two-handed knight longsword, steel blade, gold crossguard, leather grip, full length, straight, realistic, game asset, single object, PBR textures
```

**Mage**
```
tall wizard staff made of twisted dark wood with a glowing blue crystal at the top, full length, straight, realistic, game asset, single object, PBR textures
```
```
pointed wizard hat, deep purple velvet with silver star embroidery, empty hat, realistic, game asset, single object, PBR textures
```
```
ancient leather spellbook with brass corners and a glowing rune on the cover, closed, realistic, game asset, single object, PBR textures
```

**Ranger**
```
elegant elven longbow, pale carved wood with leaf engravings and green leather grip, full length, realistic, game asset, single object, PBR textures
```
```
leather quiver full of arrows with green fletching, realistic, game asset, single object, PBR textures
```

**Viking**
```
viking spangenhelm helmet with nasal guard, riveted iron and bronze, empty helmet, no head inside, realistic, game asset, single object, PBR textures
```
```
viking bearded battle axe, wooden handle wrapped in leather, carved runes on the blade, full length, realistic, game asset, single object, PBR textures
```
```
round wooden viking shield painted with blue and white knotwork, iron boss in the center, front view, realistic, game asset, single object, PBR textures
```

**Pirate**
```
black tricorn hat with gold trim and a red feather, empty hat, realistic, game asset, single object, PBR textures
```
```
pirate cutlass, curved steel blade, brass basket hilt, full length, realistic, game asset, single object, PBR textures
```
```
antique flintlock pistol, dark wood stock with brass details, side view, realistic, game asset, single object, PBR textures
```

**Compagnons**
```
black raven standing on the ground, wings folded, realistic feathers, realistic, game asset, single object, PBR textures
```
```
grey wolf standing, four legs on the ground, neutral pose, realistic fur, realistic, game asset, single object, PBR textures
```

### Variantes de couleur
Pour un même objet en plusieurs versions (fer, doré, noir), utilise sur ton modèle l'outil **« Texture »** / **« Retexture »** de Tripo avec une description courte (`black steel with red details`), puis télécharge chaque version.

### Télécharger
- format **GLB**, textures **2K** ;
- un nom de fichier clair : `casque_chevalier_dore.glb`, `bouclier_viking_bleu.glb`.

---

## 4. M'envoyer les modèles

1. Dépose les fichiers dans **le dossier Google Drive déjà partagé** (même lien que d'habitude).
2. Écris-moi ici : « J'ai ajouté X modèles ».

Je récupère tout et, pour chaque modèle :
- je l'**allège** (de 60 Mo à moins d'1 Mo, sans perte visible) ;
- je l'**ajuste sur le personnage** : taille, position, attache à la tête, à la main, au dos ou aux épaules ;
- je fabrique sa **vignette** pour la boutique ;
- je l'ajoute au **catalogue** avec son nom, son prix et sa rareté ;
- je te montre un **aperçu** avant de l'intégrer.

---

## 5. Pense-bête

- [ ] Un seul objet, sans personnage dedans
- [ ] Description en anglais terminée par `realistic, game asset, single object, PBR textures`
- [ ] Rien de copié d'une œuvre existante
- [ ] Personnage : T-pose, rien qui pend, squelette « Humanoïde »
- [ ] Export GLB, textures 2K, nom de fichier clair
- [ ] Déposé dans le dossier Drive partagé
