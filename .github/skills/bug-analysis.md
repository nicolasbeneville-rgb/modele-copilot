---
name: bug-analysis
description: >
  Analyse méthodique d'un bug avant correction. Force la recherche de cause racine, 
  la comparaison avec backups/git, la consultation du registre des bugs connus.
  Invoque quand un bug est signalé et que la cause n'est pas évidente.
  NE PAS utiliser pour : typos, changements CSS cosmétiques, ajouts de features.
applyTo: "**"
---

# Skill : Bug Analysis (BugDetective)

## Principe
Interdiction de patcher sans analyse préalable. Un patch sans compréhension crée de nouveaux bugs.

## Niveaux de sévérité

### Niveau 1 — RAPIDE (bug CSS, typo, erreur simple évidente)
1. Lire le fichier concerné
2. Identifier la ligne fautive
3. Corriger
4. Build check (commande projet)
5. Ajouter une entrée courte dans `.bugdetective/bug-registry.md`

### Niveau 2 — STANDARD (comportement cassé, widget qui ne s'affiche plus, erreur RPC)
1. **Comparer** avec le dernier fichier `.backup-*` correspondant OU `git diff`
2. **Consulter** `.bugdetective/bug-registry.md` pour des bugs similaires
3. **Identifier** la cause racine (pas le symptôme)
4. **Rapport léger** :
   ```
   📍 Fichier : [chemin]
   🧬 Cause : [explication courte]
   🔄 Diff clef : [ce qui a changé]
   📚 Bug similaire : [ref ou "aucun"]
   ```
5. Corriger uniquement ce qui est lié à la cause racine
6. Build check
7. Mettre à jour le registre

### Niveau 3 — CRITIQUE (perte de données, erreur serveur bloquante, page blanche)
Workflow complet obligatoire :

#### Passe 1 — Analyse (OBLIGATOIRE avant tout code)
1. `git status` + `git diff HEAD`
2. `git log --oneline -10 [fichier]`
3. Comparer avec le backup le plus récent si disponible
4. Lire `.bugdetective/bug-registry.md`
5. Identifier le commit/changement fautif
6. Si besoin de logs diagnostiques (temporaires) :
   - Backend : logs serveur adaptés au framework
   - Frontend : `console.log('[BD] ...');`

#### Passe 2 — Rapport (OBLIGATOIRE avant correction)
```
🔍 RAPPORT BUGDETECTIVE
━━━━━━━━━━━━━━━━━━━━━━━
📍 Fichier(s) : [chemin]
📍 Ligne(s) : [numéros]
🧬 Cause racine : [hypothèse + confiance %]
🔄 Changement fautif : [description du diff]
📚 Bug similaire : [ref registre ou "aucun"]
⚠️ Risque patch rapide : [pourquoi c'est risqué]
🎯 Point de restauration : [backup ou commit]
```

#### Passe 3 — Correction (après validation utilisateur)
1. Demander confirmation : "Hypothèse [X] confirmée ? Procéder ?"
2. Corriger UNIQUEMENT la cause racine. Pas d'améliorations opportunistes.
3. Build check
4. Supprimer les logs `[BD]` temporaires
5. Mettre à jour `.bugdetective/bug-registry.md`

## Règles inviolables
- **ANTI-PATCH-REFLEX** : Pas de code correctif sans avoir identifié la cause racine.
- **ANTI-SCOPE-CREEP** : Ne modifier que ce qui est lié au bug signalé.
- **ANTI-HALLUCINATION** : Toujours lire le fichier réel avant d'en parler.
- **BUILD OBLIGATOIRE** : La commande de build projet doit passer après chaque fix.
- **REGISTRE** : Tout bug résolu → entrée dans `.bugdetective/bug-registry.md`.

## Format d'entrée registre
```markdown
## BUG-[DATE]-[NUMÉRO]
**Fichier :** [chemin]
**Symptôme :** [description]
**Cause racine :** [explication]
**Correction :** [description courte]
**Version fix :** [version/commit]
**Date :** [date]
```

## Contexte technique projet (À ADAPTER au kickoff)
- Backend : `[STACK_BACKEND]`
- Frontend : `[STACK_FRONTEND]`
- Build : `[BUILD_COMMAND]`
- Tests : `[TEST_COMMAND ou "aucun"]`
- Déploiement : `[DEPLOY_COMMAND]` (ne JAMAIS exécuter sans GO explicite)
- Backups : `[BACKUP_PATTERN ou "git uniquement"]`

## Expert Execution Standard
- Toute hypothèse doit être falsifiable et liée à une preuve locale.
- Si le bug touche l'UI, vérifier aussi la structure HTML/composant, l'accessibilité, et les effets de performance avant de conclure.
- Refuser les "fixes" qui déplacent simplement le symptôme avec du CSS arbitraire ou des conditions ad hoc.
