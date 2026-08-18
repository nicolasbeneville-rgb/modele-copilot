---
name: doc-cleanup
description: "Audit project documentation for obsolete, duplicated or unreferenced files. Use before a documentation refactor or governance sync. Never delete automatically."
---

# Doc cleanup

## Inventaire

Scanner les dossiers indiqués et relever :
- noms `backup`, `old`, `v1`, `copy`, `tmp`, `draft` ou dates anciennes ;
- fichiers non référencés par les instructions, README ou règles projet ;
- doublons de titre ou de contenu ;
- stubs de moins de cinq lignes non vides.

## Rapport

Pour chaque fichier suspect, produire :

| Fichier | Preuve | Verdict |
|---|---|---|
| <path> | <référence ou absence de référence> | GARDER / ARCHIVER / SUPPRIMER / DEMANDER |

Ne jamais classer un fichier comme obsolète uniquement à cause de son âge.

## Exécution

- Présenter la liste complète avant toute suppression.
- Attendre un GO explicite, fichier par fichier ou `GO TOUT`.
- Ne jamais supprimer `decision-log.md`, `operating-rules.md`, les sources canoniques ou les backups sans validation.
- Préférer l'archivage dans `.backups/` quand la valeur historique n'est pas certaine.
- Après exécution, lancer `#doc-sync` et vérifier les références mortes.
