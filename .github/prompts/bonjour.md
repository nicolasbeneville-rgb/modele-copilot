# Prompt : #bonjour — Ouverture de session

## Protocole

### §1 — Synchronisation Git
Exécuter `git fetch origin` puis `git pull` si retard détecté.
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
