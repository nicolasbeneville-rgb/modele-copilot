# Prompt : #retro — Capture RETRO-MODELE

## Déclenchement
Automatique via #bonne-nuit (étape 6) ou manuel à tout moment.

## Protocole strict
1. Lire docs/retro-modele.md — état actuel de la base.
2. Analyser la session :
   - Fichiers modifiés: `git diff --name-only <first-session-commit>..HEAD` (capture entière de session, pas juste dernier commit)
   - Bugs corrigés (.bugdetective/bug-registry.md ou session notes)
   - Décisions architecture (docs/project/decision-log.md)
3. Pour chaque pattern candidat :
   - Chercher un doublon dans retro-modele.md
   - Si similaire existant, ignorer
   - Si nouveau, rédiger au format standard
   - **M5 FIX — Sélection section appropriée**:
     * Bug GAS (closure, Apps Script runtime) → "GAS — Pièges spécifiques"
     * Sécurité (access scope, secrets) → "Sécurité & Robustesse"
     * Déploiement (versioning, quotas) → "Déploiement & Versioning"
     * Performance (optimization) → "Performance & UI"
     * Gouvernance (process, workflow) → "Gouvernance & Scripts"
4. Ajouter dans la section appropriée de retro-modele.md.
5. Rapport final obligatoire :
   "[N] entrée(s) ajoutée(s) : [titres]" ou "Aucune nouvelle entrée détectée"

## Format entrée standard
- **[Titre pattern] :** [Contexte — 1 phrase].
  [Règle actionnable].
  (*[Projet] — [YYYY-MM-DD]*)

## Sections disponibles
- Gouvernance & Scripts
- GAS — Pièges spécifiques
- Sécurité & Robustesse
- Performance & UI
- Déploiement & Versioning