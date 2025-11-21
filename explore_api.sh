#!/bin/bash

# Configuration
EMAIL="${BEEM_EMAIL}"
PASSWORD="${BEEM_PASSWORD}"
MONTH=$(date +%-m)
YEAR=$(date +%Y)

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
