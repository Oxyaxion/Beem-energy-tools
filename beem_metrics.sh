#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 [-e <email>] [-p <password>] [-m <month>] [-y <year>]"
  echo ""
  echo "Options:"
  echo "  -e <email>     Email for authentication"
  echo "  -p <password>  Password for authentication"
  echo "  -m <month>     Month (1-12, default: current month)"
  echo "  -y <year>      Year (default: current year)"
  echo "  -h             Display this help message"
  echo ""
  echo "Environment variables (can be overridden by options):"
  echo "  BEEM_EMAIL     Email for authentication"
  echo "  BEEM_PASSWORD  Password for authentication"
  echo ""
  echo "Example:"
  echo "  export BEEM_EMAIL=\"your@email.com\""
  echo "  export BEEM_PASSWORD=\"yourpassword\""
  echo "  $0"
  exit 1
}

# Default values from environment variables
# Option: Récupérer les credentials depuis Bitwarden (décommentez les lignes ci-dessous)
# Assurez-vous d'être connecté avec: bw login ou bw unlock
# EMAIL="${BEEM_EMAIL:-$(bw get username Beem 2>/dev/null)}"
# PASSWORD="${BEEM_PASSWORD:-$(bw get password Beem 2>/dev/null)}"

EMAIL="${BEEM_EMAIL:-}"
PASSWORD="${BEEM_PASSWORD:-}"
MONTH=$(date +%-m)  # Month without leading zero
YEAR=$(date +%Y)

# Parse command line options
while getopts "e:p:m:y:h" opt; do
  case $opt in
    e) EMAIL="$OPTARG" ;;
    p) PASSWORD="$OPTARG" ;;
    m) MONTH="$OPTARG" ;;
    y) YEAR="$OPTARG" ;;
    h) usage ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
  esac
done

# Check required parameters
if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
  echo "Erreur: Email et mot de passe sont requis"
  echo "Utilisez les variables d'environnement BEEM_EMAIL et BEEM_PASSWORD"
  echo "ou passez-les en options avec -e et -p"
  usage
fi

POST_DATA="{\"month\":$MONTH,\"year\":$YEAR}"

# Colors for display
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to create a progress bar
progress_bar() {
  local current=$1
  local max=$2
  local width=${3:-50}  # Default width: 50 characters

  if [ "$max" -eq 0 ]; then
    percentage=0
  else
    percentage=$(echo "scale=2; ($current / $max) * 100" | bc)
  fi

  filled=$(echo "scale=0; ($current * $width) / $max" | bc 2>/dev/null || echo "0")
  filled=${filled%.*}  # Remove decimal part

  if [ "$filled" -gt "$width" ]; then
    filled=$width
  fi

  empty=$((width - filled))

  # Build the bar
  bar=""
  for ((i=0; i<filled; i++)); do
    bar+="█"
  done
  for ((i=0; i<empty; i++)); do
    bar+="░"
  done

  LC_NUMERIC=C printf "${CYAN}[${bar}]${NC} ${YELLOW}%.1fW${NC} / ${GREEN}%dW${NC} (%.1f%%)\n" "$current" "$max" "$percentage"
}

# Function to format timestamp to European format
format_timestamp() {
  local timestamp=$1

  if [ "$timestamp" = "N/A" ] || [ -z "$timestamp" ] || [ "$timestamp" = "null" ]; then
    echo "N/A"
    return
  fi

  # Check if timestamp is already in ISO 8601 format (contains 'T' or ':')
  if [[ "$timestamp" =~ [T:] ]]; then
    # Handle ISO 8601 format (e.g., "2025-01-21T10:30:00Z" or "2025-01-21 10:30:00")
    date -d "$timestamp" "+%d/%m/%Y %H:%M:%S" 2>/dev/null || echo "Date invalide"
  else
    # Handle Unix timestamp (numeric only)
    # Check if timestamp is in milliseconds (13 digits) or seconds (10 digits)
    local ts_length=${#timestamp}
    if [ "$ts_length" -gt 10 ]; then
      # Convert milliseconds to seconds
      timestamp=$(echo "scale=0; $timestamp / 1000" | bc)
    fi

    # Format: DD/MM/YYYY HH:MM:SS
    date -d "@$timestamp" "+%d/%m/%Y %H:%M:%S" 2>/dev/null || echo "Date invalide"
  fi
}

echo -e "${BLUE}=== Récupération du token ===${NC}"

# Token retrieval
TOKEN=$(curl -s https://api-x.beem.energy/beemapp/user/login \
  -X POST \
  -H "Content-Type: application/json" \
  --data-raw "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" |
  jq -r '.accessToken')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Erreur : Impossible de récupérer le token"
  exit 1
fi

echo -e "${GREEN}Token récupéré avec succès${NC}"
echo -e "Période : ${BLUE}${MONTH}/${YEAR}${NC}"

# Function to retrieve data
get_metrics() {
  curl -s -X POST \
    --location 'https://api-x.beem.energy/beemapp/box/summary' \
    --header "authorization: Bearer ${TOKEN}" \
    --header 'content-type: application/json; charset=UTF-8' \
    --header 'Accept: */*' \
    --data "${POST_DATA}"
}

echo -e "\n${BLUE}=== Récupération des métriques ===${NC}"

# Data retrieval
RESPONSE=$(get_metrics)

if [ -z "$RESPONSE" ]; then
  echo "Erreur : Aucune donnée récupérée"
  exit 1
fi

# Extraction of all data
NAME=$(echo "$RESPONSE" | jq -r '.[0].name // "N/A"')
SERIAL=$(echo "$RESPONSE" | jq -r '.[0].serialNumber // "N/A"')
POWER=$(echo "$RESPONSE" | jq -r '.[0].power // 0')
TOTAL_MONTH=$(echo "$RESPONSE" | jq -r '.[0].totalMonth // 0')
TOTAL_DAY=$(echo "$RESPONSE" | jq -r '.[0].totalDay // 0')
WATT_HOUR=$(echo "$RESPONSE" | jq -r '.[0].wattHour // 0')
LAST_PRODUCTION=$(echo "$RESPONSE" | jq -r '.[0].lastProduction // "N/A"')
LAST_ALIVE=$(echo "$RESPONSE" | jq -r '.[0].lastAlive // "N/A"')
LAST_DBM=$(echo "$RESPONSE" | jq -r '.[0].lastDbm // "N/A"')

# Conversion to kWh (division by 1000)
TOTAL_MONTH_KWH=$(echo "scale=3; $TOTAL_MONTH / 1000" | bc)
TOTAL_DAY_KWH=$(echo "scale=3; $TOTAL_DAY / 1000" | bc)
WATT_HOUR_KWH=$(echo "scale=3; $WATT_HOUR / 1000" | bc)

# Display panel information
echo -e "\n${BLUE}=== Informations du panneau ===${NC}"
echo -e "${GREEN}Nom :${NC} ${NAME}"
echo -e "${GREEN}Numéro de série :${NC} ${SERIAL}"
echo -e "${GREEN}Puissance crête :${NC} ${POWER}W"

# Display production statistics
echo -e "\n${BLUE}=== Statistiques de production ===${NC}"
echo -e "${GREEN}Total du mois :${NC} ${TOTAL_MONTH_KWH} kWh (${TOTAL_MONTH} Wh)"
echo -e "${GREEN}Total du jour :${NC} ${TOTAL_DAY_KWH} kWh (${TOTAL_DAY} Wh)"
echo -e "\n${GREEN}Production actuelle :${NC}"
progress_bar "$WATT_HOUR" "$POWER" 40

# Display system information
echo -e "\n${BLUE}=== Informations système ===${NC}"
echo -e "${GREEN}Dernière production :${NC} $(format_timestamp "$LAST_PRODUCTION")"
echo -e "${GREEN}Dernière activité :${NC} $(format_timestamp "$LAST_ALIVE")"
echo -e "${GREEN}Force du signal :${NC} ${LAST_DBM} dBm"

# Optionnel : Afficher la réponse brute pour le débogage
# echo -e "\n${BLUE}=== Réponse brute ===${NC}"
# echo "$RESPONSE" | jq .
