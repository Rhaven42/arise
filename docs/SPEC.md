# SPEC.md — Spécification fonctionnelle ARISE

> Référence fonctionnelle complète. En cas de conflit : CLAUDE.md (règles) > ANATOMY.md (anatomie) > SPEC.md. Les valeurs numériques citées ici sont reportées dans les fichiers de configuration de jeu (client + serveur) et ne sont écrites nulle part ailleurs dans le code.
>
> Les points marqués **[À PRÉCISER]** sont tranchés par les décisions de la section 20, qui font foi.
>
> ⚠️ **Depuis le 04/11/2026, l'application est 100 % hors ligne (§21).** Partout où ce document parle de « serveur », de Cloud Functions, de Firestore ou de connexion Google, lire : logique du domaine et base locale Drift sur le téléphone. Le coach caméra est retiré du MVP.

## 1. Vision et univers
- Application de sport gamifiée : sport réel → expérience → niveaux → rangs → évolution d'un avatar 3D personnalisable.
- Royaume original **d'Arisia**. Ambiance MMORPG fantasy héroïque : cadres de pierre et de bois, éclairage chaud, polices médiévales, fenêtres de « Système » qui annoncent quêtes et récompenses.
- Aucun nom, logo ni asset protégé (Solo Leveling, World of Warcraft…).
- Interface en français.

## 2. Onboarding
1. **Écran titre** dans une taverne fantasy.
2. ~~Connexion Google~~ — retirée (§21) : aucun compte, le profil est créé sur le téléphone.
3. **Questionnaire** :
   - objectif : force, perte de poids, endurance, souplesse, forme générale ;
   - niveau (débutant, intermédiaire, avancé — libellés à valider) ;
   - équipement disponible ;
   - **1 à 3 jours de repos par semaine**, choisis librement ;
   - consentement santé (révocable dans les paramètres) et rappel de prudence (douleur, fatigue extrême).
4. **Création du personnage** (§3).
5. **Tutoriel « l'Éveil »** : première quête simple de **10 squats** qui fait passer au **niveau 1**.

## 3. Création du personnage
### 3.1 Sexe et maillages
- Homme / femme : **deux maillages totalement distincts**, chacun avec sa propre topologie, un squelette humanoïde complet avec les doigts et ses blend shapes.
- Homme : épaules larges, silhouette en V, hanches étroites, cou épais, mâchoire carrée, pomme d'Adam, mains et pieds plus grands.
- Femme : épaules plus étroites, taille marquée, bassin large, cou plus fin, traits plus doux, curseur de poitrine avec physique douce.
- Proportions : homme 7,5 à 8 têtes ; femme 7 à 7,5 têtes. Style fantasy héroïque semi-réaliste, sans caricature.

### 3.2 Morphologie (curseurs indépendants, propres à chaque sexe)
- Masse musculaire : Filiforme → Svelte → Athlétique → Musclé → Colosse.
- Masse grasse : Sec → Normal → Enveloppé → Rondouillard → Massif. Répartition : ventre chez l'homme, hanches et cuisses chez la femme.
- Taille : 1,50 à 2,05 m. Longueurs : torse, bras, jambes. Largeurs : épaules, cage thoracique, taille, hanches.
- Morphotype : mélange ectomorphe / mésomorphe / endomorphe.
- Posture : neutre, droite, voûtée, bombée.
- **12 préréglages par sexe** : Frêle, Svelte, Athlétique, Nageur, Sprinteur, Musclé, Culturiste, Colosse, Rondouillard, Costaud, Massif + Sablier (femme) / En V (homme).
- Correctifs aux épaules, coudes et genoux : aucun artefact quelle que soit la combinaison.
- Définition musculaire et veines qui apparaissent / s'estompent selon masse musculaire et masse grasse.

### 3.3 Visage
- Couleur de peau libre (palette + sélecteur), taches de rousseur, cicatrices, tatouages.
- Formes du visage, de la mâchoire, du nez, de la bouche, des oreilles.
- Yeux : couleur libre, forme et écartement réglables.
- 15 styles de sourcils ; 12 styles de barbe (homme) avec couleur indépendante ; 10 styles de maquillage.

### 3.4 Coiffures
- **≥ 60 coiffures par sexe**, par catégories :
  - Courtes : rasé, buzz, dégradé, brosse, undercut, crête, pompadour, en bataille, coupe de soldat, pixie, carré court.
  - Mi-longues : carré plongeant, coupe au menton, coupe aux épaules, coupe d'aventurier.
  - Longues : lisses jusqu'au dos ou à la taille, avec frange, raie au milieu, dégradées.
  - Bouclées / frisées : boucles lâches ou serrées, afro court / moyen / volumineux, frisés longs.
  - Queues de cheval : haute, basse, de côté, avec mèches, de guerrier.
  - Chignons : haut, bas, désordonné, double.
  - Nattes / tresses : dans le dos, sur l'épaule, double natte, natte couronne, tresses collées, tresses africaines, tresse à perles, tresses vikings.
  - Couettes : hautes, basses, tressées, de côté.
  - Héroïques : crinière, cordons, anneaux de métal, mi-rasé tressé, dreadlocks.
- Couleurs : palette de 40 teintes + couleur libre, dégradé deux tons, mèches, brillance, volume, cheveux gris.
- Rendu : cartes de cheveux, reflets anisotropes. Physique des mèches avec collisions tête / nuque / épaules ; aucun cheveu ne traverse corps ou vêtements.
- Chaque coupe a une **variante sous casque**.
- Bouton « assortir barbe et sourcils ». 5 coiffures favorites. Certaines coupes verrouillées, achetables en cristaux.

### 3.5 Équipement de départ et emplacements
- Tenue de départ en tissu usé : tunique, pantalon, bottes, ceinture de corde.
- Emplacements : tête, épaules, torse, mains, ceinture, jambes, pieds, dos, arme cosmétique.
- Tout équipement s'adapte à toutes les morphologies sans clipping.

### 3.6 Scène de l'éditeur
- Rotation 360°, zoom visage / corps.
- 4 poses : en A, héroïque, de combat, détendue ; respiration au repos.
- 3 éclairages : jour, nuit, taverne.
- Capture d'écran, bouton aléatoire, réinitialisation, annuler / rétablir sur **20 actions**, comparaison avant / après.
- Nom : **3 à 16 caractères**, filtre anti-insultes, **unicité vérifiée par le serveur** (réservation de nom).
- Brouillon sauvegardé localement (Drift).

### 3.7 Rendu abstrait
- `CharacterRenderer` : interface indépendante du moteur. MVP : implémentation `.glb`. Implémentation Unity ultérieure.
- En l'absence d'assets définitifs : deux mannequins de substitution distincts. Cahier des charges artiste dans `docs/ASSETS.md`.

## 4. Stats
| Stat | Progresse avec |
|---|---|
| Force | pompes, squats, tractions, dips, haltères, hip thrust, exercices avec charge |
| Endurance | marche, course, vélo, corde à sauter, Tabata, HIIT, burpees, rameur |
| Agilité | étirements, mobilité, yoga, équilibre, coordination (jumping jacks, shadow boxing) |
| Vitalité | gainage et isométrie, sommeil, hydratation, respiration, récupération active |
| Volonté | **uniquement** la régularité (séries de jours, quêtes, objectifs tenus), jamais un exercice |

- Chaque exercice a une stat principale et parfois une secondaire, avec une répartition (ex. burpees : 70 % Endurance / 30 % Force).
- Gains automatiques de stats avec l'entraînement **[À PRÉCISER : taux]**.

## 5. Progression
- XP pour passer du niveau *n* au niveau *n+1* : `round(100 × n^1.5)`.
- XP d'une série : `base_exercice × volume_normalisé × mult_intensité × bonus_série_jours × bonus_classe`.
  - Intensité ressentie 1–10 convertie en multiplicateur 0,8–1,3 **[À PRÉCISER : courbe]**.
  - Volume normalisé **[À PRÉCISER : définition]**.
- Au-delà de **120 minutes d'effort actif dans la journée** : XP divisée par deux + message de prudence.
- À chaque niveau : **3 points de stat** à placer librement + **(5 + niveau atteint) Cristaux de Mana**.

### 5.1 Rangs
| Rang | Niveaux |
|---|---|
| E | 1 – 9 |
| D | 10 – 19 |
| C | 20 – 34 |
| B | 35 – 49 |
| A | 50 – 69 |
| S | 70 – 89 |
| Monarque | ≥ 90 |

- L'XP se **bloque au dernier niveau d'un rang** (9, 19, 34, 49, 69, 89) tant que le boss du rang n'est pas vaincu.

## 6. Classes
- Choix au **rang C**, changement possible **une fois par mois**.
- Bonus de **+15 % d'XP** sur un style : Berserker (Force), Ranger (Endurance), Assassin (Agilité), Tank (Vitalité).
- Nécromancien : **+5 % partout** + bonus sur les Ombres (7 Ombres actives au lieu de 5, bonus des Ombres doublé).

## 7. Séries de jours, repos et pénalités
- Jour validé : au moins **une séance complète** ou la **quête quotidienne terminée**.
- Chaque jour de série : **+5 % d'XP**, maximum **+50 %**.
- Coffres de cristaux à **7, 30, 100 et 365 jours**. La Volonté progresse avec la série.
- **Jours de repos déclarés** : ne cassent jamais la série ; mobilité légère permise.
- **Zone de Pénalité** (jour manqué hors repos) :
  - série remise à zéro, sauf utilisation d'un **Bouclier** (1 gagné toutes les deux semaines, stock max 2) ;
  - malus de **−20 % d'XP pendant 24 h** ;
  - **quête de pénalité** courte et raisonnable ; la réussir annule le malus ;
  - **jamais** de perte de niveau, d'objet ou de cristaux.
- **Mode maladie / blessure** : pause complète jusqu'à **14 jours**, sans pénalité.

## 8. Épreuves (boss) et donjons
- Chaque passage de rang exige de vaincre un **boss** : épreuve physique calibrée sur le niveau.
  - Ex. « Repousser le Rocher du Gardien » : force, minimum de pompes et de squats en temps limité, accessible avec **Force ≥ 40**.
  - Autres épreuves : endurance (marche/course chronométrée), agilité (circuit de mobilité).
- Victoire : nouveau rang, titre, équipement exclusif personnalisable, cinématique.
- Défaite : nouvel essai après **48 h**.
- Caméra obligatoire pendant les épreuves quand l'exercice est compatible.
- **Donjons hebdomadaires** : séances thématiques à enchaîner, butin cosmétique.

## 9. Quêtes
- **Quête quotidienne du Système** : 3 ou 4 objectifs adaptés au niveau et au planning (ex. 30 pompes, 30 squats, 15 min de marche, 5 min d'étirements).
- Quêtes hebdomadaires et quêtes d'événement.
- **Toutes générées par le serveur.**

## 10. Exercices, programmes et planning
### 10.1 Catalogue
- **≥ 80 exercices**. Chaque fiche : nom, description, consignes, erreurs fréquentes, type (répétitions / durée / distance), stats et répartition, muscles principaux et secondaires (référentiel uniquement), équipement, difficulté, animation.
- Animation en boucle sur la fiche ; synchronisée pendant la séance (`ExerciseAnimationPlayer`).

### 10.2 Personnalisation
- Exercices personnalisés : muscles choisis directement sur la silhouette.
- Programmes personnalisés.

### 10.3 Formats de séance
| Format | Paramètres |
|---|---|
| Musculation | séries × répétitions (ex. 4 × 15 pompes), charge optionnelle, repos entre séries |
| Tabata / HIIT / circuit | travail, repos, rounds, cycles, repos entre cycles, liste d'exercices. Défaut : 20 s / 10 s / 8 rounds |
| Cardio | durée ou distance |
| Mobilité | temps de maintien par position |

### 10.4 Planning
- Planning hebdomadaire en **glisser-déposer**, séances récurrentes, jours de repos, rappels (notifications locales + FCM).

### 10.5 Lecteur de séance
- Minuteur visuel et sonore, voix optionnelle, animation, compteur de séries, saisie de l'intensité ressentie.
- Avertissement visible : arrêter en cas de douleur ou fatigue extrême.
- Récapitulatif final : XP gagnée (confirmée par le serveur) et muscles travaillés.
- **Hors ligne** : séance conservée dans Drift puis synchronisée ; le serveur recalcule à la réception.

## 11. Analyse musculaire
- Après chaque exercice : muscles sollicités en **vert vif** (principaux) et **vert clair** (secondaires), sur l'avatar et la silhouette.
- Onglet d'analyse : silhouettes face et dos ; périodes jour / semaine / mois / année ; 5 niveaux (seuils et motifs dans ANATOMY.md §4), configurables ; couleur + motif + libellé.
- Suggestions (ex. « Tes ischio-jambiers sont en retard, essaie le pont fessier ») — uniquement des exercices dont le mapping du référentiel cible le muscle en retard.
- Alertes de déséquilibre poussée / tirage et avant / arrière **[À PRÉCISER : groupes et seuil]**.
- **Agrégats calculés côté serveur.**

## 12. Coach caméra — retiré du MVP (§21)
Conservé ci-dessous à titre d'idée pour une version future.
- Optionnel, uniquement avec consentement.
- Détection de pose sur l'appareil (ML Kit) : comptage des répétitions de pompes, squats, jumping jacks, fentes ; chronométrage de la planche ; vérification de l'amplitude.
- Anti-triche : répétitions validées par caméra = **+10 % d'XP** ; caméra obligatoire pendant les boss si l'exercice est compatible.
- **Aucune image stockée ni envoyée** ; seul le nombre de répétitions validées est transmis.

## 13. Santé
- Lecture seule (jamais d'écriture) : pas, marche, course, vélo, sommeil, fréquence cardiaque.
- Conversion en Endurance ou Vitalité, avec **plafond journalier** **[À PRÉCISER : valeurs]**.
- Sommeil ≥ 7 h : bonus de Vitalité. Hydratation saisie manuellement.
- Synchronisation via une Cloud Function.

## 14. Boutique, inventaire, titres, hauts faits, Ombres
### 14.1 Boutique et inventaire
- Monnaie unique : **Cristal de Mana**, gagné uniquement par le sport. **Aucun achat réel dans le MVP.**
- Catalogue : coiffures, tenues, sets d'armure par rang, capes, auras, armes cosmétiques, poses, décors de profil.
- Raretés : Commun, Rare, Épique, Légendaire, Mythique.
- Teinture des équipements ; essayage sur l'avatar avant achat.
- Achat validé par le serveur.

### 14.2 Hauts faits et titres
- **≥ 60 hauts faits** : régularité, volume, stats, boss, exploration, équilibre musculaire, secrets.
- Titres équipables affichés sous le nom (ex. « L'Éveillé », « Celui qui ne saute jamais les jambes », « Briseur de Rocher », « Monarque de l'Aube »). Certains débloquent une aura.

### 14.3 Ombres
- À partir du **rang B**, vaincre un boss permet d'extraire une **Ombre** : compagnon cosmétique à côté de l'avatar, **+2 % passif** dans une stat.
- Max **5 actives** (7 pour un Nécromancien, bonus doublé).

## 15. Autres écrans
- **Fenêtre du Système** (tableau de bord) : niveau, barre d'XP, stats, série de jours, quête du jour, prochaine séance.
- **Profil** : historique et graphiques.
- **Paramètres** : unités, sons, notifications, caméra, santé ; **export et suppression des données (RGPD)**.
- Classement entre amis : **hors MVP**, prévu plus tard.

## 16. Modèle de données (base locale Drift)
Une seule base SQLite sur le téléphone. Tables prévues (créées au fil des phases, chaque ajout = migration testée) :
| Table | Contenu | Phase |
|---|---|---|
| `player_profiles` | profil du questionnaire (objectif, niveau, équipement, jours de repos, consentement santé) | 1 |
| `local_drafts` | brouillons (questionnaire, personnage) | 0 |
| `pending_sessions` | file de séances (conservée pour un futur export ou une synchronisation) | 0 |
| `characters` | sexe, race, morphologie, apparence, équipement porté | 6 |
| `progression` | niveau, XP, rang, stats, points libres, cristaux, série, boucliers, classe | 4 |
| `sessions`, `session_sets` | séances réalisées ; source : manuelle ou santé | 3 |
| `programs`, `custom_exercises` | programmes et exercices personnalisés | 2 |
| `inventory`, `achievements`, `quests`, `trials`, `shadows` | contenu du jeu débloqué | 7 à 9 |
| `muscle_aggregates` | volume par muscle et par période | 5 |

Les catalogues (exercices, objets, hauts faits, épreuves) sont des fichiers embarqués en lecture seule.

## 17. Règles du jeu (use cases du domaine)
| Use case | Rôle |
|---|---|
| `CompleteSession` | validation, XP, stats, progression, agrégats, hauts faits |
| `RunDailyRollover` | à l'ouverture de l'app, pour chaque jour écoulé : séries, pénalités, boucliers, génération des quêtes |
| `AllocateStatPoints`, `ChooseClass` | répartition des points, choix de classe (rang C, 1×/mois) |
| `StartTrial` / `CompleteTrial` | épreuves de rang |
| `PurchaseItem` | achat en cristaux |
| `SetSickMode` | mode maladie / blessure (≤ 14 jours) |
| `ExportBackup` / `ImportBackup` / `EraseAllData` | sauvegarde et effacement |

## 18. Accessibilité et santé (exigences transverses)
- Polices dynamiques, contrastes suffisants, heatmap daltonien-compatible (motifs + libellés), lecteurs d'écran.
- Aucune mécanique de surentraînement ; repos respecté ; avertissement douleur / fatigue extrême ; plafond 120 min/jour.

## 19. Hors périmètre MVP
- Achats réels, classement entre amis, implémentation Unity du rendu.

## 20. Décisions validées (04/11/2026)
Ces décisions remplacent les anciens points « [À PRÉCISER] ». Toute valeur marquée **provisoire** est rangée dans les fichiers de configuration de jeu avec ce statut et pourra être ajustée sans changer le code.

1. **Catalogue au-delà des 26 exercices de référence** : Claude propose le mapping des 54 exercices restants dans ANATOMY.md avec `reviewStatus: pending_review`. Aucun de ces exercices n'est utilisé dans le code ou les calculs avant validation explicite de la propriétaire du projet.
2. **Formules** :
   - multiplicateur d'intensité linéaire : `0,8 + (intensité − 1) × 0,5 / 9` (1 → 0,8 ; 10 → 1,3) ;
   - tous les bonus et malus se cumulent **par multiplication** (série de jours, classe, caméra +10 %, malus −20 %, Ombres, division par deux au-delà de 120 min) ;
   - « volume normalisé » : définition **provisoire** fixée en phase 4 et soumise à validation avec le plan de la phase.
3. **Niveaux** : départ au **niveau 0** ; le tutoriel de l'Éveil donne exactement **100 XP** (passage au niveau 1). Niveau maximum : **100** (provisoire).
4. **Valeurs non chiffrées** (gain automatique des stats, plafonds santé, calibration des boss, contenu de la quête de pénalité, rythme des boucliers) : fixées **à titre provisoire** dans la configuration de jeu.
5. **Fin de journée** : minuit, heure locale, selon le fuseau IANA du profil. Un changement de fuseau s'applique à partir du jour suivant.
6. **Alertes de déséquilibre** : déclenchées au-delà d'un ratio de **1,5:1** (provisoire). Classement poussée/tirage par exercice, proposé en phase 5 et soumis à validation.
7. **Rendu 3D du MVP** : mannequins distincts homme / femme, blend shapes de base, tous les écrans et toutes les données de personnalisation. La fidélité complète (physique des cheveux, reflets anisotropes, correctifs avancés, physique de la poitrine) est réservée à l'implémentation Unity et documentée dans ASSETS.md.
8. **Polices et sons** : polices Google Fonts sous licence OFL (Cinzel, IM Fell English) incluses dans l'app ; sons libres de droits.
9. **Lint** : `very_good_analysis` (Dart) et ESLint strict (TypeScript).
10. **Environnement** : code hébergé sur un **dépôt GitHub** ; compilation et tests Flutter via **GitHub Actions**.

## 21. Passage en 100 % hors ligne (04/11/2026)
Décision de la propriétaire du projet : pas de forfait Firebase Blaze, pas de serveur, pas de caméra.

1. **Aucun compte ni serveur.** Firebase (Auth, Firestore, Functions, Storage, Messaging) et la connexion Google sont retirés. Toutes les données vivent dans la base Drift du téléphone.
2. **Règles du jeu** : calculées par les use cases purs de la couche `domain` (et non plus par des Cloud Functions). Les quêtes, séries, pénalités et agrégats musculaires sont évalués sur l'appareil, à l'ouverture de l'application et à chaque séance, dans le fuseau horaire du téléphone.
3. **Sauvegarde** : export d'un fichier JSON versionné (partage vers Drive, mails…) et import pour restaurer sur un nouveau téléphone. Effacement complet des données dans les paramètres.
4. **Coach caméra** : retiré du MVP. Plus de bonus caméra (+10 %) ; les répétitions sont saisies à la main, y compris pendant les épreuves de boss.
5. **Nom du personnage** : unicité non vérifiable sans serveur ; seuls la longueur (3 à 16 caractères) et le filtre anti-insultes s'appliquent.
6. **Classement entre amis** : impossible sans serveur ; reste hors périmètre.
7. **Anti-triche** : sans objet pour une application solo.
8. **Créateur de personnage (phase 6)** : interface à menus déroulants demandée, qui met à jour la fiche JSON du personnage et affiche le rendu en direct, avec un choix de **race (Humain, Elfe, Orque)** en plus du sexe, du nombre de coiffures et de la couleur de peau. Modèles **originaux uniquement** : `wow-model-viewer`, Wowhead et les exports de World of Warcraft sont exclus (assets protégés). Le détail (races × sexes, maillages à prévoir) sera validé avec le plan de la phase 6 et reporté dans ASSETS.md.

## 22. Décisions de la phase 2 (04/11/2026)
1. **Animations d'exercices** : mannequin 2D original (`FigureAnimationPlayer`), qui exécute le mouvement en boucle ; les segments du corps sont colorés en vert vif (muscles principaux) et vert clair (secondaires). La version 3D (modèle anatomique sous licence compatible + animations Mixamo) viendra plus tard, assemblée par un artiste 3D, via la même interface `ExerciseAnimationPlayer` (docs/ASSETS.md §1). Z-Anatomy est écarté (licence CC BY-SA à partage à l'identique).
2. **Silhouettes face et dos** : SVG originaux à 33 zones (`assets/svg/body_*.svg`), communs à la fiche exercice, à la création d'exercices personnalisés et, en phase 5, à la heatmap. Chaque rôle est signalé par une couleur **et** un motif (hachures = principal, points = secondaire) et listé en texte.
3. **Catalogue** : 27 exercices de référence validés (le référentiel compte hip thrust et pont fessier séparément). Les 53 suivants sont proposés **par lots de 10** dans ANATOMY.md §2 bis ; chaque lot rejoint le catalogue après validation.
4. **Jours de repos** : seuls les programmes de **mobilité** peuvent y être planifiés.
5. **Rappels** : notifications locales programmées sur le téléphone, 30 minutes avant la séance (valeur provisoire dans la configuration de jeu), avec une demande d'autorisation au premier rappel activé.
6. **Difficulté** d'un exercice : 1 à 3, affichée avec les libellés de niveau du questionnaire (Débutant, Intermédiaire, Avancé).

## 23. Décisions de la phase 3 (05/11/2026)
1. **Déroulé d'une séance** : musculation = séries puis repos prévu (pas de repos après la dernière série) ; Tabata/HIIT/circuit = rounds de travail et de repos, exercices à tour de rôle, repos entre les cycles ; cardio = un effort par exercice (durée chronométrée ou distance confirmée) ; mobilité = un maintien chronométré par exercice.
2. **Intensité ressentie** : demandée après chaque série de musculation ; pour les autres formats, une intensité unique en fin de séance s'applique à tous les efforts. Une intensité de 10/10 affiche un message de prudence.
3. **Bouton « Douleur ou malaise »** toujours visible : arrêt immédiat, message de prudence (repos, hydratation, 15 ou 112 en cas de signes graves), efforts déjà réalisés enregistrés.
4. **XP d'un effort (provisoire)** : `10 × volume normalisé × multiplicateur d'intensité`, avec volume normalisé = répétitions / 10, ou distance / 1 000 m, ou secondes d'effort / 60. Le multiplicateur va linéairement de 0,8 (1/10) à 1,3 (10/10) ; sans saisie, intensité neutre (6/10). Les bonus de série de jours et de classe s'ajouteront en phase 4. Valeurs marquées provisoires dans `game_config.dart` (section `xp`).
5. **Plafond quotidien** : l'effort actif (repos et pauses exclus) est cumulé sur la journée locale ; la part au-delà de 120 min rapporte moitié moins d'XP, au prorata, avec un message de prudence dans le bilan.
6. **Signaux** : bips originaux générés par `tool/sounds.py`, vibrations, voix (synthèse vocale du téléphone, hors ligne, désactivée par défaut) ; réglables dans les paramètres. L'écran reste allumé pendant la séance. Une erreur de son ou de voix n'interrompt jamais la séance.
7. **Volume par muscle** (points de la heatmap) : calculé en phase 5 à partir des séances enregistrées ; le bilan de la phase 3 affiche seulement les muscles sollicités (principal / secondaire).

## 24. Décisions de la phase 4 (05/11/2026)
1. **XP finale d'une séance** = XP de base (§23.4) × bonus de série (+5 % par jour de série acquis avant la séance, plafonné à +50 %) × 0,8 si la Zone de Pénalité est active. Le bonus de classe s'ajoutera en phase 8.
2. **Niveaux** : 100 XP pour 0 → 1 (Éveil), puis `round(100 × n^1,5)`. Chaque niveau donne 3 points de stat libres et (5 + niveau) cristaux. Niveau maximum 100.
3. **Blocage de rang** : au dernier niveau d'un rang (9, 19, 34, 49, 69, 89), la barre se remplit puis l'XP en trop est perdue tant que le boss du rang n'est pas vaincu ; la victoire fait passer le niveau immédiatement.
4. **Stats** : valeur = points placés + 1 point par tranche de 50 XP attribuée à la stat (répartition des exercices, provisoire). La Volonté vient uniquement de la régularité : +1 par jour de série validé (provisoire).
5. **Jour validé** : une séance complète (tous les efforts réalisés). Les jours de repos déclarés et les jours de maladie sont neutres : ils ne prolongent ni ne cassent la série. Coffres de série : 20, 60, 200 et 700 cristaux à 7, 30, 100 et 365 jours (provisoire).
6. **Bascule quotidienne** à l'ouverture et avant chaque séance : chaque jour écoulé est évalué en date civile (insensible aux changements d'heure). Jour manqué : un bouclier protège la série, sinon elle repart à zéro ; le malus de −20 % dure 24 h et ne se cumule pas. Jamais de perte de niveau, d'objet ni de cristaux. Le jour de création du profil n'est jamais compté comme manqué.
7. **Boucliers** : +1 tous les 14 jours écoulés (stock de 2). **Quête de pénalité** (en attendant les quêtes de la phase 8) : terminer une séance pendant le malus le lève.
8. **Mode maladie** : 1 à 14 jours à partir d'aujourd'hui, lève le malus en cours ; y mettre fin laisse le jour en cours neutre.
9. **Joueurs existants** : à la première ouverture avec la progression, l'XP des séances déjà enregistrées est rejouée, sans pénalité rétroactive.

## 25. Décisions de la phase 5 (05/11/2026)
1. **Analyse musculaire** accessible depuis la Fenêtre du Système : vues jour, semaine (lundi → dimanche), mois et année, avec navigation vers les périodes passées (jamais au-delà de la période en cours).
2. **Volume** (ANATOMY.md §3) : en musculation, une série d'intensité ≥ 6/10 vaut 1 point par muscle principal et 0,5 par secondaire ; Tabata/HIIT/circuit : 0,25 par round et par principal, la moitié pour un secondaire (provisoire) ; cardio : 1 point par 10 minutes, 3 au plus par séance et par muscle ; la mobilité alimente seulement l'indicateur de souplesse (en minutes).
3. **Heatmap** : vues mois et année exprimées en moyenne par semaine écoulée (au moins une semaine). Seuils hebdomadaires 4 / 8 / 12 et quotidiens 2 / 4 / 6 (`game_config.dart`). Chaque niveau a une couleur, un motif (hachures, points, lignes, quadrillage) et un libellé, avec une légende et un détail par muscle.
4. **Alertes de déséquilibre** (provisoires, ANATOMY.md §6) : avant / arrière du corps et poussée / tirage, à partir d'un volume total de 4 et au-delà d'un rapport de 1,5.
5. **Conseils du Système** : jusqu'à 3 muscles pas du tout ou pas assez travaillés, chacun avec l'exercice le plus simple du référentiel validé qui le cible comme muscle principal et que l'équipement du joueur permet. Aucun conseil sans séance sur la période.

## 26. Décisions de la phase 6A (05/11/2026)
1. **Monnaie** : les Cristaux de Mana sont remplacés par des **pièces de bronze, d'argent et d'or** (100 bronze = 1 argent, 100 argent = 1 or). Une séance rapporte du bronze selon l'XP de chaque effort et la **difficulté de l'exercice** : 1 bronze par XP (facile), 1,5 (intermédiaire), 2,5 (avancé), bonus de série et malus de pénalité compris. Un niveau donne (5 + niveau) pièces d'argent ; les coffres de série donnent 10, 40, 150 et 600 pièces d'argent. Les cristaux déjà gagnés deviennent du bronze, 1 pour 1. Valeurs provisoires (`game_config.dart`, section `coins`).
2. **Personnage** : fiche JSON (sexe, race, nom, corpulence, musculature, taille, couleur de peau, coiffure 1 à 10, couleur des cheveux), enregistrée sur le téléphone, brouillon conservé à chaque choix, comprise dans la sauvegarde (format v5).
3. **Races** : Humain, Elfe (plus grand, oreilles allongées), Orque (carrure et mâchoire larges, défenses, peaux vertes ou grises). Homme et femme ont chacun leur maillage.
4. **Morphologie** : deux curseurs, avec des mots bienveillants qui changent selon le sexe — *Corpulence* : Élancée, Fine, Équilibrée, Pulpeuse, Généreuse / Élancé, Mince, Équilibré, Robuste, Imposant ; *Musculature* : Légère, Tonique, Athlétique, Musclée, Puissante / Léger, Tonique, Athlétique, Musclé, Puissant. Taille de 150 à 205 cm.
5. **Équipements** : la tenue et les coiffures sont exportées avec les mêmes formes de morphologie que le corps ; tout futur équipement de la boutique devra suivre la même règle (docs/ASSETS.md §2).
6. **Rendu 3D** : vue web embarquée avec three.js (licence MIT), entièrement hors ligne ; l'interface `CharacterRenderer` reste indépendante du moteur. Si le rendu échoue, le créateur reste utilisable.
7. **Nom** : 3 à 16 caractères, lettres, espaces, tirets et apostrophes, filtre anti-insultes (variantes accentuées et chiffres compris). Sans serveur, l'unicité n'est pas vérifiée (§21.5).
8. **Accès** : « Création du personnage » depuis la Fenêtre du Système ; le personnage reste modifiable.

## 27. Décisions de la phase 6B (05/11/2026)
1. **Silhouettes** : 12 préréglages par sexe, qui ne règlent que corpulence et musculature (ajustables ensuite) — *Femme* : Délicate, Svelte, Athlétique, Nageuse, Sprinteuse, Musclée, Culturiste, Guerrière, Ronde, Costaude, Généreuse, Sablier ; *Homme* : Fin, Svelte, Athlétique, Nageur, Sprinteur, Musclé, Culturiste, Colosse, Robuste, Costaud, Imposant, En V.
2. **Visage** : cinq curseurs (mâchoire, nez, bouche, pommettes, oreilles ; libellés de « Très fine » à « Très marquée »), 8 couleurs d'yeux, 6 sourcils, 6 barbes (hommes uniquement, couleur des cheveux par défaut ou couleur propre), 4 maquillages (khôl, lèvres, joues, peinture de guerre). L'onglet Visage cadre la caméra sur la tête.
3. **Coiffures** : trois familles (courtes, attachées, longues) et jusqu'à 5 favorites (`favoriteHairstylesMax`). Les coiffures verrouillées arrivent avec la boutique (phase 7).
4. **Poses et posture** : 4 poses (en A, détendue, héroïque, combat), 4 postures (neutre, droite, voûtée, bombée) ajoutées à la pose, respiration discrète permanente. Pose et posture sont enregistrées dans la fiche.
5. **Scène** : éclairages jour, nuit et taverne ; comparaison avant / après (fiche à l'ouverture du créateur) ; capture PNG partagée par la feuille de partage du téléphone, uniquement sur action de l'utilisateur (§5 règle 10).
6. **Créateur** : quatre onglets (Corps, Visage, Coiffure, Nom & fiche), bouton « Valider » toujours visible.
7. **Compatibilité** : les nouveaux champs de la fiche ont tous une valeur par défaut ; une fiche ou une sauvegarde v5 se relit sans migration de la base (la fiche est stockée en JSON).
8. **Limite connue** : sourcils, barbes et maquillages des modèles de substitution sont des pièces grossières découpées dans le maillage ; la version définitive est attendue de l'artiste (docs/ASSETS.md §2).

## 28. Décisions de la phase 7 (10/11/2026)
1. **Boutique** : 22 objets originaux et 3 coiffures, tous cosmétiques (aucun avantage de jeu). Ensembles *Cuir de l'Éveillé* (commun), *Maille du Veilleur* (rare), *Plates de l'Aube* (épique) ; capes du Vagabond (rare) et de l'Aube (légendaire), capuche du Crépuscule (épique) ; épée d'apparat de l'Aube (légendaire) et bâton de Braise (mythique).
2. **Emplacements** : tête, épaules, torse, mains, ceinture, jambes, pieds, dos, arme. Un objet par emplacement ; un objet de torse, de jambes, de pieds ou de ceinture masque la pièce correspondante de la tenue de départ ; casque, camail et capuche masquent la coiffure.
3. **Prix** (provisoires, `game_config.dart`, section `shop`) : communs de 1 à 3 pièces d'argent selon l'emplacement, rare 10 argent, épique 40 argent, légendaire 1 or 50 argent, mythique 5 or ; coiffure 10 argent ; teinture 50 bronze. **Jamais d'argent réel.**
4. **Achat** : confirmation obligatoire ; le débit des pièces et la livraison sont enregistrés dans une seule transaction de la base (jamais de débit sans objet).
5. **Essayage** : en boutique, l'article choisi s'affiche sur le personnage enregistré par-dessus sa tenue, sans achat.
6. **Teinture** : capes, capuche, veste et chausses de cuir ; 10 teintes nommées.
7. **Coiffures verrouillées** : Crête, Double natte et Crinière s'achètent en boutique ; une coiffure déjà portée par le personnage enregistré reste utilisable ; le tirage aléatoire ne propose que les coiffures disponibles.
8. **Données** : base v7 (table `inventory_states`), sauvegarde v6 (`inventory`) ; un inventaire relu est nettoyé (objets inconnus, objets portés non possédés, teintures d'objets non teignables).
9. **Modèles** : les objets sont inclus dans les six fichiers `.glb` (mêmes formes de morphologie et mêmes poids de peau que le corps ; armes liées à la main droite). Environ 6 à 7 Mo par modèle. Ce sont des pièces de substitution, à remplacer par l'artiste (docs/ASSETS.md §3).

## 29. Corrections du créateur et de la boutique (11/11/2026)
1. **Musculature** : le curseur change le relief des muscles sans faire grossir ni maigrir. Dans MakeHuman, retirer du muscle à poids égal ajoute de la graisse : l'état « peu musclé » baisse donc aussi le poids (tour de taille identique au corps de base), et l'état « très musclé » accentue le relief (× 1,5). La corpulence reste le seul curseur de gras / mince.
2. **Poses et postures retirées** (§27.4 annulé) : le personnage garde une pose détendue fixe, avec la respiration.
3. **Yeux, sourcils, cils, coiffures** : pièces des paquets officiels MakeHuman, **licence CC0** (utilisables commercialement), ajustées sur chaque corps et chaque morphologie, avec textures teintées par l'application. L'iris est une pièce à part : seule elle prend la couleur des yeux.
4. **Coiffures** : 1 Courte, 2 Queue de cheval, 3 Natte, 4 Chignon, 5 Longue, 6 Mèches rebelles, 7 Très courte, 8 Double natte, 9 Carré, 10 Bouclée. Familles : courtes (1, 6, 7, 10), attachées (2, 3, 4, 8), longues (5, 9). Coiffures de la boutique : 6, 8 et 10.
5. **Maquillages** : peints en dégradés doux (khôl qui suit la paupière avec une pointe, rouge à lèvres, fard à joues, peinture de guerre).
6. **Boutique** : chaque article montre une vignette de l'objet seul à gauche (`assets/items/`) et un bouton « Voir sur mon personnage » qui ouvre une grande vue 3D, orientable, du personnage portant l'article.
7. **Modèles allégés** : textures WebP et géométrie compressée (meshopt), environ 3,3 Mo par modèle au lieu de 6 à 7.


## 30. Décisions de la phase 8A (11/11/2026)
Plan proposé le 11/11/2026 ; la propriétaire du projet a demandé de poursuivre la phase 8 après les corrections du §29. Toutes les valeurs chiffrées sont **provisoires** (`game_config.dart`, sections `quests` et `trials`).

1. **Quête quotidienne du Système** (`features/quests`) : générée une fois par jour (date civile locale), de façon reproductible, par `generateDailyQuest`. Elle compte 3 ou 4 objectifs tirés du **catalogue validé uniquement** (jamais un exercice en attente de relecture ni personnalisé), selon l'équipement du joueur et une difficulté au plus d'un cran au-dessus de son niveau : deux exercices de force à muscles principaux différents, un cardio chronométré et, une fois sur deux, un gainage. Objectifs de base selon le niveau du questionnaire (20 / 30 / 40 répétitions, 10 / 15 / 20 min de cardio, 45 / 60 / 90 s de gainage), réduits pour les exercices difficiles (× 1, 0,75, 0,5) et augmentés de 2 % par niveau du joueur, au plus × 2.
2. **Jours de repos et maladie** : aucune quête ; le Système invite à récupérer (le catalogue validé n'a pas encore d'exercice de mobilité légère).
3. **Progression** : calculée automatiquement à partir des efforts réalisés dans la journée (toutes séances confondues, efforts sautés exclus). Le bouton « Accomplir la quête » lance une séance générée avec les quantités restantes (séries de 15 répétitions au plus).
4. **Récompense** : quête terminée = (30 + 2 × niveau) XP, autant de pièces de bronze, +1 Volonté, versées une seule fois, et **validation du jour** (série prolongée, coffre aux paliers) si aucune séance complète ne l'a déjà fait.
5. **Quête de pénalité** (remplace §24.7) : pendant le malus de la Zone de Pénalité, réaliser **la moitié** des objectifs de la quête du jour lève le malus. Terminer une séance ne suffit plus.
6. **Épreuves de rang** (`features/trials`) : un boss par rang, de E à S (le Monarque n'en a pas) ; les natures tournent force → endurance → agilité.
   - Force : pompes puis squats (E : 20 et 30 … S : 75 et 110) en **10 minutes d'effort au plus** (repos exclus), répétitions saisies à la main.
   - Endurance : marche (rang E, 20 min) puis course chronométrée (15 à 40 min).
   - Agilité : circuit de jumping jacks et de mountain climbers, 20 s d'effort / 10 s de repos, 8 à 20 rounds.
   - Accès : être au **dernier niveau du rang** et avoir la stat de l'épreuve au minimum requis (10, 20, 30, 45, 60, 80).
   - Victoire : séance complète, sans arrêt pour douleur, objectifs et temps respectés. Le boss est vaincu, la barre d'XP pleine fait passer le niveau et le rang immédiatement, un **titre** est gagné (affiché en phase 9) et un **objet exclusif** rejoint l'inventaire.
   - Défaite : rien n'est perdu, nouvel essai après **48 h**.
   - Une consigne de prudence précède chaque épreuve ; le bouton « Douleur ou malaise » du lecteur reste disponible.
7. **Boss et titres** (créations originales) : Gardien du Rocher (« Briseur de Rocher »), Cerf d'Argent (« Coureur des Brumes »), Danseuse des Vents (« Pied-de-Vent »), Colosse de Basalte (« Brise-Colosse »), Comète Écarlate (« Sillage de Comète »), Seigneur des Tempêtes (« Œil de la Tempête »).
8. **Objets exclusifs** : variantes teintées de pièces existantes, absentes de la boutique et teignables (veste du Gardien, cape du Cerf d'Argent, capuche de la Danseuse des Vents, chausses du Colosse, cape de la Comète, capuche du Seigneur des Tempêtes). Des modèles propres sont attendus de l'artiste (docs/ASSETS.md §4).
9. **Cinématique** : fenêtre du Système « Victoire ! » animée dans le bilan de séance (désactivée si le téléphone limite les animations). Une vraie cinématique 3D reste à produire.
10. **Données** : base v8 (tables `quest_states` et `trial_states`), sauvegarde v7 (`quest`, `trials`), v6 toujours lisible. Une récompense est enregistrée dans la même transaction que la quête ou l'épreuve qui la donne.

## 31. Décisions de la phase 8B (11/11/2026)
Valeurs chiffrées **provisoires** (`game_config.dart`, sections `quests` et `classes`).

1. **Classes** (§6) : choix à partir du **rang C**, changement possible **30 jours** après le précédent. Le bonus s'ajoute à l'XP de base avant les autres multiplicateurs (§20.2) : +15 % sur la part de l'XP qui va à la stat de la classe (Berserker : Force, Ranger : Endurance, Assassin : Agilité, Tank : Vitalité), ou +5 % sur toute l'XP pour le Nécromancien (son bonus sur les Ombres arrivera en phase 9). Le bilan de séance affiche l'XP de classe.
2. **Quête hebdomadaire** (lundi → dimanche) : séances complètes (jours d'entraînement moins un, entre 2 et 5), minutes d'effort actif (60 / 90 / 120 selon le niveau du questionnaire, + 2 % par niveau du joueur, au plus × 2) et 3 quêtes du jour accomplies. Récompense : (100 + 5 × niveau) XP et 10 pièces d'argent, une fois par semaine.
3. **Donjon hebdomadaire** : un thème par semaine, en alternance — Crypte de Pierre (force, séries), Forêt des Échos (circuit d'endurance 20 s / 10 s), Tour des Vents (circuit d'agilité et de gainage). Trois salles générées à partir du catalogue validé et de l'équipement, à franchir **dans l'ordre et une par jour au plus** ; aucune salle n'ouvre un jour de repos ou de maladie. Une salle compte si sa séance est complète. Butin à la sortie : 150 XP et un objet commun ou rare de la boutique pas encore possédé (tirage stable), ou 30 pièces d'argent si tout est possédé.
4. **Quêtes d'événement** : calendrier d'Arisia sur le téléphone (dates locales) — Éveil du Printemps (18 mars → 1er avril, 8 séances), Grande Marche d'Été (18 juin → 2 juillet, 300 min), Fête des Moissons (20 septembre → 4 octobre, 8 séances), Solstice d'Hiver (18 décembre → 3 janvier, 300 min). Récompense : 200 XP et 25 pièces d'argent par édition. Les titres d'événement viendront avec les titres (phase 9).
5. **Données** : la semaine, le donjon et les événements récompensés forment le « tableau des quêtes », stocké en JSON dans une seconde ligne de `quest_states` (pas de nouvelle table, base toujours en v8). Sauvegarde v8 (`questBoard`), v7 toujours lisible. Les récompenses sont enregistrées dans la même transaction que les quêtes qui les donnent.

## 32. Personnages plus réalistes (11/11/2026)
Demande de la propriétaire du projet : tenues, coiffures et barbes plus réalistes, pose souple et naturelle. Ressources CC0 et CC BY acceptées (crédits obligatoires), modèles jusqu'à environ 6 Mo.

1. **Peau** : texture réaliste (MakeHuman, CC0) ramenée à une teinte neutre ; la couleur de peau choisie est appliquée par-dessus, pour toutes les races (orques verts ou gris compris).
2. **Tenue de départ** : blouse lacée en lin, pantalon de toile et bottes de cuir, vraies pièces texturées qui suivent corpulence et musculature (la tunique découpée dans le corps et la ceinture de corde sont retirées). Un maillot et un collant sombres, ajustés à la peau, couvrent le corps quand un objet de la boutique remplace la blouse ou le pantalon.
3. **Coiffures** : les dix styles gardent leur famille (§29.4) avec des modèles plus détaillés (mèches texturées) ; contraste des textures adouci pour que la couleur choisie s'applique de façon homogène.
4. **Barbes** : de vraies barbes en mèches au lieu de la peau peinte. Libellés : Collier, Bouc, Moustache, Courte, Longue, Moustache en guidon.
5. **Pose** : bras le long du corps, coudes et doigts légèrement fléchis, paumes vers les cuisses, poids sur la jambe gauche (bassin incliné, genou droit relâché), tête un peu inclinée ; la respiration continue.
6. **Rendu** : reflets doux d'une pièce virtuelle générée (sans image ni réseau) en plus des trois éclairages.
7. **Crédits** : nouvel écran Paramètres → Crédits (ressources CC BY avec auteur et page d'origine, ressources CC0, three.js, polices).
8. **Limites** : les sourcils restent des plaques texturées (les sourcils en vrais poils pèsent 10 000 à 28 000 points chacun, trop pour un téléphone) ; les objets de la boutique, moulés sur le corps, seront refaits avec de vraies pièces dans une étape suivante.

## 33. Équipement de la boutique plus réaliste (11/11/2026)
1. **Vraies pièces** (MakeHuman, CC0 et CC BY) : tunique et pantalon de cuir, gants (trois longueurs), bottes de cuir, haubert de maille à manches, heaume de chevalier, solerets à revers, capuche de moine. Elles suivent corpulence, musculature et pose.
2. **Matières réalistes** (ambientCG, CC0) : cuir, maille, acier brossé, or, tissu, avec relief ; la teinture des objets teignables est conservée.
3. **Plaques forgées** : plastron, épaulières, tassette et jambières lissées pour perdre les formes du corps.
4. **Bâton de Braise** : hampe de bois, bague dorée, orbe incandescent ; épée d'apparat en acier, or et cuir.
5. Vignettes de la boutique refaites ; crédits CC BY complétés (Paramètres → Crédits). Modèles de 4,8 à 6 Mo.

## 34. Décisions de la phase 9 (11/11/2026)
1. **Hauts faits** : 63 hauts faits en 7 catégories (régularité, volume, statistiques, boss et Ombres, exploration, équilibre musculaire, secrets), définis avec leurs seuils dans `game_config.dart`. Ils sont calculés à partir de l'historique enregistré : les joueurs d'avant la phase 9 les obtiennent à l'ouverture de la page. Les secrets restent masqués (« Haut fait secret ») jusqu'à leur obtention.
2. **Santé** : aucun haut fait ne pousse au surentraînement. La « longue séance » (45 min d'effort) doit rester sous le plafond quotidien ; le repos est récompensé (« Sage du Repos » : 20 jours de repos déclarés respectés) ; arrêter une séance pour une douleur débloque « À l'écoute de soi ».
3. **Titres** : ceux des boss (phase 8A) et 14 titres de hauts faits (« L'Éveillé », « Celui qui ne saute jamais les jambes », « Monarque de l'Aube »…). Un titre se porte sous le nom, sur la carte du chasseur de la Fenêtre du Système.
4. **Auras** : six auras (Aube, Braise, Givre, Sylvestre, Ombre, Orage), chacune débloquée par un titre ; anneau lumineux au sol et particules qui montent autour du personnage.
5. **Ombres** : à partir du rang B, chaque boss vaincu (rangs B, A et S) et chaque donjon de la semaine terminé laisse une Ombre à extraire (bouton « Extraire »). Sans les donjons, il n'y aurait que trois Ombres pour cinq places. Stat d'une Ombre : celle exigée par l'épreuve du boss, ou celle du thème du donjon (Crypte → Force, Forêt → Agilité, Tour → Endurance). Cinq Ombres actives (sept pour le Nécromancien), +2 % d'XP sur la part de leur stat (+4 % pour le Nécromancien), cumulés par multiplication avec les autres bonus.
6. **Apparence des Ombres** : silhouettes sombres et translucides du personnage du joueur, d'une teinte différente chacune, placées derrière lui (page Ombres).
7. **Stockage** : base v9 (`achievement_states`, `shadow_states`) et sauvegarde v9 ; les sauvegardes plus anciennes restent lisibles.
