#!/bin/bash

export RG=$1
export location=$2
export functionAppName=$3
export cosmosDBAccountName=$4
export cosmosDBKey=$5
export cosmosDBDatabase=$6
export cosmosDBCollection=$7
export logicAppUri=$8

az login 
az group create -n $RG -l $location

funcStorageName=${functionAppName}sa
keyVaultName=${functionAppName}keyvault001

# Create an Azure Function with storage accouunt in the resource group.
az storage account create --name $funcStorageName --location $location --resource-group $RG --sku Standard_LRS
az functionapp create --name $functionAppName --storage-account $funcStorageName --consumption-plan-location $location --resource-group $RG
az functionapp identity assign --name $functionAppName --resource-group $RG
functionAppId="$(az functionapp identity show --name $functionAppName --resource-group $RG --query 'principalId' --output tsv)"

# Create Key Vault 
az keyvault create --name $keyVaultName --resource-group $RG --location $location 
az keyvault set-policy --name $keyVaultName --object-id $functionAppId --secret-permissions get

cosmosDBKeyId="$(az keyvault secret set --vault-name $keyVaultName --name cosmosDBKey --value $cosmosDBKey --query 'id' --output tsv)"
az functionapp config appsettings set -g $RG -n $functionAppName --settings cosmosDBKey="@Microsoft.KeyVault(SecretUri=$cosmosDBKeyId)"

logicAppUriId="$(az keyvault secret set --vault-name $keyVaultName --name logicAppUri --value $logicAppUri --query 'id' --output tsv)"
az functionapp config appsettings set -g $RG -n $functionAppName --settings logicAppUri="@Microsoft.KeyVault(SecretUri=$logicAppUriId)"

az functionapp config appsettings set -g $RG -n $functionAppName --settings cosmosDBAccountName="$cosmosDBAccountName"
az functionapp config appsettings set -g $RG -n $functionAppName --settings cosmosDBDatabase="$cosmosDBDatabase"
az functionapp config appsettings set -g $RG -n $functionAppName --settings cosmosDBCollection="$cosmosDBCollection"