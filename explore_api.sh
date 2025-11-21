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

echo "=== Fetching token ==="
TOKEN=$(curl -s https://api-x.beem.energy/beemapp/user/login \
  -X POST \
  -H "Content-Type: application/json" \
  --data-raw "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}" |
  jq -r '.accessToken')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Error: Unable to retrieve token"
  exit 1
fi

echo "Token retrieved successfully"
echo ""
echo "=== API Response for period: ${MONTH}/${YEAR} ==="
echo ""

curl -s -X POST \
  --location 'https://api-x.beem.energy/beemapp/box/summary' \
  --header "authorization: Bearer ${TOKEN}" \
  --header 'content-type: application/json; charset=UTF-8' \
  --header 'Accept: */*' \
  --data "{\"month\":$MONTH,\"year\":$YEAR}" | jq .

echo ""
echo "=== All available fields ==="
curl -s -X POST \
  --location 'https://api-x.beem.energy/beemapp/box/summary' \
  --header "authorization: Bearer ${TOKEN}" \
  --header 'content-type: application/json; charset=UTF-8' \
  --header 'Accept: */*' \
  --data "{\"month\":$MONTH,\"year\":$YEAR}" | jq 'keys'
