#!/usr/bin/env bash
#
# API Docs -
# https://cloud.ibm.com/apidocs/watsonxdata-software#authentication
#

# Configuration
LH_HOST="127.0.0.1:9443"
CASSANDRA_HOSTNAME=$(docker network inspect bridge --format='{{range .IPAM.Config}}{{.Gateway}}{{end}}')
USERNAME="ibmlhadmin"
PASSWORD="password"
INSTANCE_ID="0000-0000-0000-0000"
INSTANCE_NAME="lh-default"
PRESTO_ENGINE_ID="presto-01"
DATABASE="hcd"


# Authenticate and get access token
echo "Authenticating..."
AUTH_RESPONSE=$(curl -k -s -X POST \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "'${USERNAME}'",
    "password": "'${PASSWORD}'",
    "instance_id": "'${INSTANCE_ID}'",
    "instance_name": "'${INSTANCE_NAME}'"
  }' \
  "https://${LH_HOST}/lakehouse/api/v2/${INSTANCE_ID}/auth/authenticate")

echo "Authentication response: $AUTH_RESPONSE"

# Extract access token using jq
ACCESS_TOKEN=$(echo "${AUTH_RESPONSE}" | jq -r '.accessToken')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
    echo "Error: Failed to get access token"
    exit 1
fi


# Create Cassandra database using Bearer token
echo "Creating Cassandra database..."
RESPONSE=$(curl -k -s -X POST \
  -H "accept: application/json" \
  -H "AuthInstanceId: ${INSTANCE_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "database_display_name": "'${DATABASE}'",
    "database_type": "cassandra",
    "description": "Hyperconverged Database (HCD) with Vector Support",
    "database_details": {
      "hostname": "'${CASSANDRA_HOSTNAME}'",
          "port": 9042,
          "username": "cassandra",
          "password": "cassandra"
        },
        "associated_catalog": {
          "catalog_name": "'${DATABASE}'",
          "catalog_type": "Cassandra"
        }
  }' \
  -w "%{http_code}" \
  "https://${LH_HOST}/lakehouse/api/v2/database_registrations")

HTTP_CODE="${RESPONSE: -3}"
PAYLOAD="${RESPONSE%???}"

if [[ "$HTTP_CODE" -ge 400 ]]; then
    echo "Error (HTTP $HTTP_CODE): $PAYLOAD"
fi

echo ""
echo "Adding catalog to Presto engine..."
RESPONSE=$(curl -k -s -X POST \
  -H "accept: application/json" \
  -H "AuthInstanceId: ${INSTANCE_ID}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "catalog_names": "'${DATABASE}'"
  }' \
  -w "%{http_code}" \
  "https://${LH_HOST}/lakehouse/api/v2/${INSTANCE_ID}/presto_engines/${PRESTO_ENGINE_ID}/catalogs")

HTTP_CODE="${RESPONSE: -3}"
PAYLOAD="${RESPONSE%???}"

if [[ "$HTTP_CODE" -ge 400 ]]; then
    echo "Error (HTTP $HTTP_CODE): $PAYLOAD"
fi

