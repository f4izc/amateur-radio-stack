# Amateur Radio Stack

Sélection de logiciels radioamateur pour **Windows 10/11**, avec liens vers la dernière version et un script d’installation à menu.

- Page : https://f4izc.github.io/amateur-radio-stack/
- Installation en une commande (PowerShell) :

```powershell
irm https://f4izc.github.io/amateur-radio-stack/install.ps1 | iex
```

Le script affiche la liste des logiciels par catégorie. Tu coches ceux que tu veux :
- les logiciels qui publient des releases GitHub sont téléchargés puis installés ;
- les autres ouvrent leur page de téléchargement officielle.

Les outils web (PHP, Docker) figurent sur la page, section **Webtools**, mais ne sont pas installés par le script.

Tu préfères lire le script avant de l’exécuter ? Télécharge [`install.ps1`](install.ps1), ouvre-le, puis lance-le.

## Fonctionnement

| Fichier | Rôle |
|---|---|
| `software.json` | Catalogue, source unique de la page et du script |
| `versions.json` | Dernières versions, régénéré chaque nuit par GitHub Actions |
| `index.html` | La page |
| `install.ps1` | Le script d’installation |

## Licences

Le contenu de ce dépôt (script, page, catalogue) est publié sous licence MIT. Les logiciels listés restent soumis à leurs licences respectives, certains sont sous licence payante ou shareware (VARA par exemple). Aucun logiciel n’est hébergé ici : les liens pointent vers les sources officielles.

## Contribuer

Voir [CONTRIBUTING.md](CONTRIBUTING.md).
