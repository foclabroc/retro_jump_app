# Changelog — Rétro Jump 🚀

Historique des versions de l'application autonome (le jeu existe aussi dans [Foclabroc Remote](https://github.com/foclabroc/foclabroc-remote), avec le même classement).

---

## v1.0.8 — Octobre 2026

> Aucun changement côté serveur : le script Supabase v13 reste valable.

### 🎨 Style des pages
- 2 nouveaux styles pour l'interface : **Futuriste** (étoiles, anneaux HUD, sol quadrillé qui défile, accent cyan) et **Disco** (boule à facettes, faisceaux colorés, piste de danse lumineuse, accent rose)
- Fond animé sur l'accueil et dans tous les panneaux (Boutique, Classements, Stats, Réglages), cartes et fenêtres aux couleurs du style
- Nouvelle section **Style des pages** dans la Boutique, **3 000 pièces** chacun (Classique reste gratuit)

### 🎡 Roue de la fortune
- Roue **redessinée** : couronne dorée, ampoules qui clignotent, icônes des lots, pointeur et moyeu en relief
- Après **Récupérer**, la roue **reste ouverte** : le lot s'affiche et tu peux retenter ta chance (payant) directement
- Nouveau bouton **Fermer**

### 🕹️ Jeu
- **Plateformes verticales** qui montent et descendent
- **Son** au déclenchement du turbo
- Le bouton principal devient **Jouer Solo**

### 🧑 Avatars
- Beaucoup plus de modèles : peau (16), visage (8), coiffure (28), couleur des cheveux (24), yeux (18), bouche (18), accessoire (22), fond (24)
- Rendu **en relief** (ombres et reflets)

### 🛠️ Corrections et confort
- Le réglage **son / muet** est désormais conservé au relancement
- La pointe de la fusée de l'écran de démarrage n'est plus coupée
- Fenêtre **Nouveautés** au lancement (avec « Ne plus afficher ») à la place de l'explication des classements

---

## v1.0.7 — Octobre 2026

> ⚠️ Nécessite le script Supabase **v13 à jour** (relancer le script complet avant d'installer cette version).

### 🔔 Notifications
- **Alerte classement** : dès qu'un joueur te dépasse au **Solo** ou au **Défi du jour** (quelle que soit ta place), une notification Android indique son pseudo et son score, ton score et ta nouvelle place — vérification environ toutes les 15 min, même appli fermée
- Autorisation des notifications demandée au premier lancement
- Nouvelles permissions `POST_NOTIFICATIONS` et `RECEIVE_BOOT_COMPLETED`, dépendances `workmanager` et `flutter_local_notifications` (desugaring Java activé)

### ✨ Héros dorés
- Version **en or avec étincelles** de chaque héros, **15 000 pièces** (Boutique, sous la grille des héros) — enfin une utilité aux pièces une fois tout débloqué
- Visible par tous : classements, chat, fiche joueur, fantôme du défi, podium
- Interrupteur pour activer / désactiver la version dorée ; le pouvoir du héros ne change pas

### 🏅 Défi du jour et classements
- **Médaille de participation chaque jour** à tous les joueurs du défi hors podium (remise à minuit), comptée dans le **Défi semaine** (or, argent, bronze, puis participation) et cumulée dans le **Défi général**
- Classement : **onglets, pseudo, compte à rebours et « Ton rang » fixes** en haut, seule la liste défile
- **Fiche joueur** réorganisée : section *Défi du jour* (jour, semaine 🥇🥈🥉✅, général 🏆, défis gagnés / joués, meilleur défi) et section *Solo* (record et semaine)
- Fenêtre d'explication au lancement mise à jour (notifications en premier, participation quotidienne) — réaffichée une fois

---

## v1.0.4+5 — Octobre 2026

> ⚠️ Nécessite le script Supabase **v13** (lancé avant d'installer cette version).

### 🧑 Avatars façon Mii
- **Créer son avatar** (Réglages → Avatar) : 8 catégories — peau (12), visage (6), coiffure (20), couleur des cheveux (16), yeux (12), bouche (12), accessoire (14), fond (16) — avec miniatures et bouton 🎲 Aléatoire
- Affiché dans le **classement**, le **chat**, la **fiche joueur** et le **podium** de l'écran de démarrage (le héros reste affiché sans avatar)
- Le **héros utilisé pour le record** reste visible à côté du score
- Quelques octets par joueur côté serveur, inclus dans la sauvegarde

### 🎨 Nouveaux contenus
- **4 thèmes réalistes** : Jungle, Plage, Ville la nuit, Canyon (950 à 1 100 pièces)
  - Jungle : singes qui se balancent de liane en liane, guirlandes et lianes pendantes
  - Ville la nuit : avion, montgolfières, hélicoptère avec projecteur, dirigeable à bandeau LED
- **4 héros avec pouvoir** (600 à 800 pièces) : Manette (bug écrasé = 6 pièces), Portable (logos comptés double), Fantôme (2ᵉ chance gratuite, hors partie du jour), Casque (+25 % d'XP)
- **4 musiques** : RPG Battle, 8-bit Console, Byte Blast, Game On (1 100 à 1 500 pièces)
- **16 nouveaux trophées** (68 au total) — l'avancement % tient compte des nouveaux objets

### 🏆 Classement
- **4 onglets** :
  - **Défi du jour** : chaque jour, **médailles** d'or, d'argent et de bronze aux 3 premiers (remises à minuit)
  - **Défi semaine** : classement aux médailles gagnées dans la semaine ; chaque lundi à minuit, **coupes** d'or, d'argent et de bronze aux 3 premiers et **médaille de participation** aux autres joueurs de la semaine
  - **Défi général** : toutes les récompenses depuis le début (coupes, puis médailles du jour, puis participation)
  - **Solo** : meilleur score des parties normales — la partie du jour n'y compte plus
- Coupes affichées à côté du pseudo, palmarès complet sur la fiche joueur
- **Compte à rebours** de fin du défi du jour et de la semaine dans le classement
- Accueil : **Record Solo** (meilleur score des parties normales, synchronisé avec le serveur)
- Au lancement, **explication des nouveaux classements** (case « Ne plus afficher »)
- **Jusqu'à 500 joueurs** (« Voir plus ») et bouton **« Ma position »**
- **Heure de la dernière partie** de chaque joueur (classement et fiche)
- **Record battu** : au lancement, liste des joueurs qui t'ont dépassé au classement Solo depuis ta dernière visite
- Partie du jour : le record affiché en jeu est ton meilleur score **du jour**

### 🎡 Roue de la fortune
- Lots revus pour la boutique actuelle : **20 à 500 pièces**, **jackpot 1 000 pièces**, bouclier, turbo, départ 1000, rejouer offert et **objet surprise 🎁** (un héros, thème, musique ou traînée encore verrouillé, ou 1 000 pièces si tout est débloqué)
- Tour supplémentaire : **75 pièces**

### ⚙️ Réglages et confort
- **Intensité des vibrations** : Faible / Normal / Fort
- Nouveau record : le nom n'est plus demandé si un pseudo est déjà choisi
- Codes secrets utilisables **3 fois** chacun, résultat affiché dans une fenêtre

---

## v1.0.3+4 — Octobre 2026

### 🛡️ Jeu
- **Bouclier en réserve** — ramasser un bouclier alors qu'un autre est déjà actif le met en réserve (1 au maximum) : bannière « 🛡️ BOUCLIER EN RÉSERVE » et bulle cyan en bas au milieu de l'écran
  - Bulle grisée tant que le bouclier actif n'a pas servi, puis elle pulse : un appui l'active (l'appui ne fait pas bouger le héros)
  - Réserve conservée en cas de Continue, perdue en fin de partie
- Règle du bouclier complétée dans les Réglages

---

## v1.0.2+3 — Octobre 2026

### 🎮 Jeu
- **Bouclier de 2 s en sortie de turbo** (bonus ou propulsion de départ) : bulle qui clignote, insensible aux bugs
- **Option Fantôme** (Réglages → Options) : afficher ou non le fantôme du n°1 dans la partie du jour
- **Sensibilité réglable** (Réglages) : **tactile** 70 à 130 % (vitesse et réactivité du déplacement) et **inclinaison** 50 à 200 % (moins il faut pencher le téléphone) — réglages inclus dans la sauvegarde

### 🎨 Interface
- **Écran de démarrage** : ciel de nuit étoilé, titre « RÉTRO JUMP », « by foclabroc », héros qui rebondit sur une cartouche et **podium des 3 meilleurs scores** ; « Touche pour commencer » une fois chargé (la roue du jour s'ouvre ensuite)
- **Barre du bas** :
  - **Quêtes** (remplace Défis) : 3 onglets **Défis / Trophées / Collection** avec leur compteur ; le bouton 🏆 de l'en-tête ouvre directement les Trophées
  - **Messages** (remplace Collection) : le chat, avec pastille **NEW** (nouveau message) ou **@** (mention) — le Classement revient à 3 onglets
- **Compte à rebours** sur la tuile Défis du jour : « ⏳ Fin dans hh:mm:ss » jusqu'à minuit
- Titre de l'accueil remonté avec la signature **« by foclabroc »**

### 📱 Application
- **Mise à jour intégrée** : l'APK se télécharge dans l'appli (barre de progression, Annuler) puis l'installateur Android s'ouvre — plus besoin de passer par GitHub (lien GitHub en secours)
  - Première fois : autoriser « Installer des applis inconnues » pour Rétro Jump
  - Nouvelle permission `REQUEST_INSTALL_PACKAGES`, dépendance `open_filex`

---

## v1.0.1+2 — Octobre 2026

### 🏆 Progression
- **Niveau joueur (XP)** — chaque partie rapporte de l'XP : 1 XP pour 10 pts, +10 par partie, +25 par défi réussi, +30 pour la partie du jour
  - Niveaux 1 à 99, **rang tous les 10 niveaux** : Débutant → Bronze → Argent → Or → Platine → Diamant → Maître → Légende
  - **Pièces offertes à chaque niveau** (20 × le niveau atteint)
  - Barre de niveau sur l'accueil (touche = page « Gagner de l'XP » + liste des rangs), encadré « +XP / Niveau X atteint ! » en fin de partie
  - Joueurs existants : XP de départ calculée d'après leurs stats à vie (pas de retour à zéro)
- **52 trophées permanents** (bronze, argent, or) — parties, records, points cumulés, bugs écrasés, sauts, turbos, combos, pièces, sacs, logos, temps de jeu, niveau, albums, collection complète, séries de défis, **jours d'affilée**, parties du jour, **podium / 1ʳᵉ place du défi du jour**, premier message dans le chat…
  - Récompense : 25 / 75 / 200 pièces selon la médaille
  - Bouton **🏆 Trophées** dans l'en-tête de l'accueil, page avec progression de chaque trophée
  - Trophées gagnés listés en fin de partie ; ceux gagnés hors partie (achat, chat) annoncés par une notification
  - Joueurs existants : trophées déjà mérités débloqués d'office (sans pièces)

### 🌍 En ligne
- **Chat** (4ᵉ onglet du Classement) — 200 derniers messages, rafraîchi toutes les 8 s, pastille « nouveau message » sur l'accueil
  - Filtre FR/EN des gros mots (même déguisés), liens et numéros de téléphone masqués, 1 message / 10 s
  - **Appui long = signaler** (message masqué pour tous au 3ᵉ signalement), bannissement possible côté serveur
- **Mentions @pseudo** — suggestions de pseudos en tapant `@`, mentions en couleur, message qui te cite encadré, notification « X t'a mentionné » au lancement
- **Fiche joueur** — touche un joueur (classement, partie du jour ou chat) : niveau, rang, pièces, avancement, record et rangs (général, semaine, jour), défis joués / gagnés, toutes les stats de jeu, collection et trophées, date d'inscription
- **Avancement %** de chaque joueur affiché dans le classement : 40 % boutique + 30 % albums + 30 % trophées
- **Pastille de niveau** devant chaque pseudo (classement, chat, fiche)

### 🎨 Interface
- **Accueil fixe**, sans défilement : la scène du héros s'adapte à la taille de l'écran
- Bouton **Jouer** toujours visible, au-dessus de la barre du bas
- En-tête : **Pièces · Trophées · Stats · Son**, avec leur nom sous chaque bouton
- **Version de l'appli** affichée en bas des Réglages + bouton **« Vérifier les mises à jour »**

### 🗄️ Serveur (Supabase) — `supabase_retro_jump.sql` (v9) à relancer
- Colonnes `progress` et `level`, fonction `set_jump_profile`
- Tables `jump_chat`, `jump_chat_reports`, `jump_chat_bans`, `jump_chat_words` (mots filtrés modifiables) + fonctions `send_jump_chat` / `report_jump_chat`
- Stats publiques des joueurs : `set_jump_stats` / `jump_player_card`

---

## v1.0.0+1 — Octobre 2026

Première version de l'application autonome.

### 🎮 Jeu
- Jeu de saut vertical : cartouches normales, mobiles, fissurées, ressorts, bugs à écraser
- Commandes tactiles ou **inclinaison du téléphone**
- Bonus en jeu : turbo, bouclier, aimant, pièces ×2, super saut, ralenti ; **combo** jusqu'à ×5
- Décor qui change tous les 400 pts (château, donjon, temple, glace, volcan, cyber, espace…)
- **Météo dynamique** : vent, pluie, orage (pluie de pièces), brouillard
- Continue une fois par partie, **bonus de départ** (500 / 1 000 pts, bouclier, turbo)

### 🛍️ Boutique
- **12 héros** avec pouvoirs, **12 thèmes** (dont Nuit, Matrix, Réaliste, Tour gelée), **7 musiques**, **6 traînées de saut**
- **Roue de la fortune** : un tour gratuit par jour

### 🏅 Progression
- **Défis** par séries de plus en plus dures, **albums de logos de consoles**, statistiques à vie
- **Sauvegarder / Charger** la progression (fichier dans Téléchargements), identité en ligne comprise : un joueur de Foclabroc Remote retrouve son pseudo et ses scores

### 🌍 En ligne
- **Partie du jour** : même parcours pour tous, choix du héros / décor / musique, rejouable à volonté
- **Classements** défi journalier, semaine et général, avec les pièces des joueurs
- **Fantôme du n°1** et **ligne de record** des autres joueurs pendant la partie
- **Pseudo unique**

### 📱 Application
- Langue automatique **FR / EN** selon le téléphone
- **Vérification des mises à jour** au lancement (GitHub Releases)
- Écran toujours allumé (jeu jouable à l'inclinaison)
