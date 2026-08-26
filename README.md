# Repo Modele Copilot

Ce dossier est un repo modele pret a reutiliser pour un nouveau projet.

## Demarrage en 5 minutes
1. Copier ce dossier vers le nouvel emplacement du projet.
2. Initialiser Git dans le dossier:
	- `git init`
	- `git add .`
	- `git commit -m "chore: initialize project from copilot template"`
3. Remplacer les placeholders projet (section "A personnaliser en premier").
4. Ouvrir le projet dans VS Code.
5. Lancer le one-shot kickoff de `docs/project/startup-kit.md`.

## Contenu
- `.github/` : instructions, agents, skills
- `docs/project/` : gouvernance, architecture, roadmap, startup kit
- `docs/security/` : baseline securite, risques robustesse/scalabilite

## Ce qui est generique (reutilisable tel quel)
- `.github/agents/*.agent.md`
- `.github/skills/*/SKILL.md`
- `docs/project/startup-kit.md`
- `docs/project/decision-log.md` (format)
- `docs/project/requirements-matrix.md` (structure)
- `docs/project/operating-rules.md` (guardrails de base)

## A personnaliser en premier (specifique projet)
- `.github/copilot-instructions.md`
- `docs/project/architecture-standards.md`
- `docs/project/roadmap.md`
- `docs/project/glossary.md`
- `docs/project/charte-graphique.md` (si UI)
- `docs/security/cybersecurity-baseline.md`
- `docs/security/robustesse-scalabilite.md`
- `type de compte clasp attendu` : `PRO` ou `PERSO`
- `email ou alias du compte clasp attendu`

## Utilisation
1. Copier ce dossier dans un nouveau projet.
2. Initialiser un nouveau depot Git ou creer un repo GitHub.
3. Declarer le compte `clasp` attendu pour le projet : `PRO`, `PERSO` ou `TO_CONFIRM`, puis renseigner l'email ou l'alias attendu.
4. Adapter `docs/project/charte-graphique.md`, `architecture-standards.md` et `copilot-instructions.md` au contexte du projet.
5. Lancer le one-shot kickoff depuis `docs/project/startup-kit.md`.

## Kit projet existant

Pour brancher le modele sur un projet deja existant sans casser la doc metier, utiliser :

`\.\init-existing-project-governance.ps1 -ProjectPath ..\NomDuProjet -ClaspAccountType PRO -ClaspAccountAlias nom@domaine.com -DryRun`

Le kit :
- verifie Git et la structure du projet
- remplace la couche `.github` canonique
- ajoute les docs manquantes
- garde les docs existantes et depose les versions modele dans `docs/copilot-governance/to-merge/` si fusion manuelle necessaire
- lance un controle simple des secrets
- ne deploie rien

Voir aussi `docs/project/go-new-project.md`.

## Placeholders a remplacer
- `[PROJECT_NAME]`
- `[PROJECT_SCOPE]`
- `[STACK]`
- `[PRIMARY_RISKS]`
- `[OWNER_TEAM]`
- `[PRO|PERSO|TO_CONFIRM]`
- `[email ou alias attendu]`

## Regle projet futur
- A la creation d'un nouveau projet, declarer le compte `clasp` attendu avant toute premiere commande `clasp login`, `clasp push`, `clasp version` ou `clasp deploy`.
- Reporter cette information dans `.github/copilot-instructions.md` et `docs/project/operating-rules.md`.
- Si le type de compte n'est pas encore arbitre, laisser `TO_CONFIRM` et bloquer tout deploiement jusqu'a decision.

## Regle de conception

## Flux de mise à jour des skills

### Architecture des skills

```
Workspace chapeau (source de politique)
  _governance/skills-registry.yaml
  .agents/skills/                 ← skills externes ou lourds, workspace seulement

Source projet canonique
  modele-copilot/.github/skills/*.md
       ↓ fusion contrôlée
Chaque projet/.github/skills/*.md
```

`vsg-integration` est une exception opt-in : il n'est copié que si le projet
déclare VSG au lancement avec `-VsgIntegration Oui`.

Les rétros suivent un flux séparé : `#retro` écrit dans le projet courant ;
`GO RETRO MODEL` agrège les entrées taguées vers `docs/retro-modele.md` du modèle.

### Mettre à jour un skill propagé
1. Lire `_governance/skills-registry.yaml` et confirmer son périmètre.
2. Modifier le fichier source dans `modele-copilot/.github/skills/`.
3. Lancer `..\_scripts\go-sync-copilot-safe.ps1 -DryRun` depuis la racine.
4. Vérifier la liste des fichiers puis demander le GO de synchronisation.

Les skills externes de `.agents/skills/` se mettent à jour avec `npx skills update`
après revue du diff et du fichier `skills-lock.json`.

## Flux de synchronisation workspace complet

Pour éviter les dérives entre le modèle et les projets du workspace, utiliser le script unique :

`\.\sync-workspace-github.ps1`

Ce script resynchronise proprement les assets canoniques suivants depuis les sources `_governance/` et `modele-copilot/.github/` :
- `copilot-instructions-commun.md`
- `copilot-instructions-gas.md` ou `copilot-instructions-react.md` selon la signature du projet
- `agents/`
- `skills/`
- `hooks/`

Il fusionne les fichiers canoniques sans supprimer les skills spécifiques au projet.
Il ne modifie jamais `.github/copilot-instructions.md`, qui reste le fichier LOCAL du projet.
Il ignore volontairement les prompts spécifiques projet comme `ml-code-review.prompt.md`.

### Exemples d'usage

- Dry-run sur tout le workspace : `\.\sync-workspace-github.ps1 -DryRun`
- Dry-run ciblé : `\.\sync-workspace-github.ps1 -Projects Webapp_Digitools,Webapp_Harmonisation -DryRun`
- Sync complète : `\.\sync-workspace-github.ps1`
- Sync complète + user prompts VS Code : `\.\sync-workspace-github.ps1 -SyncUserPrompts`
- Retraites de skills explicites : `\.\sync-workspace-github.ps1 -ApplyRetirements` après revue du dry-run
- Sync sans écraser les instructions : `\.\sync-workspace-github.ps1 -SkipInstructions`

### Quand l'utiliser

1. Après modification du modèle `.github/agents/`
2. Après modification du modèle `.github/skills/`
3. Après nettoyage structurel de doublons `.github/skills/`

### Ajouter un nouveau skill propagé
1. Créer le fichier plat dans `modele-copilot/.github/skills/`.
2. Ajouter son entrée et son périmètre dans `_governance/skills-registry.yaml`.
3. Mettre à jour le catalogue `modele-copilot/.github/skills/README.md`.
4. Faire un dry-run puis une synchronisation validée.

### Ajouter un skill projet-spécifique
1. Créer dans `.github/skills/` du projet directement.
2. Ne pas l'ajouter au modèle si son contenu dépend du métier local.
3. Le synchroniseur doit le préserver.
- Methode generique dans les skills.
- Specificites projet dans les docs projet.
- Aucun deploiement sans GO explicite en chat.
