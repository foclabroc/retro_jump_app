# Changelog — Rétro Jump 🚀

Historique des versions de l'application autonome (le jeu existe aussi dans [Foclabroc Remote](https://github.com/foclabroc/foclabroc-remote), avec le même classement).

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
