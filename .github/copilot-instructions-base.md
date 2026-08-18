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
- Un compte-rendu abrégé ne valide pas un GO BONNE NUIT : commit, push et session-log doivent être effectivement exécutés.

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
