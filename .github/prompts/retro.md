# Prompt : #retro — Capture RETRO-MODELE

## Déclenchement
Automatique via #bonne-nuit (étape 6) ou manuel à tout moment.

## Protocole strict
1. Lire docs/retro-modele.md — état actuel de la base.
2. Analyser la session :
   - Fichiers modifiés (git diff --name-only HEAD)
   - Bugs corrigés (.bugdetective/bug-registry.md)
   - Décisions architecture (docs/project/decision-log.md)
3. Pour chaque pattern candidat :
   - Chercher un doublon dans retro-modele.md
   - Si similaire existant, ignorer
   - Si nouveau, rédiger au format standard
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
