# Prompt : #bonjour — Ouverture de session

Alias principal : `GO JOUR`. Alias historique accepte : `GO BONJOUR`.

## Format de session

- PLANIFICATION : afficher les fichiers lus, la critique ou l'arbitrage requis, le plan d'execution, les agents/skills et les regles appliquees.
- EXECUTION : silence pendant les lectures, commandes et validations reussies; interrompre uniquement en cas de blocage ou d'arbitrage humain.
- FIN EXECUTION : indiquer les fichiers lus et ecrits, documents mis a jour, validations, blocages, actions/decisions humaines et propositions complementaires.

## Protocole

### §0 — Lecture du suivi projet
Avant toute autre action, si `projet-status.yaml` existe à la racine du projet :
- Lire `projet-status.yaml`, afficher `next`, les tâches `wip`/`blocked` et les blocages.
- Si `ap: ~`, suggérer `@projet-architecte` ; si `av: ~` sur une tâche terminée, suggérer `@verification-before-completion` ; si `cp: true`, suggérer `@checkpoint-sauvegarde` avant commit ou opération risquée. Suggérer seulement, jamais invoquer sans commande explicite.
- Exécuter `_scripts/validate-action-plan.ps1 -ProjectPath . -Phase Pre` si disponible. Bloquer la session si le plan est absent ou incomplet.
- Lire la dernière archive dans `_governance/action-plan-history/` ou `docs/project/action-plan-history/` pour reprendre le contexte.

### §0 bis — Trace d'ouverture immédiate
Avant `git fetch`, toute vérification ou tout blocage : ajouter une ligne append-only `OPEN` dans `_governance/session-log.md` avec date, PC, projet actif, hash court de HEAD (`NO_COMMIT` si indisponible). Ne jamais exiger une clôture précédente pour ouvrir la session. Si l'écriture échoue, bloquer les actions sensibles et signaler la cause.

### §1 — Synchronisation Git
Pour le projet actif, le dépôt chapeau parent et `modele-copilot` s'ils sont présents : `git fetch origin`, puis `git pull --ff-only origin main` uniquement si le dépôt est propre.
Si un dépôt est dirty, divergent ou en avance sur origin, bloquer et donner l'action exacte (push par `GO NUIT`).
Si le gitlink racine et le HEAD de `modele-copilot` divergent, bloquer et signaler le commit attendu.
**Bloquer si conflits non résolus** — résolution via `_governance/git-conflict-priority-rules.md` (SYNC→theirs, LOCAL→ours, APPEND→merge), jamais continuer sans résoudre.

```
git fetch origin
git pull origin main
```

### §2 — Vérification session précédente
Lire `_governance/pc-identity.md`, extraire `pc_id`, vérifier que le hostname courant correspond ; signaler un mismatch en WARN.
Lire `_governance/session-log.md` — dernière ligne du projet actif. Afficher PC précédent, commit hash, GO SYNC (OUI/NON), statut clôture (CLEAN/WARN).

**Exemple affichage** :
```

ℹ️  Dernière session: PC-A | a3f9c12 | GO SYNC: NON | CLEAN

```
Si le PC diffère du précédent, informer du changement de poste et suggérer de vérifier que la session précédente a bien été sauvegardée. Si le statut précédent n'est pas CLEAN et date de plus de 24h, WARN et suggérer `git status`/`git log -3`/`git stash` si besoin ; si moins de 24h, signaler simplement l'incomplétude.
Pour R4, rechercher une ligne `OPEN` du jour pour le projet actif — une ligne `CLEAN`/`WARN`/`INTERRUPTED` est écrite seulement par `GO NUIT` et ne constitue pas un prérequis.

### §3 — Guardrail Clasp Account
Vérifier présence `## Clasp Account Guardrail` dans `.github/copilot-instructions.md`.
**Si absent** → exécuter `sync-clasp-account-anchors.ps1` en dry-run, puis GO si propre.

**Signaux**:
- ✅ Guardrail present + account declared = prêt
- ⚠️  Guardrail absent = lancer sync
- 🔴 Multiple accounts declared = bloquer, conflit

### §4 — Rapport état obligatoire

**Succès** :
```

✅ Workspace synchronisé — [PROJET_MAIN] — commit [hash] — prêt

```
**Problème** :
```

⚠️  [PROBLÈME DÉTECTÉ] — [description courte] — action requise avant de continuer

```
**Blocages possibles** :
- Conflits Git non résolus
- Trace OPEN absente aujourd'hui (R4)
- Guardrail clasp manquant ou compte divergent vs registry
- Gitlink racine et HEAD `modele-copilot` divergents
- Token plafond dépassé (signaler et bloquer)

---

## Exécution Recommandée
```

#bonjour → git fetch + pull → lecture session-log → vérif guardrail → rapport

```
**Output cible** : Afficher toutes les 4 étapes dans le rapport final.

Le rapport final contient `Ce que j'ai fait`, `Ce qui marche`, `Ce qui bloque`, `Action / Décision humaine` et `Propositions complémentaires`. Ne pas ajouter `Ce que je fais ensuite`.

Si les scripts workspace sont disponibles, exécuter `validate-copilot-discovery.ps1`, `validate-skill-propagation.ps1`, `validate-powershell-syntax.ps1` (si le workspace chapeau est présent) et `validate-clasp-config.ps1` pour les projets GAS avant tout contrôle d'identité. Exécuter `validate-vscode-settings.ps1` si la baseline settings est présente, signaler seulement un drift ou un PASS. Un agent legacy ou un skill plat actif bloque le démarrage.
