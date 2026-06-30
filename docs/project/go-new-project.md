# GO NEW PROJECT

## But

Utiliser le modele local `modele-copilot` pour ajouter la couche Copilot a un projet existant, sans casser l'existant et sans deploiement.

## Ce que fait le kit

1. Verifie la structure du projet cible.
2. Verifie l'etat Git et signale l'absence de remote.
3. Copie la couche `.github` canonique du modele.
4. Ajoute les docs de gouvernance et securite manquantes.
5. Si une doc existe deja, la conserve et depose la version modele dans `docs/copilot-governance/to-merge/`.
6. Lance un controle simple des secrets en dur.
7. Ne deploie rien.
8. Exige de declarer le compte `clasp` attendu si le projet cible utilise Google Apps Script.

## Commande type

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\init-existing-project-governance.ps1 -ProjectPath ..\Webapp_Onboarding -ClaspAccountType PRO -ClaspAccountAlias nom@domaine.com -DryRun
```

Puis, si le dry-run est propre :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\init-existing-project-governance.ps1 -ProjectPath ..\Webapp_Onboarding -ClaspAccountType PRO -ClaspAccountAlias nom@domaine.com
```

Pour un projet avec interface :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\init-existing-project-governance.ps1 -ProjectPath ..\Webapp_Onboarding -UiProject -ClaspAccountType PRO -ClaspAccountAlias nom@domaine.com
```

## Resultat attendu

- `.github/copilot-instructions.md` remplace la version locale cible.
- `.github/agents/` et `.github/skills/` sont resynchronises.
- Les docs de gouvernance ne remplacent pas les docs metier existantes.
- Les conflits documentaires sont prepares pour fusion manuelle.
- Aucun deploiement automatique.

## Checkpoint obligatoire apres creation

Avant toute premiere commande `clasp`, renseigner dans le projet cible :
- `Declared clasp account: PRO|PERSO|TO_CONFIRM - email ou alias attendu` dans `.github/copilot-instructions.md`
- `Clasp account for this project: PRO|PERSO|TO_CONFIRM - email ou alias attendu` dans `docs/project/operating-rules.md`

Si le projet doit etre ajoute au workspace racine `PROJETS_APP_SCRIPT`, reporter aussi la decision dans `_governance/clasp-project-registry.md`.