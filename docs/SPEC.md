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

