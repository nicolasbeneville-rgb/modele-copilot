<!-- NIVEAU: COMMUN | PROJET: ALL | SYNC: 2026-08-20 | PLAFOND: 800 -->

# Regles Communes - Tous Projets
**Source de verite** : `_governance/core/copilot-instructions-commun.md`
**Procedure detaillee** : `_governance/governance-quality-procedure.md`
**Chargement** : avant LOCAL, agent et skill. Ne pas modifier la copie projet.

## [SEC] Protection obligatoire

[SEC] Aucun secret, token, mot de passe, export d'authentification ou scope non arbitre dans Git.
[SEC] Un placeholder critique (`TO_CONFIRM`, `[a renseigner]`) bloque l'action.
[SEC] Une regle critique n'existe qu'a une seule source; les autres fichiers renvoient vers elle.
[SEC] Une regle locale ne peut jamais affaiblir une regle SEC commune.

## [FUNC] Lecture et plan

[FUNC] Lire `projet-status.yaml` avant toute action projet; lire `_governance/action-plan.yaml` au root.
[FUNC] Toute action exige un plan valide et `validate-action-plan.ps1 -Phase Pre`.
[FUNC] Lire avant d'editer; apres chaque edit, lancer le test cible le moins couteux.
[FUNC] Une tache actionnable indique perimetre, resultat, test, preuve et statut.
[FUNC] Une livraison est `verified` seulement avec preuve fraiche, controle d'integration et rollback.
[FUNC] Si le sujet expose un bug, une contradiction, une derive, une recurrence ou un risque, verifier que la question est la bonne puis appliquer les 5 pourquoi jusqu'a une cause racine actionnable.
[FUNC] Chaque pourquoi repose sur un fait ou est marque comme hypothese; consigner symptome, cause, preuve, action, test et classe LOCAL/COMMUN/PROCESS dans le plan ou le decision log.
[FUNC] Toute affirmation sur un fichier precis vient de sa lecture directe ce tour; jamais deduite d'un document tiers qui le mentionne.

## [FUNC] Couches de gouvernance

[FUNC] `copilot-instructions-commun.md` porte les regles partagees; ne pas y mettre d'ID, compte ou metier local.
[FUNC] `.github/copilot-instructions.md` porte les regles courtes propres au projet; ne pas le remplacer par GO SYNC.
[FUNC] `docs/project/operating-rules.md` porte le detail local, les raisons, procedures, IDs et rollbacks.
[FUNC] L'overlay actif est determine par signature (`.clasp.json` = GAS; React dans `package.json` = React).
[FUNC] Le perimetre de diffusion est le registre `_governance/clasp-project-registry.md`.

## [FUNC] Routines

[FUNC] `GO JOUR` lit `.github/prompts/bonjour.md` et ouvre une trace `OPEN`.
[FUNC] `GO NUIT` lit `.github/prompts/bonne-nuit.md`, execute `#retro`, puis pousse le depot concerne.
[FUNC] `GO RETRO` reste local au projet et alimente `docs/retro-modele.md`.
[FUNC] `GO RETRO MODEL` fait dry-run puis promotion revue vers `modele-copilot/docs/retro-modele.md`.
[FUNC] `GO NEW` utilise l'architecture et le miroir commun de `modele-copilot`.
[FUNC] `GO SYNC COPILOT` fait dry-run puis diffusion; il ne remplace jamais l'instruction locale.
[FUNC] `GO PUSH` est la seule routine de publication Apps Script; aucun deploy implicite.

## [FUNC] Git et diffusion

[FUNC] Le depot root ne commit que ses fichiers; chaque sous-projet commit ses propres fichiers.
[FUNC] Toute diffusion de masse exige dry-run, audit des diffs, validation structure/discovery et preuve finale.
[FUNC] Un bloc local non marque `GOVERNANCE-MANAGED` est conserve et signale, jamais ecrase.
[FUNC] Les copies commun et procedure sont controlees par hash ou audit diff.

## [STYLE] Execution

[STYLE] Planifier avant action; rester silencieux pendant les validations reussies; signaler faits, causes, impacts et decisions.
[STYLE] Les explications longues vont dans `governance-quality-procedure.md` ou `operating-rules.md`, pas ici.
[STYLE] Les agents heritent COMMUN + LOCAL; les skills heritent COMMUN seulement et n'appellent pas d'agent.