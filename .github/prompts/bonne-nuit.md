# Prompt : #bonne-nuit — Cloture de session

## Protocole
1. Backup des fichiers modifies du jour.
2. Build check et validation succes.
3. Mise a jour docs projet impactees.
4. Mise a jour decision-log / roadmap si necessaire.
5. Commit local explicite (sans push/deploy sans GO).
6. RETRO-MODELE : invoquer `#retro`.
   Analyser la session, dedupliquer, ajouter les nouveaux patterns.
   Rapport obligatoire avant de clore la session.
7. Checklist GO SYNC COPILOT (decision):
   - Lancer GO SYNC si la couche modele/gouvernance a change (instructions, agents, skills, prompts).
   - Lancer GO SYNC si un projet est desynchronise ou vient d'etre ajoute.
   - Ne pas lancer GO SYNC si aucun asset mutualise n'a ete modifie.
   - Toujours utiliser le mode safe sync (dry-run puis execution reelle si dry-run propre).
8. Ligne de trace obligatoire dans le rapport final:
   - `GO SYNC requis: OUI` ou `GO SYNC requis: NON`
   - Ajouter une raison courte sur la ligne suivante.
