# Prompt : #bonne-nuit — Clôture de session

Alias principal : `GO NUIT`. Alias historique accepte : `GO BONNE NUIT`.

## Format de session

- PLANIFICATION : afficher les fichiers lus, la critique ou l'arbitrage requis, le plan d'execution, les agents/skills et les regles appliquees.
- EXECUTION : silence pendant les lectures, commandes et validations reussies; interrompre uniquement en cas de blocage ou d'arbitrage humain.
- FIN EXECUTION : indiquer les fichiers lus et ecrits, documents mis a jour, validations, blocages, actions/decisions humaines et propositions complementaires.

## Protocole SPRINT 4 — Multi-PC End-of-Session

**Objectif** : Clôture complète, multiplateforme, append-only tracing, GO SYNC optionnel  
**Durée estimée** : 10-15 min pour session standard  
**Blocages** : Aucun — tous les points doivent passer avant session-log write

La ligne `OPEN` écrite par `GO JOUR` est la trace d'ouverture. Elle ne doit jamais être remplacée par la ligne de clôture.

---

### §1 — Backup des Fichiers Modifiés

**Étapes**:
```
§1.1: Identifier fichiers modifiés ce jour
      - Exécuter: git diff --name-only HEAD
      - Scope UNIQUE: last commit only (pas session start)
      - Filter OUT: node_modules/, dist/, .git/, .backups/
      - Résultat: liste fichiers à sauvegarder

§1.2: Créer backup avec horodatage
      - Format: .backups/[fichier].[YYYY-MM-DD-HHMM].bak
      - OU créer zip: _checkpoints/backup-[YYYY-MM-DD-HHMM].zip si volume > 5MB
      - Vérifier intégrité: Get-ChildItem .backups/ -Recent
      - Trace: "[OK] X fichiers sauvegardés"

§1.3: Zéro archive hors de cette liste (prévention clutter)
```

### §2 — Build Check & Validation Succès

```
§2.1: Lancer build/validation per project
      - GAS projects: `clasp pull` → vérifier 0 error
      - Node projects: `npm test` ou `npm run lint`
      - Static sites: 0 compilation error
      - Trace: "[OK] Build passed" ou "[WARN] X warnings (non-bloquant)"

§2.2: Signaler blocages
      - IF build FAIL: "[FAIL] Résoudre build error avant push"
      - IF syntax error: "[FAIL] Résoudre syntax error avant push"
      - Continue anyway (non-bloquant pour session-log, mais signal clasp push bloqué)
```

### §3 — Mise à Jour Docs Projet

```
§3.0: Mettre à jour projet-status.yaml si présent
      - Actualiser date_maj, statuts cdc, next et bloquants
      - Renseigner ap, av et cp selon les contrôles réellement exécutés
      - En cas d'incertitude, conserver la tâche en blocked et demander confirmation
      - Ne jamais déclarer done sans preuve de vérification fraîche
      - Renseigner action_plan.status=verified et action_plan.evidence après les contrôles réussis
      - Exécuter `_scripts/validate-action-plan.ps1 -ProjectPath . -Phase Post`
      - Si le gate Post échoue, bloquer la clôture et ne pas déclarer CLEAN
      - Si le plan est verified, exécuter `_scripts/archive-action-plan.ps1 -ProjectPath .`
      - Ne jamais remplacer une archive existante : une archive YAML est créée par plan validé.

§3.1: Vérifier docs impactées (decision-log, architecture-notes)
      - Lire git diff HEAD -- docs/project/
      - Si absent: créer docs/project/decision-log.md si décisions prises
      - Ajouter raison courte des changements
      - Trace: "[OK] Docs updated" ou "[SKIP] Pas de changements doc"

§3.2: Mise à jour roadmap si applicable
      - Si feature complétée: mettre à jour roadmap status
      - Trace: "[OK] Roadmap synced"
```

### §4 — Mise à Jour Decision-Log (Si Applicable)

```
§4.1: Enregistrer décisions architecturales
      - Appendage-only: ne jamais écraser
      - Format: [YYYY-MM-DD] | [sujet] | [décision] | [raison]
      - Exemple: [2026-07-08] | Gestion_Club | Migrer OAuth to 3LO | Scopte réduction
      - Trace: "[OK] Decision recorded" ou "[SKIP] Pas de décision"
```

### §5 — Commit Local Explicite

**⚠️ SPRINT 4 RULE (R2)**: Commit ici, push à l'étape §8

```
§5.1: Préparer message commit
      - Format: [PROJET] description courte (40 chars max)
      - Exemple: [Audit360] Fix OAuth scope validation
      - Ne pas inclure références dépôt (pour re-run multi-PC)

§5.2: Exécuter git commit
      - Déterminer les dépôts concernés : projet actif, modele-copilot si modifié, dépôt chapeau si modifié.
      - Ne jamais utiliser `git add .` depuis un workspace multi-dépôts.
      - Stager uniquement les fichiers du dépôt courant.
      - git commit -m "[PROJET] [description]"
      - Capture hash: git rev-parse --short HEAD
      - Trace: "[OK] Commit: [hash] — [message]"
      - GO NUIT ne committe jamais les fichiers SYNC : `.github/copilot-instructions-commun.md`, les overlays `-gas`/`-react`, `.github/agents/`, `.github/skills/`, `.github/prompts/`, `.github/hooks/` et `_governance/governance-quality-procedure.md`. Ces fichiers appartiennent à GO SYNC.

§5.3: ⚠️ IMPORTANT — Le push se fait à §8, PAS MAINTENANT
      - Commit LOCAL uniquement
      - Non-bloquant si push à §8 échoue (peut être rejeu)
```

### §6 — Invoquer #retro — Pattern Capture

```
§6.1: Exécuter #retro prompt
      - git diff <hash-debut-session>..HEAD --name-only
        (hash-debut-session lu depuis session-log.md dernière entrée #bonjour)
      - Analyser fichiers: bugs corrigés, décisions, patterns
      - Dédupliquer vs retro-modele.md existant
      - Ajouter entrées nouvelles

§6.2: Rapport retro obligatoire
      - "[OK] X entrée(s) ajoutée(s): [titres]"
      - OU "[INFO] 0 nouvelle entrée détectée"
      - Trace obligatoire dans rapport final

§6.3: Agrégation modèle séparée
      - Ne pas lancer GO RETRO MODEL automatiquement depuis chaque projet.
      - Si plusieurs projets ont produit des patterns génériques, proposer le dry-run `_scripts/go-retro-model.ps1` depuis le workspace chapeau.
      - Toute promotion ou propagation reste soumise à revue et GO explicite.
```

### §7 — Décision GO SYNC COPILOT (SPRINT 4 — R7)

**Règle**: Sec ou NO go sans dry-run. Toujours dry-run d'abord.

```
§7.1: Détecter changements _governance/
      - Exécuter: git diff HEAD -- _governance/
      - Résultat: liste fichiers modifiés
      - Si vide → GO SYNC non requis
      - Si non vide → GO SYNC requis

§7.2: Si GO SYNC requis:
      - Trace: "GO SYNC requis: OUI — [raison]"
      - Dry-run: go-sync-copilot-safe.ps1 -DryRun
      - Vérifier output: 0 ERROR, X files to sync
      - Si dry-run échoue: STOP — résoudre avant GO SYNC réel
      - Si dry-run OK: exécuter le sync complet après GO SYNC explicite
      - Ne pas utiliser `-SkipAgents` ou `-SkipSkills` pour la routine GO SYNC
      - Capture output de sync

§7.3: Si GO SYNC non requis:
      - Trace: "GO SYNC requis: NON — [raison]"
      - Continue à §8 (pas de sync)
```

### §8 — Git Push OBLIGATOIRE (R2)

**RÈGLE STRICTE** : Push TOUJOURS, zéro exception

```
§8.1: Exécuter push
      - Pousser chaque dépôt concerné, séparément, après son commit.
      - Ordre si le modèle change : modele-copilot, projet propagé, puis dépôt chapeau/gitlink.
      - git push origin main dans chaque dépôt concerné
      - Vérifier retour: "Everything up-to-date" ou "pushed [hash]"
      - IF push FAIL:
           → Conflict ou network issue
           → Résoudre via git pull + merge manual
           → Re-run git push
           → STOP si 2ème push échoue (resolver hors session)
      - Trace: "[OK] Pushed commit [hash]"
      - GO NUIT ne pousse pas les fichiers SYNC listés à l'étape §5.2 (`.github/copilot-instructions-commun.md`, overlays `-gas`/`-react`, `.github/agents/`, `.github/skills/`, `.github/prompts/`, `.github/hooks/`, `_governance/governance-quality-procedure.md`) ; GO SYNC les committe et les pousse dans sa boucle de gouvernance.

      - Si un dépôt est dirty, divergent ou sans remote : BLOQUER avec le dépôt, la cause et l'action exacte.

§8.2: Confirmer push success
      - git status → "On branch main — up to date with origin/main"
      - MANDATORY avant §9
```

### §9 — Écrire Session-Log (R2, R8)

**Format SPRINT 4 étendu** : DATE | PC | PROJET | COMMIT | GO_SYNC | STATUT | NOTES

```
§9.1: Lire pc_id depuis _governance/pc-identity.md
      - Extract: pc_id field (ex: PC-A, PC-B)
      - Note: Hostneme doit matcher pc-identity (vérification intégrité)

§9.2: Collecter infos session
      - DATE: horodatage clôture (YYYY-MM-DD HH:MM)
      - PC: from pc-identity.md
      - PROJET: dossier courant
      - COMMIT: hash court (7 chars) de §5
      - GO_SYNC: OUI ou NON (de §7)
      - STATUT: CLEAN (tout OK) / WARN (alertes, non-bloquant) / INTERRUPTED (session non complétée)
      - NOTES: optionnel — raison WARN ou INTERRUPTED

§9.3: Append ligne à _governance/session-log.md
      - Ajouter une nouvelle ligne de clôture; ne jamais remplacer la ligne OPEN.
      - Format exact: | [DATE] | [PC] | [PROJET] | [COMMIT_HASH] | [GO_SYNC] | [CLEAN/WARN/INTERRUPTED] | [NOTES] |
      - Exemple: | 2026-07-08 23:15 | PC-A | Webapp_Audit360 | a3f9c12 | NON | CLEAN | |
      - JAMAIS écraser/remplacer — toujours APPEND (append-only)
      - git add _governance/session-log.md
      - git commit -m "[SESSION-LOG] Logged session [PC] [PROJET] [STATUT]"
      - git push origin main

§9.4: Rapport final obligatoire
      ```
      ✅ Session clôturée [PROJET] sur [PC]
      - Commit: [HASH]
      - GO SYNC: [OUI/NON] — [raison]
      - Retro: [X patterns added]
      - Session-log: Enregistré ✓
      ```

      Le rapport final contient :
      - `Ce que j'ai fait` : fichiers lus et ecrits, documents mis a jour, validations et cloture du plan ;
      - `Ce qui marche` : preuves utiles uniquement ;
      - `Ce qui bloque` : fait, cause, impact et action automatique si un blocage existe ;
      - `Action / Décision humaine` : action attendue, arbitrage requis ou confirmation qu'aucune validation humaine n'est necessaire ;
      - `Propositions complémentaires` : automatisations ou ameliorations utiles, sans attente implicite.
      Ne pas ajouter `Ce que je fais ensuite` : les actions automatiques sont déjà exécutées.
```

---

## Error Scenarios & Recovery

| Blocage | Cause | Resolution | Block Session? |
|---------|-------|-----------|--|
| §2 Build FAIL | Syntax/logic error | Fix code + re-test | ⚠️ Signal, not fatal |
| §7 Dry-run FAIL | Script error | Debug GO SYNC script | ❌ BLOCK — resolve |
| §8 Push FAIL | Conflict/network | `git pull` + resolve | ❌ BLOCK — resolve |
| §9 Write FAIL | File locked/permission | Check .backups, .git permissions | ❌ BLOCK — resolve |

---

## Statut Values

| Status | Meaning | Next Action |
|--------|---------|-------------|
| CLEAN | Session fully completed, 0 issues | Normal — ready for next session |
| WARN | Alerts but non-blocking (build warnings, etc.) | Document in NOTES, plan follow-up |
| INTERRUPTED | Session terminated before §9 (crash, manual stop) | Next #bonjour detects, offers recovery |