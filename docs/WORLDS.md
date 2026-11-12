# WORLDS.md — Progression multi-mondes (à réaliser plus tard)

> Cahier des charges remis par la propriétaire du projet le 12/11/2026, **à mettre en route une fois terminés les chantiers en cours** (comptes locaux, équipements, santé). Il a été conservé tel quel ci-dessous. Les « Points à trancher » en fin de document doivent être validés avec elle avant de commencer (processus par phase de CLAUDE.md).

## Partie 1 : règles générales

### 1. Progression globale (jamais réinitialisée)
- Ces données sont stockées une seule fois au niveau du profil : niveau, XP, les 4 stats (Force, Endurance, Équilibre, Souplesse), historique des séances, poids, objectif de poids, monnaie et streak (série de jours consécutifs).
- Les stats n'ont pas de maximum et ne diminuent jamais.
- Le monde actif change uniquement l'apparence : textes, couleurs, icônes, polices, visuels, noms des stats, de l'XP, de la monnaie et des grades. Utilise un fichier de configuration par monde.
- Aucun son ni musique n'est à intégrer pour le moment.

### 2. Données sauvegardées par monde
- Pour chaque monde : objets possédés, tenue équipée, progression des hauts-faits, faction choisie, palier attribué et statut « maîtrisé ».
- Les objets obtenus ne sont jamais supprimés.
- Les hauts-faits d'un monde progressent uniquement quand ce monde est actif. Leur progression reste sauvegardée hors du monde.

### 3. Système de paliers (progression longue durée)
- Chaque monde correspond à un palier de 100 points de stats :
  - Palier 1 = Médiéval : stats 0 à 100, coût 3 points d'effort par point de stat.
  - Palier 2 = 1er monde débloqué : 100 à 200, coût 4.
  - Palier 3 = 2e monde débloqué : 200 à 300, coût 5.
  - Palier 4 = 3e monde débloqué : 300 à 400, coût 6.
  - Nexus des Mondes : 400 et plus, coût 7, sans limite.
- Le joueur choisit librement l'ordre des mondes Sorcier, Viking et Pirate. Le palier d'un monde est fixé au moment de son déblocage.
- Tous les coûts sont dans un fichier de configuration modifiable.

### 4. Gain de points
- Une séance rapporte environ 30 points d'effort, répartis entre les stats selon les muscles travaillés (ex. pompes + abdos = Force ; course = Endurance ; gainage/yoga = Équilibre ; étirements = Souplesse).
- Maximum 2 séances comptées par jour.
- Bonus de série : +5 % d'effort par semaine complète, plafonné à +25 %.
- Après la séance, écran « Upgrade ! » : le joueur voit ses points gagnés et les attribue lui-même à ses stats pour devenir plus fort.

### 5. Affichage des stats et grades
- Dans le monde actif, chaque stat s'affiche en pourcentage de son palier (0 à 100 %), avec la valeur réelle visible en détail.
- Si une stat est encore sous le palier du monde actif, elle s'affiche à 0 % avec la mention « rattrapage en cours ».
- Le grade (1 à 8) est calculé à partir de la moyenne des 4 stats dans le palier du monde actif : grade 1 = 0 %, puis un grade tous les 12,5 %, grade 8 = 87,5 % et plus.

### 6. Hauts-faits
- Les conditions de stats sont relatives au palier : « 4 stats au-dessus de 75 » signifie « 4 stats au-dessus de (début du palier + 75) ».
- Les compteurs de séances ne prennent en compte que les séances réalisées pendant que ce monde est actif. Les séances passées ne débloquent rien d'avance.

### 7. Déblocage des mondes
- Le Médiéval est actif par défaut.
- Un nouveau monde exige : le monde précédent maîtrisé + son haut-fait rare de déblocage (détaillé dans chaque monde).
- À la première activation d'un monde, le joueur choisit sa faction. La faction donne +10 % d'effort dans sa stat associée.
- Le joueur peut revenir à tout moment dans un monde déjà débloqué pour changer d'apparence.

### 8. Maîtrise d'un monde
Un monde est maîtrisé quand le joueur a :
- débloqué tous les hauts-faits du monde ;
- obtenu l'objet légendaire du monde ;
- atteint le grade 8 dans ce monde.

Afficher alors un badge doré du monde sur le profil.

### 9. Défis
Chaque monde propose un défi hebdomadaire et un défi mensuel (ex. « 4 séances d'Endurance dans la semaine ») qui donnent de la monnaie et des objets cosmétiques exclusifs.

### 10. Carte d'évolution du poids
- Chaque monde affiche la même progression de poids sous forme de carte illustrée avec 6 étapes, réparties proportionnellement entre le poids de départ et l'objectif. Dernière étape = objectif atteint.
- Fonctionne pour une perte comme pour une prise de poids.
- Suivi journalier, hebdomadaire, mensuel et annuel en graphiques.

### 11. Sécurité des données
- Sauvegarde automatique après chaque séance et chaque changement.
- Synchronisation avec le compte utilisateur (base de données en ligne).
- Aucune action ne peut effacer la progression sans une double confirmation explicite.

## Partie 2 : monde Médiéval Fantasy (palier 1, par défaut)
- Ambiance : royaumes, citadelles, forêts enchantées, donjons.
- Couleurs : bleu royal #1E3A8A, or #D4AF37, pierre #4B4B4B.
- Monnaie : Pièces d'or. XP : Expérience.
- Stats : Puissance (Force), Vitalité (Endurance), Agilité (Équilibre), Dextérité (Souplesse).
- Grades : 1 Recrue, 2 Écuyer, 3 Soldat, 4 Chevalier, 5 Chevalier d'élite, 6 Champion, 7 Seigneur de guerre, 8 Héros légendaire.
- Factions (ordres) : Ordre du Lion (Force), Gardiens du Bastion (Endurance), Lames de l'Ombre (Équilibre), Cercle des Druides (Souplesse).
- Carte du poids : « La Route du Royaume » — du village jusqu'au trône du château royal.
- Objets de l'avatar :
  - Tête : casque de fer, heaume de chevalier, couronne de champion
  - Corps : armure de cuir, cotte de mailles, armure de plaques, armure dorée
  - Arme : épée courte, hache de guerre, marteau runique, Lame du Roi Déchu (légendaire)
  - Bouclier : rondache, écu blasonné, bouclier du dragon
  - Cape : cape de laine, cape royale, cape de flammes
- Hauts-faits :
  - Premier Combat : 1re séance → Épée courte
  - Bras de Fer : 10 séances de Force → Hache de guerre
  - Marche Forcée : 20 séances d'Endurance → Cotte de mailles
  - Pas du Duelliste : 15 séances d'Équilibre → Écu blasonné
  - Garde Permanente : 7 jours consécutifs → Cape royale
  - Champion du Royaume : les 4 stats au-dessus de 75 du palier → Lame du Roi Déchu (légendaire)

## Partie 3 : monde Sorcier (école de magie)
- Haut-fait rare de déblocage : « L'Appel de l'École » — 30 séances en 2 mois dont au moins 10 de Souplesse.
- Ambiance : château-école de magie, grandes salles éclairées à la bougie, bibliothèque, forêt interdite.
- Couleurs : bordeaux #6B0F1A, or ancien #C9A227, bleu nuit #0F1B3D.
- Monnaie : Gallions. XP : Mana.
- Stats : Puissance magique (Force), Résistance (Endurance), Concentration (Équilibre), Fluidité (Souplesse).
- Grades : 1 Première année, 2 Apprenti, 3 Élève confirmé, 4 Préfet, 5 Duelliste, 6 Auror, 7 Professeur, 8 Grand Mage.
- Factions (maisons) : Maison du Griffon (Force), Maison du Blaireau (Endurance), Maison du Corbeau (Équilibre), Maison du Serpent (Souplesse).
- Carte du poids : « Le Chemin du Château » — de la gare jusqu'au sommet de la tour d'astronomie.
- Objets de l'avatar :
  - Tête : chapeau pointu, chapeau de mage étoilé, couronne d'argent
  - Corps : robe d'élève, robe aux couleurs de la maison, cape de professeur, robe de Grand Mage
  - Arme : baguette de chêne, baguette de houx, bâton de mage, Baguette de Sureau Ancien (légendaire)
  - Compagnon : hibou, chat noir, crapaud, phénix (rare)
  - Accessoire : écharpe de maison, grimoire, balai de course, cape d'invisibilité
- Hauts-faits :
  - Premier Sortilège : 1re séance → Baguette de chêne
  - Maître des Potions : 10 séances de Force → Grimoire
  - Coureur de la Forêt : 20 séances d'Endurance → Balai de course
  - Esprit Clair : 15 séances d'Équilibre → Robe de la maison
  - Élève Assidu : 7 jours consécutifs → Hibou
  - Grand Mage : les 4 stats au-dessus de 75 du palier → Baguette de Sureau Ancien (légendaire)

## Partie 4 : monde Viking
- Haut-fait rare de déblocage : « L'Appel du Valhalla » — 25 séances de Force en 2 mois.
- Ambiance : fjords, drakkars, villages de bois, aurores boréales.
- Couleurs : bleu glacier #3A6EA5, brun bois #5C3A21, blanc neige #EDEFF2.
- Monnaie : Pièces d'argent. XP : Gloire.
- Stats : Rage (Force), Ténacité (Endurance), Ancrage (Équilibre), Souffle (Souplesse).
- Grades : 1 Fermier, 2 Guerrier, 3 Pillard, 4 Berserker, 5 Huscarl, 6 Jarl, 7 Roi des fjords, 8 Élu du Valhalla.
- Factions (clans) : Clan de l'Ours (Force), Clan du Loup (Endurance), Clan du Corbeau (Équilibre), Clan du Serpent de Mer (Souplesse).
- Carte du poids : « La Route du Valhalla » — du village côtier jusqu'aux portes du Valhalla.
- Objets de l'avatar :
  - Tête : bonnet de fourrure, casque nasal, casque à cornes de cérémonie
  - Corps : tunique de laine, armure de cuir clouté, cotte de mailles du Jarl, peau d'ours
  - Arme : hache de jet, épée runique, double hache, Marteau du Tonnerre (légendaire)
  - Compagnon : corbeau, loup gris, loup géant des glaces (rare)
  - Accessoire : bouclier rond peint, cor de guerre, bracelets de bras en argent, collier de runes
- Hauts-faits :
  - Premier Raid : 1re séance → Hache de jet
  - Bras de Berserker : 10 séances de Force → Double hache
  - Traversée des Fjords : 20 séances d'Endurance → Peau d'ours
  - Pied Marin : 15 séances d'Équilibre → Bouclier rond peint
  - Hiver Sans Faiblir : 7 jours consécutifs → Loup gris
  - Élu du Valhalla : les 4 stats au-dessus de 75 du palier → Marteau du Tonnerre (légendaire)

## Partie 5 : monde Pirate
- Haut-fait rare de déblocage : « L'Appel du Large » — 30 séances d'Endurance en 2 mois.
- Ambiance : îles tropicales, galions, ports pirates, trésors cachés.
- Couleurs : bleu océan #0E4D64, sable #E8C872, rouge corsaire #8B1E1E.
- Monnaie : Doublons. XP : Réputation.
- Stats : Abordage (Force), Endurance du marin (Endurance), Pied marin (Équilibre), Agilité du gréement (Souplesse).
- Grades : 1 Mousse, 2 Matelot, 3 Canonnier, 4 Maître d'équipage, 5 Second, 6 Capitaine, 7 Corsaire légendaire, 8 Seigneur des Sept Mers.
- Factions (équipages) : Les Briseurs de Coque (Force), Les Loups du Large (Endurance), Les Danseurs de Mât (Équilibre), Les Serpents des Récifs (Souplesse).
- Carte du poids : « La Chasse au Trésor » — du port de départ jusqu'à l'île au trésor.
- Objets de l'avatar :
  - Tête : bandana, tricorne, chapeau de capitaine à plume
  - Corps : chemise rayée, gilet de cuir, manteau de capitaine, veste de corsaire brodée d'or
  - Arme : sabre d'abordage, pistolet à silex, harpon, Sabre Maudit (légendaire)
  - Compagnon : perroquet, singe, crabe, bébé kraken (rare)
  - Accessoire : cache-œil, longue-vue, boucle d'oreille en or, boussole enchantée, pavillon personnalisé
- Hauts-faits :
  - Premier Abordage : 1re séance → Sabre d'abordage
  - Bras de Canonnier : 10 séances de Force → Pistolet à silex
  - Loup de Mer : 20 séances d'Endurance → Manteau de capitaine
  - Équilibriste du Mât : 15 séances d'Équilibre → Longue-vue
  - Cap sur l'Horizon : 7 jours consécutifs → Pavillon personnalisé
  - Seigneur des Sept Mers : les 4 stats au-dessus de 75 du palier → Sabre Maudit (légendaire)

## Partie 6 : récompense ultime — « Héros des Quatre Royaumes »
Condition : maîtriser les 4 mondes (Médiéval, Sorcier, Viking, Pirate). Afficher un écran de récompense avec les 4 badges dorés et la liste des récompenses débloquées (pas de cinématique).

Récompenses :
1. **Monde secret « Le Nexus des Mondes »** (palier 400 et plus, sans fin) — univers céleste, îles flottantes, ciel étoilé, ruines des 4 civilisations réunies. Couleurs : violet cosmique #2A0E4A, or céleste #FFD54A, cyan astral #3FE0FF. Monnaie : Éclats d'Étoile. XP : Légende. Stats : Titan (Force), Éternité (Endurance), Harmonie (Équilibre), Fluidité (Souplesse). Carte du poids : « L'Ascension », un escalier d'étoiles qui monte vers le Trône Céleste.
2. **Transmogrification** — le joueur peut équiper librement les objets de tous les mondes sur un même avatar (ex. chapeau de sorcier + armure viking + sabre pirate).
3. **Compagnon « Dragon Céleste »** — affiché à côté de l'avatar dans tous les mondes, ailes animées.
4. **Aura dorée animée** autour de l'avatar, visible dans tous les mondes.
5. **Titre « Héros des Quatre Royaumes »** sous le pseudo et cadre de profil animé aux couleurs des 4 mondes.
6. **Mode Prestige** (optionnel, jamais obligatoire) — remet à zéro la progression des hauts-faits de monde contre une étoile de Prestige. Ne touche jamais aux objets, à l'historique, au niveau, aux stats, au poids ni à la monnaie. Chaque étoile débloque une variante de couleur rare pour l'aura et le Dragon Céleste.

## Points à trancher avant de commencer
1. **Stats** : l'application a aujourd'hui 5 stats (Force, Endurance, Agilité, Vitalité, Volonté, SPEC §4). Le cahier en prévoit 4 (Force, Endurance, Équilibre, Souplesse), sans maximum, avec un coût en points d'effort par palier et une attribution manuelle après chaque séance. Il faut décider comment convertir les stats existantes des joueurs (migration de la base et de la sauvegarde).
2. **Synchronisation en ligne** (§11) : contraire au choix du 12/11/2026 (comptes locaux, 100 % hors ligne, SPEC §21 et §36). À confirmer : rester hors ligne (sauvegarde automatique locale et export) ou ouvrir un chantier serveur.
3. **Musique** : « aucun son ni musique pour le moment » ; les musiques par monde déjà reçues (Ouverture, Stats, Boutique et Level Up « Magie », Stats « Viking ») sont gardées de côté jusqu'à nouvel ordre.
4. **Propriété intellectuelle** (CLAUDE.md §1, univers 100 % original) : plusieurs noms du monde Sorcier reprennent de trop près une saga existante (les quatre maisons griffon / blaireau / corbeau / serpent, « Auror », « Préfet », « Première année », « Gallions », « Baguette de Sureau », « cape d'invisibilité », la gare et la tour d'astronomie, le balai de course). « Transmogrification » vient de World of Warcraft. Des équivalents originaux sont à proposer et à faire valider.
5. **Poids** : le suivi du poids (départ, objectif, graphiques) est une donnée nouvelle, à ajouter au profil et à la sauvegarde ; il doit rester bienveillant (pas de pression, cohérent avec CLAUDE.md §5.8).
6. **Ordre avec les autres chantiers** : comptes locaux → équipements → santé → mondes, sauf autre choix de la propriétaire.
