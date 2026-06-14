---
name: verification-before-completion
description: >
  Forcer une vérification avant de déclarer un travail terminé, corrigé ou passant.
  Utiliser avant de committer, créer une PR, ou affirmer qu'un bug est résolu.
  Principe : preuve avant affirmation, toujours. Pas d'exception.
  Source : obra/superpowers (MIT, v5.1)
applyTo: "**"
---

# Verification Before Completion

## Principe fondamental

Affirmer qu'un travail est terminé sans vérification = mensonge, pas efficacité.

```
AUCUNE AFFIRMATION DE COMPLÉTION SANS PREUVE DE VÉRIFICATION FRAÎCHE
```

## La fonction de contrôle (Gate)

```
AVANT de revendiquer un statut ou d'exprimer de la satisfaction :

1. IDENTIFIER : Quelle commande prouve cette affirmation ?
2. EXÉCUTER : Lancer la commande COMPLÈTE (fraîche, dans ce message)
3. LIRE : Sortie complète, code de retour, compter les échecs
4. VÉRIFIER : La sortie confirme-t-elle l'affirmation ?
   - Si NON : Déclarer le statut réel avec preuves
   - Si OUI : Déclarer avec preuves
5. SEULEMENT ALORS : Faire l'affirmation

Sauter une étape = mentir, pas vérifier.
```

## Échecs courants

| Affirmation | Requiert | Insuffisant |
|-------------|----------|-------------|
| Build OK | Commande build : exit 0 | "Le linter passe" |
| Bug corrigé | Test du symptôme original : passe | "Code modifié, devrait marcher" |
| Tests passent | Sortie test : 0 échecs | Run précédent, "devrait passer" |
| Exigences remplies | Checklist ligne par ligne | "Les tests passent" |
| Régression couverte | Cycle red-green vérifié | "J'ai écrit un test" |

## Red Flags — STOP

- Utiliser "devrait", "probablement", "semble"
- Exprimer de la satisfaction AVANT vérification ("Super !", "Parfait !", "Fait !")
- Sur le point de commit/push/PR sans vérification
- Se fier à des rapports de réussite d'agent sans vérifier
- Penser "juste cette fois"
- **TOUT wording impliquant un succès sans avoir exécuté la vérification**

## Prévention des rationalisations

| Excuse | Réalité |
|--------|---------|
| "Devrait marcher maintenant" | EXÉCUTER la vérification |
| "Je suis confiant" | Confiance ≠ preuve |
| "Juste cette fois" | Pas d'exception |
| "Le linter passe" | Linter ≠ build ≠ test fonctionnel |
| "L'agent dit succès" | Vérifier indépendamment |
| "Vérification partielle suffit" | Partiel ne prouve rien |

## Patterns corrects

**Build :**
```
✅ [Exécuter build] → [Voir: exit 0] → "Build OK"
❌ "Devrait builder" / "Le code est correct"
```

**Bug fix :**
```
✅ [Exécuter build/test] → [Voir: passe] → "Bug corrigé"
❌ "J'ai modifié la ligne, c'est réglé"
```

**Exigences :**
```
✅ Relire le plan → Créer checklist → Vérifier chaque point → Rapport
❌ "Tests passent, phase terminée"
```

## Quand appliquer

**TOUJOURS avant :**
- Toute affirmation de succès/complétion
- Toute expression de satisfaction sur l'état du travail
- Commit, PR, déploiement
- Passage à la tâche suivante
- Dire "bonne nuit" / fin de session

## La règle absolue

**Pas de raccourci pour la vérification.**

Exécuter la commande. Lire la sortie. ALORS seulement affirmer le résultat.

Non négociable.

## Expert Execution Standard
- If the work includes UI or frontend changes, verification must also include a textual structural check of the DOM/component tree and a WCAG-oriented review of labels, focus, contrast, and reduced motion.
- If the work includes visual layout guidance, provide a text layout plan before declaring the design valid.
- Never accept a design as "done" if it still depends on arbitrary absolute coordinates or undocumented raw CSS for core layout.
