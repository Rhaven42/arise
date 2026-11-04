# ANATOMY.md — Référentiel anatomique ARISE

> **Source unique de vérité.** Aucune correspondance muscle ↔ exercice ne doit exister dans le code ou les catalogues si elle n'est pas écrite ici.
>
> ⚠️ **Relecture obligatoire** : ce référentiel doit être relu et validé par un **coach diplômé ou un kinésithérapeute** avant toute publication de l'application. Tout ajout ou modification doit également être relu avant publication.

## 1. Identifiants des muscles

Les identifiants (colonne `id`) sont utilisés partout : catalogues d'exercices, zones des SVG, agrégats serveur. Ils ne changent jamais une fois publiés.

### 1.1 Muscles visibles de face (`front`)
| id | Nom affiché | Remarque |
|---|---|---|
| `sternocleidomastoid` | Sterno-cléido-mastoïdien | |
| `pectoralis_upper` | Grand pectoral — partie haute | « pectoraux hauts » |
| `pectoralis_mid_lower` | Grand pectoral — partie moyenne-basse | « pectoraux moyens-bas » |
| `deltoid_anterior` | Deltoïde antérieur | |
| `deltoid_lateral` | Deltoïde latéral | |
| `biceps_brachii` | Biceps brachial | |
| `brachialis` | Brachial | |
| `forearm_flexors` | Fléchisseurs de l'avant-bras | |
| `brachioradialis` | Brachio-radial | |
| `rectus_abdominis` | Grand droit de l'abdomen | |
| `obliques` | Obliques | |
| `transversus_abdominis` | Transverse | Muscle profond, affiché avec les abdominaux |
| `serratus_anterior` | Dentelé antérieur | |
| `hip_flexors` | Fléchisseurs de la hanche (ilio-psoas) | |
| `adductors` | Adducteurs | |
| `abductors` | Abducteurs (tenseur du fascia lata) | |
| `quadriceps` | Quadriceps | |
| `tibialis_anterior` | Tibial antérieur | |

### 1.2 Muscles visibles de dos (`back`)
| id | Nom affiché |
|---|---|
| `trapezius_upper` | Trapèze supérieur |
| `trapezius_mid_lower` | Trapèze moyen-inférieur |
| `rhomboids` | Rhomboïdes |
| `latissimus_dorsi` | Grand dorsal |
| `teres_major` | Grand rond |
| `deltoid_posterior` | Deltoïde postérieur |
| `rotator_cuff` | Coiffe des rotateurs |
| `triceps_brachii` | Triceps brachial |
| `forearm_extensors` | Extenseurs de l'avant-bras |
| `erector_spinae` | Érecteurs du rachis |
| `gluteus_maximus` | Grand fessier |
| `gluteus_medius` | Moyen fessier |
| `hamstrings` | Ischio-jambiers |
| `gastrocnemius` | Gastrocnémien |
| `soleus` | Soléaire |

Total : **33 zones** (18 face, 15 dos). Chaque SVG contient exactement une zone `id="<muscle_id>"` par muscle de sa vue (zones symétriques gauche/droite regroupées dans un même groupe `<g id="...">`).

## 2. Mapping des exercices de référence

Format : **principaux** (P) puis **secondaires** (S). « Faiblement » est conservé tel quel et devra être traduit en coefficient uniquement après validation (voir question ouverte dans la ROADMAP).

| Exercice (`id`) | Principaux | Secondaires |
|---|---|---|
| Pompes (`push_up`) | pectoralis_mid_lower, deltoid_anterior, triceps_brachii | pectoralis_upper, serratus_anterior, rectus_abdominis, transversus_abdominis |
| Pompes déclinées (`decline_push_up`) | pectoralis_upper, deltoid_anterior, triceps_brachii | pectoralis_mid_lower, serratus_anterior |
| Pompes diamant (`diamond_push_up`) | triceps_brachii, pectoralis_mid_lower | deltoid_anterior |
| Dips (`dips`) | triceps_brachii, pectoralis_mid_lower, deltoid_anterior | trapezius_mid_lower, rhomboids |
| Tractions en pronation (`pull_up_pronated`) | latissimus_dorsi, teres_major, biceps_brachii, brachialis | rhomboids, trapezius_mid_lower, deltoid_posterior, brachioradialis, forearm_flexors |
| Rowing (`row`) | latissimus_dorsi, rhomboids, trapezius_mid_lower, deltoid_posterior | biceps_brachii, brachialis, erector_spinae |
| Développé militaire (`overhead_press`) | deltoid_anterior, deltoid_lateral, triceps_brachii | trapezius_upper, serratus_anterior |
| Élévations latérales (`lateral_raise`) | deltoid_lateral | trapezius_upper, deltoid_anterior |
| Curl biceps (`biceps_curl`) | biceps_brachii, brachialis | brachioradialis |
| Squat (`squat`) | quadriceps, gluteus_maximus | adductors, erector_spinae, soleus, hamstrings (faiblement) |
| Fentes (`lunge`) | quadriceps, gluteus_maximus | gluteus_medius, adductors, hamstrings |
| Soulevé de terre roumain (`romanian_deadlift`) | hamstrings, gluteus_maximus | erector_spinae, adductors, forearm_flexors |
| Hip thrust (`hip_thrust`) | gluteus_maximus | hamstrings, gluteus_medius |
| Pont fessier (`glute_bridge`) | gluteus_maximus | hamstrings, gluteus_medius |
| Mollets debout (`standing_calf_raise`) | gastrocnemius, soleus | — |
| Planche (`plank`) | rectus_abdominis, transversus_abdominis | obliques, serratus_anterior, deltoid_anterior, gluteus_maximus |
| Planche latérale (`side_plank`) | obliques, transversus_abdominis | gluteus_medius |
| Crunch (`crunch`) | rectus_abdominis | obliques |
| Relevés de jambes (`leg_raise`) | hip_flexors, rectus_abdominis | obliques |
| Superman (`superman`) | erector_spinae | gluteus_maximus, hamstrings, trapezius_mid_lower |
| Burpees (`burpee`) | quadriceps, gluteus_maximus, pectoralis_mid_lower | deltoid_anterior, triceps_brachii, rectus_abdominis, gastrocnemius |
| Jumping jacks (`jumping_jack`) | gastrocnemius, soleus, abductors, gluteus_medius | deltoid_lateral, adductors |
| Mountain climbers (`mountain_climber`) | rectus_abdominis, hip_flexors | deltoid_anterior, quadriceps, obliques |
| Marche (`walking`) | quadriceps, hamstrings, gluteus_maximus, gastrocnemius, soleus, tibialis_anterior | — |
| Course (`running`) | quadriceps, hamstrings, gluteus_maximus, gastrocnemius, soleus, tibialis_anterior, hip_flexors | — |
| Vélo (`cycling`) | quadriceps, gluteus_maximus | hamstrings, gastrocnemius, soleus |
| Corde à sauter (`jump_rope`) | gastrocnemius, soleus | quadriceps, deltoid_lateral, forearm_flexors |

26 exercices de référence (hip thrust et pont fessier comptés séparément).

## 3. Règles de conversion du volume

| Format | Règle |
|---|---|
| Musculation | Une **série effective** (intensité ressentie ≥ 6/10) = **1 point** par muscle principal et **0,5 point** par muscle secondaire. Une série d'intensité < 6 ne compte pas dans le volume. |
| Cardio | **10 minutes = 1 point** pour chaque muscle principal, **plafond de 3 points par séance** et par muscle. |
| Tabata / HIIT | **Un round de travail = 0,25 point** (répartition principaux/secondaires selon le mapping de l'exercice du round). |
| Mobilité / étirements | Alimentent un **indicateur de souplesse séparé** ; ne gonflent **jamais** le volume de renforcement. |

## 4. Seuils de la heatmap (configurables, valeurs par défaut)

Valeur mesurée : séries effectives **moyennes par semaine** sur la période (semaine, mois, année) ; en vue jour, séries effectives du jour.

| Niveau | Couleur | Semaine / mois / année | Vue jour | Motif (accessibilité) | Libellé |
|---|---|---|---|---|---|
| 0 | Gris | 0 | 0 | aucun | Pas du tout |
| 1 | Rouge | > 0 et < 4 | 1 | hachures diagonales | Pas assez |
| 2 | Orange | 4 à < 8 | 2 à 3 | points | Un peu |
| 3 | Vert clair | 8 à < 12 | 4 à 5 | lignes horizontales | Moyen |
| 4 | Vert vif | ≥ 12 | ≥ 6 | quadrillage | Très travaillé |

Motifs proposés à titre de valeur par défaut, à valider en phase 5.

## 5. Format obligatoire pour tout nouvel exercice
Tout exercice ajouté (catalogue officiel ou futur ajout) doit fournir :
```yaml
id: snake_case_unique
name: "Nom affiché"
type: reps | duration | distance
primaryMuscles: [muscle_id, ...]     # uniquement des id de la §1
secondaryMuscles: [muscle_id, ...]   # uniquement des id de la §1
volumeRule: strength | cardio | interval | mobility
reviewStatus: pending_review | validated   # validated = relu par coach diplômé / kiné
reviewedBy: "nom + qualification"          # requis si validated
```
Un exercice `pending_review` peut exister en développement mais **ne peut pas être publié**. L'utilisateur qui crée un exercice personnalisé choisit lui-même ses muscles sur la silhouette ; ces exercices restent privés et hors référentiel.

## 6. Groupes pour les alertes de déséquilibre
Ces regroupements sont nécessaires aux alertes poussée/tirage et avant/arrière (SPEC §11). **Ils restent à valider** (voir questions ouvertes) — aucune alerte ne sera livrée sans validation.
- Avant / arrière : dérivé directement des vues `front` / `back` de la §1.
- Poussée / tirage : à définir à partir des exercices (ex. pompes, dips, développé militaire = poussée ; tractions, rowing = tirage), non à partir des muscles seuls.
