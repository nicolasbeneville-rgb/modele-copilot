# Règles Globales — Socle Commun Tous Projets
# Source de vérité : PROJETS_APP_SCRIPT/_governance/
# Ne pas modifier directement dans les sous-projets.

## 🔒 Sécurité Critique (Priorité absolue)

### Secrets
- Interdiction absolue de hardcoder clés, tokens, mots de passe.
- Utiliser exclusivement `PropertiesService.getScriptProperties()`.

### appsscript.json — Règle de vigilance
- Toute modification déclenche un avertissement obligatoire :
  "⚠️ Ce fichier contrôle les permissions OAuth et l'accès public.
   `access: ANYONE` = accessible sans authentification.
   `executeAs: USER_DEPLOYING` = s'exécute avec les droits du déployeur.
   Confirmer la modification ?"
- Ne jamais élargir les oauthScopes sans GO explicite de l'utilisateur.

### UrlFetchApp — Traçabilité obligatoire
- Toute utilisation doit être précédée du commentaire :
  `// EXTERNAL_REQUEST: [URL cible] — validé par utilisateur le [YYYY-MM-DD]`

## 🚀 Déploiement Versionné (Non négociable)
- Problème : Google Apps Script limite chaque projet à 20 déploiements versionnés. Tout `clasp deploy` sans `-i` crée un nouveau déploiement et consomme ce quota.
- Principe : conserver un seul déploiement de production par projet et le mettre à jour à chaque nouvelle version.
- Interdiction de créer un nouveau déploiement de prod si un ID de prod existe déjà.
- Interdiction de laisser la prod sur `@HEAD`.
- Zéro déploiement sans GO explicite textuel de l'utilisateur.

### Trouver l'ID de production (une seule fois par projet)
- Exécuter `clasp deployments`.
- Identifier la ligne du déploiement de production actif (description la plus récente et significative).
- Conserver l'identifiant de déploiement commençant par `AKfyc...`.
- Documenter cet ID dans `instructions.md` ou `copilot-instructions.md` du projet.

### Séquence obligatoire à chaque GO PUSH
- `clasp push --force`
- `clasp version "<desc>"`
- `clasp deploy -i <DEPLOYMENT_ID_PROD> -V <versionNumber> -d "<desc>"`
- Vérifier que l'URL Web App de prod n'a pas changé.

### Déclencheurs de session (alias GO)
- `GO BONNE NUIT` = exécuter `#bonne-nuit`, puis l'étape 6 déclenche `#retro`.
- `GO RETRO` ou `GO RETRO MODEL` = exécuter directement `#retro`.
- Les prompts requis sont `.github/prompts/bonne-nuit.md` et `.github/prompts/retro.md`.

## 🔁 Multi-PC — Synchronisation Git
- Fin de session : `git push origin` SYSTÉMATIQUEMENT après le commit.
- Début de session : `git fetch origin` puis `git pull` si retard détecté.
- ⚠️ Distinction obligatoire :
  - `git push` = sauvegarde code sur remote = TOUJOURS en fin de session.
  - `clasp deploy` = déploiement production GAS = GO explicite requis.
  Ces deux actions sont totalement indépendantes.

## 📦 Backup — Convention Unique
- Format : `.backups/nom-fichier.YYYY-MM-DD.bak`
- Destination : dossier `.backups/` à la racine du sous-projet concerné.
- Interdiction de créer des dossiers `.backup-YYYY-MM-DD` à la racine.

## 🛠️ Diagnostic & Read-First
- Lire le fichier avant toute modification. Zéro supposition.
- Résumer (cause + preuve + but) avant de toucher un fichier.
- Corrections réversibles en priorité.

## 🪙 Token Optimization
- Éditions chirurgicales uniquement. Jamais de réécriture complète.
- Utiliser des snippets avant/après avec `// ... reste inchangé ...`
