# Proposer un logiciel

Deux façons de contribuer.

**Sans toucher au code** : ouvre une [issue « Proposer un logiciel »](../../issues/new/choose) et remplis le formulaire.

**Avec une pull request** : ajoute un bloc dans `software.json`, sur le modèle des entrées existantes.

| Champ | Rôle |
|---|---|
| `id` | Identifiant unique, en minuscules sans espace |
| `name`, `description`, `category`, `license` | Affichés sur la page |
| `homepage` | Site officiel ou dépôt |
| `github` | `propriétaire/dépôt` si le logiciel publie des releases GitHub |
| `asset_regex` | Expression qui reconnaît l’installeur Windows dans les fichiers de la release |
| `prerelease` | `true` si seules des pré-releases existent |
| `install.method` | `github` (téléchargement automatique) ou `page` (ouvre la page officielle) |
| `type` | `webtool` pour un outil web (PHP, Docker…) : affiché sur la page, jamais installé par le script |

Règles :

- Les liens pointent toujours vers les sources officielles. Aucun binaire n’est hébergé ici.
- Indique la licence réelle (gratuit, open source, shareware).
- Teste l’installation sur Windows 10 ou 11 avant de proposer une méthode `github`.
