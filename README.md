<h1 align="center">
 🔌 ☀️ Beem Energy Linux Tools ☀️ 🔌
</h1>

<p align="center">
  <img src="https://github.com/Oxyaxion/Beem-energy-tools/blob/main/beem-script.png">
</p>

Repertoire de différents scripts que j'utilise pour récupérer les metrics depuis l'API de Beem Energy (la même utilisée par l'application).
Ce ne sont évidemment pas des outils officielement supportés par <https://beemenergy.fr/> Beem Energy.

Ce repo est en Français car j'imagine que la grande majorité de leur client sont basées en FR/BE/CH ... if necessary mail me and will translate this in English.

# Cas d'usage

Je ne posséde qu'un seul panneau Beem On. Je n'ai pas donc pu tester l'API avec plus de panneaux ou les batteries ou une installation plus compléte ...

- beem_metrics.sh : Affiche vos statistiques de production actuelle / jour / mois dans votre terminal (C'est le script que vous cherchez qui génére l'image plus haut)

- explore_api.sh : Un script plus pour les developpeurs qui affiche toutes les informations disponibles par l'API

- To do : Un script pour injecter les metrics dans une base InfluxDB pour Grafana

## Installation et Configuration

Il n y a rien à configurer à part votre identifiant / mot de passe (le même que votre application Beem).

### Méthode 1 : Variables d'environnement (Recommandé)

1. Copiez le fichier d'exemple :
   ```bash
   cp .env.example .env
   ```

2. Éditez `.env` avec vos credentials :
   ```bash
   nano .env  # ou vim, code, etc.
   ```

3. Chargez les variables d'environnement :
   ```bash
   source .env
   ```

4. Exécutez le script :
   ```bash
   ./beem_metrics.sh
   ```

**Pour charger automatiquement les credentials à chaque session**, ajoutez à votre `~/.bashrc` ou `~/.zshrc` :
```bash
# Beem Energy credentials
if [ -f "$HOME/git/Beem-energy-tooling/.env" ]; then
    source "$HOME/git/Beem-energy-tooling/.env"
fi
```

### Méthode 2 : Options de ligne de commande

```bash
./beem_metrics.sh -e "votre@email.com" -p "votremotdepasse"
```

**Options disponibles :**
- `-e <email>` : Email d'authentification
- `-p <password>` : Mot de passe
- `-m <month>` : Mois (1-12, défaut: mois actuel)
- `-y <year>` : Année (défaut: année actuelle)
- `-h` : Afficher l'aide

**Exemples :**
```bash
# Utiliser les variables d'environnement
./beem_metrics.sh

# Avec credentials en ligne de commande
./beem_metrics.sh -e "email@example.com" -p "password"

# Pour un mois spécifique
./beem_metrics.sh -m 12 -y 2024

# Avec un password manager (Bitwarden CLI)
./beem_metrics.sh -e "email@example.com" -p "$(bw get password beem-energy)"
```

### Méthode 3 : Avec un password manager (Bitwarden)

Je recommande d'utiliser un password manager en ligne de commande comme Bitwarden CLI.

**Option A : Intégration directe dans le script**

Éditez `beem_metrics.sh` et décommentez les lignes 28-29 :
```bash
# Décommentez ces lignes dans le script :
EMAIL="${BEEM_EMAIL:-$(bw get username Beem 2>/dev/null)}"
PASSWORD="${BEEM_PASSWORD:-$(bw get password Beem 2>/dev/null)}"
```

Puis déverrouillez Bitwarden et exécutez le script :
```bash
bw unlock  # Entrez votre mot de passe maître
export BW_SESSION="..." # Copiez la session key affichée
./beem_metrics.sh
```

**Option B : Ligne de commande**
```bash
export BEEM_EMAIL="votre@email.com"
export BEEM_PASSWORD="$(bw get password Beem)"
./beem_metrics.sh
```

**Note :** Assurez-vous que l'entrée dans Bitwarden s'appelle exactement "Beem" 
