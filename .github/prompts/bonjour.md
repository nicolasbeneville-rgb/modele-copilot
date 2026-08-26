# Prompt : #bonjour — Ouverture de session

Alias principal : `GO JOUR`. Alias historique accepte : `GO BONJOUR`.

## Format de session

- PLANIFICATION : afficher les fichiers lus, la critique ou l'arbitrage requis, le plan d'execution, les agents/skills et les regles appliquees.
- EXECUTION : silence pendant les lectures, commandes et validations reussies; interrompre uniquement en cas de blocage ou d'arbitrage humain.
- FIN EXECUTION : indiquer les fichiers lus et ecrits, documents mis a jour, validations, blocages, actions/decisions humaines et propositions complementaires.

## Protocole SPRINT 4 — Multi-PC Synchronisation

### §0 — Lecture du suivi projet

Avant toute autre action, si `projet-status.yaml` existe à la racine du projet :

- Lire `projet-status.yaml`.
- Afficher `next`, les tâches `wip` ou `blocked`, et les blocages.
- Si `ap: ~`, suggérer `@projet-architecte` avant tout nouveau code.
- Si `av: ~` sur une tâche terminée, suggérer `@verification-before-completion`.
- Si `cp: true`, suggérer `@checkpoint-sauvegarde` avant commit ou opération risquée.
- Suggérer seulement : ne jamais invoquer un agent, un push ou un déploiement sans commande explicite.
- Exécuter `_scripts/validate-action-plan.ps1 -ProjectPath . -Phase Pre` si le script est disponible.
- Bloquer la session si le plan est absent ou incomplet.
- Lire la dernière archive dans `_governance/action-plan-history/` ou `docs/project/action-plan-history/` pour reprendre le contexte sans le chat précédent.

### §0 bis — Trace d'ouverture immédiate

Avant `git fetch`, toute vérification ou tout blocage :

1. Capturer la date/heure, le `pc_id`, le projet actif et le hash court de `HEAD` (`NO_COMMIT` si indisponible).
2. Ajouter immédiatement une ligne append-only dans `_governance/session-log.md` :
      `| DATE | PC | PROJET | HASH | N/A | OPEN | GO JOUR ouverture |`
3. Ne jamais exiger une ligne `CLEAN`, `WARN` ou `INTERRUPTED` précédente pour ouvrir la session.
4. Si cette ligne ne peut pas être écrite, bloquer les actions sensibles et signaler la cause.

### §1 — Git Synchronisation + Conflict Resolution

GO BONJOUR contrôle les dépôts nécessaires au projet actif :
- le dépôt du projet ouvert ;
- le dépôt chapeau parent s'il contient `_governance` ;
- `modele-copilot` s'il est présent dans le workspace ou référencé par le gitlink.
Il ne synchronise pas les 15 projets à la place de `GO SYNC`.

**Étapes obligatoires** (aucune sautée):

```
§1.1: Pour chaque dépôt contrôlé, exécuter `git fetch origin`
      → Comparer HEAD local vs origin/main
      → IF retard détecté: continuer à §1.2
      → IF 0 retard: aller à §2

§1.2: Si le dépôt est propre, exécuter `git pull --ff-only origin main`
      → Si le dépôt est dirty: BLOQUER, ne jamais tirer par-dessus les changements locaux
      → Si ZERO conflit: continuer à §1.3
      → Si conflits détectés:
           ⚠️  "[CONFLICT] Fichiers en conflit détectés — résolution requise"
           Afficher liste: git diff --name-only --diff-filter=U
           FOR EACH conflicting file:
             - Lire _governance/git-conflict-priority-rules.md
             - Appliquer règle priorité (SYNC→theirs, LOCAL→ours, APPEND→merge)
             - git add <file>
           - Vérifier: git diff --name-only --diff-filter=U (doit être vide)
           - git status --short (doit afficher "nothing to commit")
           → Si non vide: BLOQUER — "Conflits résiduels non résolus"
           → Si vide: continuer à §1.3

§1.3: Vérifier résultat de chaque dépôt
      - git status: branche propre et à jour avec origin/main
      - Si le dépôt local est en avance sur origin/main: signaler "push requis par GO BONNE NUIT"
      - Si le gitlink racine et HEAD de modele-copilot divergent: BLOQUER et signaler le commit attendu
      - PASS: continuer à §2
      - FAIL: BLOQUER — "git status montre des problèmes"

§1.4: Vérifier le contenu de travail
      - Si les scripts workspace sont disponibles, exécuter `validate-copilot-discovery.ps1` et `validate-skill-propagation.ps1` pour le projet actif
      - Exécuter `validate-powershell-syntax.ps1` si le workspace chapeau est présent
      - Exécuter `validate-clasp-config.ps1` pour les projets GAS avant tout contrôle d'identité
      - Exécuter `validate-vscode-settings.ps1` si la baseline settings est présente; signaler seulement un drift ou un PASS
      - Vérifier `.github/agents/*.agent.md` et `.github/skills/<nom>/SKILL.md`
      - Un skill plat, `ui-ux-pro-max` actif ou un agent legacy est un blocage de synchronisation
```

### §2 — Lecture PC Identity & Session Log

**Objectif** : Identifier qui a modifié quoi et quand

```
§2.1: Vérifier PC Identity
      - Lire _governance/pc-identity.md
      - Extraire pc_id (ex: PC-A, PC-B)
      - Vérifier hostname matches current machine:
        PS: Get-ComputerName vs table
        Mac/Linux: hostname vs table
      - Si mismatch: WARN "⚠️ PC-A used from different hostname"

§2.2: Lire session-log.md — dernière session
      - Filter: PROJET = dossier courant
      - Format: DATE | PC | PROJET | COMMIT | GO SYNC | STATUT | NOTES
      - Afficher dernière entrée:
        ℹ️  "Dernière session: [DATE] | [PC] | [COMMIT] | GO_SYNC: [OUI/NON] | Statut: [CLEAN/WARN]"

§2.3: Détection session interrompue (SPRINT 4 — R6)
      IF dernière entrée:
        - PC ≠ pc_id courant (ex: entrée PC-A, maintenant PC-B):
            → Info "Switching from PC-A to PC-B — verify previous session saved"
        - Statut ≠ CLEAN (ex: WARN, INTERRUPTED, ERROR):
            → Timestamp > 24h:
                🔴 WARN "⚠️ Previous session [PC-X] at [DATE] left as [STATUT] > 24h"
                Suggestion: "Run git status, git log -3, consider git stash if needed"
            → Timestamp ≤ 24h:
                ⚠️  "Previous session [PC-X] at [DATE] incomplete — verify"
        - Si CLEAN: ✅ "Previous session completed successfully"

§2.4: Vérifier contrainte R4 (clasp push blocker)
      - Lire session-log.md
      - Chercher une entrée OPEN pour [PROJET] aujourd'hui (même DATE)
      - Si absent: ⚠️  "⚠️ GO JOUR OPEN absent pour [PROJET] — clasp push BLOCKED jusqu'à ouverture"
      - Si présent: ✅ "clasp push allowed today — OPEN trace found"
      - Ne jamais chercher CLEAN/WARN/INTERRUPTED : ces statuts sont écrits à la clôture.
```

### §3 — Guardrail Clasp Account

Vérifier présence `## Clasp Account Guardrail` dans `.github/copilot-instructions.md`.  
**Si absent** → exécuter `sync-clasp-account-anchors.ps1` en dry-run, puis GO si propre.

**Contrôles de cohérence** :
- ✅ Guardrail présent + compte déclaré
- ✅ Compte LOCAL vs clasp-project-registry.md (autorité): doivent matcher
- 🔴 Compte manquant: BLOQUER
- 🔴 Comptes multiples déclarés: BLOQUER "ambiguïté compte"

### §4 — Rapport État Obligatoire

**Succès** :
```
✅ [PROJET] et dépôts dépendants synchronisés — Commit [HASH] — PC [ID] — Prêt
```

**Avertissements acceptables** :
```
⚠️  [détail] — prêt à continuer (non-bloquant)
```

**Blocages (stop ici)** :
```
🔴 [DÉTAIL] — BLOQUER — Résoudre avant de continuer
```

**Exemples blocages** :
- Conflits Git résiduels
- Trace OPEN absente aujourd'hui (R4)
- Guardrail clasp manquant
- Compte clasp diverge vs registry

**Compte rendu final** :
- `Ce que j'ai fait` : fichiers lus et ecrits, documents mis a jour, validations et cloture du plan.
- `Ce qui marche` : preuves utiles uniquement.
- `Ce qui bloque` : fait, cause, impact et action automatique si un blocage existe.
- `Action / Décision humaine` : action attendue, arbitrage requis ou confirmation qu'aucune validation humaine n'est necessaire.
- `Propositions complémentaires` : automatisations ou ameliorations utiles, sans attente implicite.

---

## Exécution Recommandée

```
#bonjour → git fetch + pull → lecture session-log → vérif guardrail → rapport
```

**Output cible** : Afficher toutes les 4 étapes dans le rapport final.

**Silence d'exécution** : après le plan d'amendement, ne rien afficher pendant les lectures, commandes et validations. Produire uniquement la conclusion finale, sauf blocage nécessitant une décision.

