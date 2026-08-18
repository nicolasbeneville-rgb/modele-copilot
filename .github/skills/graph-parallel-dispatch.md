---
name: graph-parallel-dispatch
description: "Lancer plusieurs tranches de diagnostic ou de codage sur des branches indépendantes en parallèle, avec fusion contrôlée. Utiliser dès que le plan pré-action identifie 2 tranches ou plus sans dépendance mutuelle déclarée dans le découpage CDC."
---

# GRAPH PARALLEL DISPATCH

## Déclenchement

Ce skill est un champ obligatoire du plan pré-action, pas une commande à retenir séparément.
Le plan pose systématiquement : "Ce travail comporte-t-il >=2 tranches indépendantes ? Si oui,
ce skill s'applique avant exécution."

Le champ `parallel_dispatch` ne peut pas être absent ou vide. Il indique `oui` ou `non` et
justifie la décision. Une réponse `oui` doit lister les tranches, leurs dépendances, leurs
fichiers et le point de fusion prévu.

## Découpage éligible

- Diagnostic : toute tranche du CDC, en lecture seule, sans restriction.
- Codage : tranches sans dépendance mutuelle, selon la colonne "Dépend de" du découpage CDC.
- Dans le CDC compact de `projet-status.yaml`, `dep: []` prouve l'absence de dépendance; si `dep` manque ou reste ambigu, la tranche reste en série.
- Une tranche qui amende les fondations (données, messages ou constantes) sort du lot parallèle
  et repasse en série avec toute autre tranche touchant les mêmes fondations, même si le texte
  fusionnerait sans erreur Git.
- Déploiement : toujours en série, aucune exception. Un seul déploiement de production à la fois.

## Isolation

Un worktree Git et une branche sont créés par tranche. Chaque worktree ne touche que les fichiers
attribués à sa tranche. Une tranche qui a besoin d'un fichier de fondations sort du lot et repasse
en série.

## Dispatch

Utiliser le skill `dispatching-parallel-agents` (obra/superpowers) pour lancer les branches.
Chaque branche exécute son propre plan pré-action, y compris les agents pertinents à son périmètre
(`@architecte-api`, `@design-ux`, `@securite-owasp` selon le cas).

Le dispatch ne commence qu'après figer le périmètre exact de chaque tranche dans le CDC et vérifier
qu'aucune dépendance mutuelle n'est déclarée.

## Fusion - point obligatoire, jamais automatique

Avant fusion, exécuter `completion-check` sur chaque branche individuellement, en vérifiant aussi
que le plan de départ (parallèle ou série) a été respecté dans l'exécution réelle.

À la fusion, appliquer le contrôle de cohérence sur les six axes habituels à l'ensemble des branches
fusionnées, pas seulement à chacune isolément.

Un conflit trouvé à la fusion arrête le processus : produire un rapport nominatif des branches en
conflit et ne faire aucune fusion partielle.

## Rapport obligatoire

Le rapport doit indiquer :

- les branches lancées et ce que chacune a produit ;
- le résultat du contrôle de cohérence à la fusion ;
- tout point resté hors parallélisation et pourquoi ;
- tout écart entre le plan et l'exécution détecté par `completion-check`, à transmettre en entrée de
  `#retro`.

## Règle de sortie

Ne jamais paralléliser une tranche si son périmètre exact n'est pas figé dans le CDC. En cas de doute
sur l'appartenance d'un fichier à une tranche, demander avant de lancer et ne jamais deviner.
