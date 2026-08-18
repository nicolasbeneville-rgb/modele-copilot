# Skills Catalog

Source de politique : `_governance/skills-registry.yaml` dans le workspace chapeau.
Source de propagation : `modele-copilot/.github/skills/`.
Format source : fichiers `.md` dans le modèle ; format projet : `.github/skills/<nom>/SKILL.md`, requis pour la découverte VS Code.

## Socle projet

- `pre-action-plan`
- `api-decision`
- `bug-analysis`
- `check-account` (GAS)
- `doc-sync`
- `validate-syntax` (GAS)
- `completion-check`
- `graph-parallel-dispatch`
- `product-plan`

## UI et recette

- `design-audit` et `design-harmony` pour les projets UI
- `programme-recette` pour une recette fonctionnelle avant livraison
- `doc-cleanup` pour un audit documentaire, sans suppression automatique

## Optionnels

- `copilot-expert-costar`
- `copywriting`
- `prompt-engineering`
- `seo`

## Opt-in à la création

- `vsg-integration` — inclus uniquement avec `go-new-project.ps1 -VsgIntegration Oui`

Les skills externes lourds (`diagnosing-bugs`, `finishing-a-development-branch`,
`frontend-design`, `improve-codebase-architecture`) restent dans `.agents/skills/`
du workspace et ne sont pas copiés automatiquement dans chaque projet.

Les anciens skills projet `backup-checkpoint`, `security-review` et
`verification-before-completion` sont retirés : leurs responsabilités sont
portées respectivement par `@checkpoint-sauvegarde`, `@securite-owasp` et
`#completion-check`.

Règle : conserver le workflow générique dans les skills et les valeurs projet dans les docs.
