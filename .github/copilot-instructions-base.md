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
- Séquence obligatoire : `clasp push` → `clasp version "<desc>"` → `clasp deploy -i <ID> -V <num> -d "<desc>"`
- Interdiction de laisser la prod sur @HEAD.
- Zéro déploiement sans GO explicite textuel de l'utilisateur.

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
