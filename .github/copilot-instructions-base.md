# Règles Globales — Socle Commun Tous Projets
# Source de vérité : PROJETS_APP_SCRIPT/_governance/core/
# Ne pas modifier directement dans les sous-projets.

## 🔒 Sécurité Critique (Priorité absolue)

### Secrets
- Interdiction absolue de hardcoder clés, tokens, mots de passe.
- Utiliser exclusivement le mécanisme de secret adapté au stack et documenté dans le projet.

## 🚀 Déclencheurs de session (alias GO)
- `GO BONJOUR` = exécuter strictement `.github/prompts/bonjour.md`.
- `GO BONNE NUIT` = exécuter strictement `.github/prompts/bonne-nuit.md` (§1 à §9), puis l'étape 6 déclenche `#retro`.
- `GO RETRO` = exécuter directement `#retro` dans le projet courant.
- `GO RETRO MODEL` = lancer `_scripts/go-retro-model.ps1` en dry-run, puis `-Execute` après revue explicite des candidats.
- Les prompts requis sont `.github/prompts/bonjour.md`, `.github/prompts/bonne-nuit.md` et `.github/prompts/retro.md`.
- Overlay appliqué = signature détectée automatiquement : `.clasp.json` = GAS, `package.json` avec `react` = front. Ne jamais se fier à un choix manuel non documenté.
- GO JOUR (alias GO BONJOUR) ajoute immédiatement une trace `OPEN` append-only; GO NUIT (alias GO BONNE NUIT) ajoute ensuite une ligne `CLEAN`, `WARN` ou `INTERRUPTED`.
- R4 vérifie la trace `OPEN` du jour, jamais une clôture préalable.
- GO BONJOUR garantit le démarrage propre : fetch/pull ff-only du dépôt actif, du chapeau et de modele-copilot si présents; discovery et skills sont contrôlés avant travail.
- GO JOUR utilise `validate-powershell-syntax.ps1` quand le script est disponible; préférer un script aux commandes inline complexes.
- GO JOUR utilise `validate-clasp-config.ps1` avant le contrôle d'identité clasp.
- GO BONNE NUIT garantit la disponibilité multi-PC : commit/push séparé de chaque dépôt concerné et vérification finale des remotes.
- Tout plan `verified` est archivé en YAML; GO JOUR lit la dernière archive avant de reprendre un projet.
- Les seules routines obligatoires sont GO NEW, GO BONJOUR, GO BONNE NUIT et GO SYNC.
- GO SYNC utilisateur est complet : ne pas utiliser `-SkipAgents` ou `-SkipSkills`.
- GO PUSH reste une publication Apps Script ponctuelle, hors routine quotidienne.
- Compte rendu final : `Ce qui marche`; `Ce qui pose problème` seulement si nécessaire; `Ce qu'il faut trancher` pour les décisions utilisateur uniquement.
- Pour chaque problème : fait, cause, impact, action automatique, action utilisateur éventuelle, arbitrage, question exacte et conséquence sans réponse.
- Ne jamais écrire `Ce que je fais ensuite` : les actions automatiques sont exécutées pendant la tâche.
- Une tâche suit ce format : plan d'amendement unique, exécution silencieuse, conclusion avec preuves et décisions restantes.
- Aucun message intermédiaire pour les lectures, commandes ou validations réussies; interrompre seulement en cas de blocage ou de décision utilisateur.
- GO JOUR et GO NUIT : après le plan initial, silence total pendant l'exécution; la conclusion finale est le seul compte rendu, sauf blocage réel.

## 🔁 Multi-PC — Synchronisation Git
- Fin de session : `git push origin` SYSTÉMATIQUEMENT après le commit.
- Début de session : `git fetch origin` puis `git pull` si retard détecté.
- Le session-log reste append-only et s'écrit via `#bonne-nuit`.

## 📦 Backup — Convention Unique
- Format : `.backups/nom-fichier.YYYY-MM-DD.bak`
- Destination : dossier `.backups/` à la racine du sous-projet concerné.
- Interdiction de créer des dossiers `.backup-YYYY-MM-DD` à la racine.

## 🛠️ Diagnostic & Read-First
- Lire le fichier avant toute modification. Zéro supposition.
- Résumer (cause + preuve + but) avant de toucher un fichier.
- Corrections réversibles en priorité.

## 🧭 Plan pré-action
- Tout plan comporte `parallel_dispatch` avec une réponse `oui` ou `non` et sa justification.
- Si le CDC contient au moins deux tranches indépendantes, appliquer `graph-parallel-dispatch` avant l'exécution.
- Les fondations partagées et les déploiements restent en série; aucune fusion parallèle n'est automatique.

## 🪙 Token Optimization
- Éditions chirurgicales uniquement. Jamais de réécriture complète.
- Utiliser des snippets avant/après avec `// ... reste inchangé ...`
