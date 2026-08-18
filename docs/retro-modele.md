# RETRO-MODELE — Base centrale du workspace
# Alimentee par GO RETRO MODEL apres dry-run et revue explicite.
# Les retro locales restent dans chaque projet.

---

## Gouvernance & Scripts

- **Registre central des comptes clasp :** Quand plusieurs projets GAS coexistent dans un meme workspace, centraliser le type de compte `clasp` attendu (`PRO` ou `PERSO`) dans un registre unique puis propager les ancrages par script safe.
	Conserver `_governance/clasp-project-registry.md` comme source de verite, injecter la regle dans `.github/copilot-instructions.md` et `docs/project/operating-rules.md`, puis brancher ce controle dans `GO SYNC COPILOT`.
	(*modele-copilot — 2026-06-30*)


- **Recalculer contexte mobile à chaque changement de club:** recalculer le contexte utilisateur (modules, badges, statuts) à chaque changement de club via un endpoint dédié, plutôt que réutiliser un contexte global.
  un utilisateur multi-rôles (admin global + enseignant local) ne peut pas reutiliser un contexte global sans risque de mélanger les rôles et visibilités.
  (*Webapp_Gestion_Club - 2026-06-15*)
---

## GAS — Pièges spécifiques


- **Fallback UserProperties pour erreurs Sheet:** implémenter un fallback sur UserProperties quand l'accès ou le quota Sheet refuse une écriture.
  conserver l'état utilisateur et documenter la règle de cohérence et de réinitialisation.
  (*Book_Nils; Webapp_Pilotage_Contrat - 2026-06-15*)
---

## Sécurité & Robustesse


- **Gouvernance Copilot standardisée:** importer la couche .github (agents, skills) et docs de gouvernance depuis le modèle centralisé pour tous les projets.
  standardiser le pilotage, la sécurité et la traçabilité; hériter des guardrails et bonnes pratiques.
  (*Book_Nils - 2026-06-15*)

- **Sécurité : actions sensibles en POST:** garder GET en lecture seule et déplacer approbation, publication et changement d'état vers POST avec confirmation explicite.
  éviter appels accidentels via prefetch, bots ou bookmarks; garantir une intention utilisateur claire.
  (*Webapp_Gestion_Club; Webapp_Pilotage_Contrat - 2026-06-15*)

- **Sécurité : XSS sur filtres dynamiques:** valider/échapper toutes les données lors de création dynamique de filtres HTML.
  éviter injection XSS sur génération d'éléments avec contenu utilisateur.
  (*Webapp_Harmonisation - 2026-06-15*)

---

## Performance & UI


- **Éviter les modifications de schéma Sheet lors de lectures simples:** ne jamais appeler des fonctions d'ajout de colonne (ensureColumn, etc.) lors d'une simple lecture de données ; isoler les modifications en init ou admin.
  les erreurs de permission Google Sheet sur modification bloquent même les lectures ultérieures.
  (*Webapp_Pilotage_Contrat - 2026-06-15*)

- **Lazy-load des widgets/modules fermés au démarrage:** différer le rendu et le chargement des sections UI non visibles au démarrage ; charger à la demande à l'ouverture utilisateur.
  réduire le travail frontend initial, accélérer le "first meaningful paint", améliorer les temps de réponse perçus.
  (*Webapp_Pilotage_Contrat - 2026-06-15*)

- **Sérialisation des dates GAS ↔ client:** convertir tous les champs date (debut/fin) en ISO strings (YYYY-MM-DD) dans les endpoints backend; stocker les objets Date uniquement en interne pour calculs.
  google.script.run ne peut pas sérialiser les Date objects — ils arrivent null côté client sinon; les strings ISO sont universelles et parsables.
  (*Webapp_Processus_Vivao - 2026-06-15*)
---

## Déploiement & Versioning