# Prompt : #bonjour — Ouverture de session

Alias principal : `GO JOUR`. Alias historique accepte : `GO BONJOUR`.

## Format de session

- PLANIFICATION : afficher les fichiers lus, la critique ou l'arbitrage requis, le plan d'execution, les agents/skills et les regles appliquees.
- EXECUTION : silence pendant les lectures, commandes et validations reussies; interrompre uniquement en cas de blocage ou d'arbitrage humain.
- FIN EXECUTION : indiquer les fichiers lus et ecrits, documents mis a jour, validations, blocages, actions/decisions humaines et propositions complementaires.

## Protocole

### §0 — Trace d'ouverture immédiate

Avant toute autre action, ajouter une ligne append-only `OPEN` dans `_governance/session-log.md` avec la date, le PC, le projet actif et le hash court de `HEAD`.
Ne jamais exiger une clôture précédente pour ouvrir la session. Si l'écriture échoue, bloquer les actions sensibles et signaler la cause.

### §1 — Synchronisation Git
Pour le projet actif, le dépôt chapeau parent et `modele-copilot` s'ils sont présents : exécuter `git fetch origin`, puis `git pull --ff-only origin main` uniquement si le dépôt est propre.
Si un dépôt est dirty, divergent ou en avance sur origin, bloquer et donner l'action exacte à exécuter par `GO NUIT`.
**Bloquer si conflits non résolus** — ne pas continuer sans résoudre.

```
git fetch origin
git pull origin main
```

### §2 — Vérification session précédente
Lire `_governance/session-log.md` — dernière ligne du **projet actif** (défini comme : workspace racine ou sous-projet VS Code ouvert).
Filtre : chercher dernier commit où colonne PROJET = projet actif courant.
Afficher :
- PC précédent (identifiant)
- Commit hash (pour traçabilité)
- GO SYNC effectué (OUI/NON)
- Statut clôture (CLEAN/WARN)

**Exemple affichage** :
```
ℹ️  Dernière session: PC-A | a3f9c12 | GO SYNC: NON | CLEAN
```

Pour R4, rechercher une ligne `OPEN` du jour pour le projet actif. Une ligne `CLEAN`, `WARN` ou `INTERRUPTED` est écrite seulement par `GO NUIT` et ne constitue pas un prérequis.

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
- Clasp account guardrail manquant
- Token plafond dépassé (signaler et bloquer)

---

## Exécution Recommandée

```
#bonjour → git fetch + pull → lecture session-log → vérif guardrail → rapport
```

**Output cible** : Afficher toutes les 4 étapes dans le rapport final.

Le rapport final contient `Ce que j'ai fait`, `Ce qui marche`, `Ce qui bloque`, `Action / Décision humaine` et `Propositions complémentaires`. Ne pas ajouter `Ce que je fais ensuite`.

Si les scripts workspace sont disponibles, exécuter `validate-copilot-discovery.ps1` et `validate-skill-propagation.ps1` pour le projet actif. Un agent legacy ou un skill plat bloque le démarrage.
