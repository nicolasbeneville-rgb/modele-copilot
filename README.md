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

## Utilisation
1. Copier ce dossier dans un nouveau projet.
2. Initialiser un nouveau depot Git ou creer un repo GitHub.
3. Adapter `docs/project/charte-graphique.md`, `architecture-standards.md` et `copilot-instructions.md` au contexte du projet.
4. Lancer le one-shot kickoff depuis `docs/project/startup-kit.md`.

## Placeholders a remplacer
- `[PROJECT_NAME]`
- `[PROJECT_SCOPE]`
- `[STACK]`
- `[PRIMARY_RISKS]`
- `[OWNER_TEAM]`

## Regle de conception
- Methode generique dans les skills.
- Specificites projet dans les docs projet.
- Aucun deploiement sans GO explicite en chat.
