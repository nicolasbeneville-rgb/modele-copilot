# Prompt : #bonne-nuit — Cloture de session

## Protocole
1. Backup des fichiers modifiés (scope = fichiers listés dans `git diff --name-only <first-commit>..HEAD` depuis début de session).
   - Créer zip ou copier en `_checkpoints/backup-YYYY-MM-DD-HHmm.zip` si volume > 5 MB
   - Note: ne pas inclure node_modules/ ou /dist/ — fichiers sources seuls
2. Build check et validation succes.
3. Mise a jour docs projet impactees.
4. Mise a jour decision-log / roadmap si necessaire.
5. Commit local explicite (commit message en clair — contenu jour).
   **Note** : le `git push` est exécuté à l'étape 8 (pas ici). Commit sans push temporairement OK.
6. RETRO-MODELE : invoquer `#retro`.
   Analyser la session, dedupliquer, ajouter les nouveaux patterns.
   Rapport obligatoire avant de clore la session.
7. Checklist GO SYNC COPILOT (decision):
   - Lancer GO SYNC si la couche modele/gouvernance a change (instructions, agents, skills, prompts).
   - Lancer GO SYNC si un projet est desynchronise ou vient d'etre ajoute.
   - Ne pas lancer GO SYNC si aucun asset mutualise n'a ete modifie.
   - Toujours utiliser le mode safe sync (dry-run puis execution reelle si dry-run propre).

8. Git push OBLIGATOIRE (zéro exception) :
   Exécuter `git push origin main` — confirmer retour "Everything up-to-date" ou "pushed".
   Si push échoue → résoudre conflit ou blocage avant de clore la session.
   **Trace** : Noter le hash du dernier commit avant push (pour session-log).

9. Écrire ligne dans `_governance/session-log.md` (append-only) :
   Format: `DATE | PC | PROJET | COMMIT_HASH | GO_SYNC (OUI/NON) | STATUT`
   Exemple : `2026-07-08 18:45 | PC-NICOLAS | Webapp_Audit360 | a3f9c12 | NON | CLEAN`
   **Statut** : CLEAN (sans problème), WARN (alertes non-bloquantes)

**Ligne de trace obligatoire dans rapport final** :
   - `GO SYNC requis: OUI` ou `GO SYNC requis: NON`
   - Ajouter raison courte
   - `Session-log entry: [ligne écrite]`
