---
name: programme-recette
description: "Generate a functional acceptance plan with scenarios, exit criteria and a receipt for a Google Apps Script webapp. Use before delivery or GO PUSH."
---

# Programme de recette

## Quand l'utiliser

- Avant une livraison métier ou un GO PUSH.
- Après une correction critique.
- Pour une recette fonctionnelle, de regression, smoke ou complete.

La recette utilise `_governance/test-matrix-template.md` comme structure de base
et adapte les scénarios au produit, à la version testée et au rôle de l'acteur.

## Contexte obligatoire

Demander si absent :
- périmètre et fonctionnalité couverte ;
- type de recette et acteur ;
- URL d'une version déployée, jamais `@HEAD` ;
- version clasp testée ;
- données de test et résultat attendu.

## Sortie

Créer `docs/recette/programme-recette-<fonctionnalite>-<YYYY-MM-DD>.md` avec :

```markdown
# Programme de recette — <Fonctionnalité>
Version testée : <version>
URL : <url>
Date : <YYYY-MM-DD>
Acteur : <rôle>

## Scénarios
| ID | Priorité | Prérequis | Étapes | Résultat attendu | Statut |
|---|---|---|---|---|---|
| S01 | P0 | <conditions> | 1. ... | <résultat mesurable> | ⬜ |

## Critères de sortie
- [ ] Tous les scénarios P0 sont réussis.
- [ ] Aucun échec critique dans les logs.
- [ ] URL et scopes confirmés.

## PV
Résultat : ☐ GO ☐ NO-GO ☐ GO avec réserves
Réserves :
Signature / date :
```

## Règles

- P0 bloque la livraison ; P1 est important ; P2 est optionnel.
- Couvrir au minimum l'accès, les droits, l'écriture et les appels externes si présents.
- Ajouter les dimensions fonction, UX/accessibilité, sécurité, messages, performance, régression et rollback selon le périmètre.
- Ne jamais écrire un scénario vague.
- Un NO-GO est listé avec l'ID du scénario et la preuve.
- Ce skill prépare la recette métier ; `@verification-before-completion` reste l'agent de preuve technique et `#completion-check` fournit la checklist à la demande.
