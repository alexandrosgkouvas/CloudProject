#create a resource group, an app service plan and a web app
az login
az group create \
  --name project \
  --location ItalyNorth 

az appservice plan create \
  --name Webapp \
  --resource-group project \
  --sku S1 \
  --is-linux

az webapp create \
  --name Webapplic4 \
  --plan Webapp \
  --resource-group project 

#create a storage account and a container
az storage account create \
  --name webappstorage4 \
  --resource-group project \
  --location ItalyNorth \
  --sku Standard_LRS \
  --access-tier Hot \
  --allow-blob-public-access false

az storage container create \
  --name blob \
  --account-name webappstorage4 \
  --auth-mode login


#create an API hosted in Azure App Service 
az appservice plan create \
  --name APIplan \
  --resource-group project \
  --location ItalyNorth \
  --sku S1 \
  --is-linux

az webapp create \
  --resource-group project \
  --plan APIplan \
  --name APIpub6

#create a virtual network and subnets
az network vnet create \
  --name VN4 \
  --resource-group project \
  --location ItalyNorth \
  --address-prefix 10.4.0.0/16

az network vnet subnet create \
  --address-prefix 10.4.1.0/24 \
  --name subwebapp \
  --resource-group project \
  --vnet-name VN4

az network vnet subnet create \
  --address-prefix 10.4.0.0/24 \
  --name substorage \
  --resource-group project \
  --vnet-name VN4

az network vnet subnet create \
  --address-prefix 10.4.2.0/24 \
  --name subAPI \
  --resource-group project \
  --vnet-name VN4

#Network restrictions and integration
 
#storage
#public network access to storage enabled only from selected networks and IP addresses
az storage account update \
  --resource-group project \
  --name webappstorage4 \
  --default-action Deny
 
#Create a private endpoint for the storage account
az network private-endpoint create \
  --resource-group project \
  --name webappstorage4 \
  --vnet-name VN4 \
  --subnet substorage \
  --private-connection-resource-id "/subscriptions/a652e6f5-3adf-4414-b197-e32ea19e3545/resourceGroups/project/providers/Microsoft.Storage/storageAccounts/webappstorage4" \
  --group-ids blob \
  --connection-name conn

#create DNS Zone
az network private-dns zone create \
  --resource-group project \
  --name privatelink.storage.core.windows.net

#Link Private DNS Zone to VNet
az network private-dns link vnet create \
  --resource-group project \
  --zone-name privatelink.storage.core.windows.net \
  --name Mylink \
  --virtual-network /subscriptions/a652e6f5-3adf-4414-b197-e32ea19e3545/resourceGroups/project/providers/Microsoft.Network/virtualNetworks/VN4 \
  --registration-enabled false


#webApp integration
az webapp vnet-integration add \
  --name Webapplic4 \
  --resource-group project \
  --vnet VN4 \
  --subnet subwebapp

#get the storage account key
az storage account keys list \
  --resource-group project \
  --account-name webappstorage4 \
  --query "[0].value" \
  --output tsv

#set a connection string
az webapp config connection-string set \
  --resource-group project \
  --name Webapplic4 \
  --settings "DefaultEndpointsProtocol=https;AccountName=webappstorage4;AccountKey=/JLqrZTL+VmtwvN2TP9LBDPJWbbjPvS1jkiIAo3EJZI/bLW8onhwVLCRvgLT/RtbRPhvW0YENIvo+AStVo0TmA==;BlobEndpoint=https://webappstorage4.privatelink.storage.core.windows.net/" \
  --connection-string-type Custom

#check connectivity
az webapp config connection-string list --resource-group project --name Webapplic4



#public API integration
az webapp vnet-integration add \
  --name APIpub6 \
  --resource-group project \
  --vnet VN4 \
  --subnet subAPI

#set a connection string
az webapp config connection-string set \
  --resource-group project \
  --name APIpub6 \
  --settings "DefaultEndpointsProtocol=https;AccountName=webappstorage4;AccountKey=/JLqrZTL+VmtwvN2TP9LBDPJWbbjPvS1jkiIAo3EJZI/bLW8onhwVLCRvgLT/RtbRPhvW0YENIvo+AStVo0TmA==;BlobEndpoint=https://webappstorage4.privatelink.storage.core.windows.net/" \
  --connection-string-type Custom

#check connectivity
az webapp config connection-string list --resource-group project --name APIpub6

#create NSGs to control traffic to subnets
az network nsg create \
  --resource-group project \
  --name NSGsubwebapp 

az network nsg create \
  --resource-group project \
  --name NSGsubstorage

az network nsg create \
  --resource-group project \
  --name NSGsubAPI

#association to subnets
az network vnet subnet update \
  --vnet-name VN4 \
  --name subwebapp  \
  --resource-group project \
  --network-security-group NSGsubwebapp

az network vnet subnet update \
  --vnet-name VN4 \
  --name substorage  \
  --resource-group project \
  --network-security-group NSGsubstorage

az network vnet subnet update  \
  --vnet-name VN4 \
  --name subAPI  \
  --resource-group project \
  --network-security-group NSGsubAPI

#create rules that deny traffic between the WebApp and the API
az network nsg rule create \
  --resource-group project \
  --nsg-name NSGsubwebapp \
  --name DenyWebappToAPI \
  --protocol Tcp \
  --direction Inbound \
  --source-address-prefix 10.4.1.0/24 \
  --source-port-range "*" \
  --destination-address-prefix 10.4.2.0/24 \
  --destination-port-range "*" \
  --access Deny \
  --priority 100

az network nsg rule create \
  --resource-group project \
  --nsg-name NSGsubAPI \
  --name DenyAPIToWebapp \
  --protocol Tcp \
  --direction Inbound \
  --source-address-prefix 10.4.2.0/24 \
  --source-port-range "*" \
  --destination-address-prefix 10.4.1.0/24 \
  --destination-port-range "*" \
  --access Deny \
  --priority 100

#enable WAF and create WAF policy
az network application-gateway waf-policy create \
  --resource-group project \
  --name WafPolicy \
  --location ItalyNorth\
  --policy-settings mode=Prevention

#create application Gateways with sku WAF_v2
#create the subnet
az network vnet subnet create \
  --address-prefix 10.4.3.0/24 \
  --name subgate \
  --resource-group project \
  --vnet-name VN4

#create the Application Gateway WAF policy
az network application-gateway waf-policy create \
  --resource-group project \
  --name wafpolicy1 \
  --location ItalyNorth

#Get the  defaultHostName of the API
az webapp show \
  --resource-group project \
  --name APIpub6 \
  --query defaultHostName
  --output tsv

%create an Application Gateway with the API as backend server
az network application-gateway create \
  --name GatewayAPItest \
  --resource-group project \
  --location ItalyNorth \
  --vnet-name VN4 \
  --subnet subgate \
  --capacity 2 \
  --frontend-port 80 \
  --sku WAF_v2 \
  --public-ip-address pubIPforAPI \
  --waf-policy wafpolicy1 \
  --servers APIpub6.azurewebsites.net \
  --priority 1

#Get the  defaultHostName of the WebApp
az webapp show \
  --resource-group project \
  --name Webapplic4 \
  --query defaultHostName
  --output tsv

#create an Application Gateway with the WebApp as backend server
az network application-gateway create \
  --name GatewayAPItest2 \
  --resource-group project \
  --location ItalyNorth \
  --vnet-name VN4 \
  --subnet subgate \
  --capacity 2 \
  --frontend-port 80 \
  --sku WAF_v2 \
  --public-ip-address pubIPforWebApp \
  --waf-policy wafpolicy1 \
  --servers Webapplic4.azurewebsites.net \
  --priority 1

#DDoS protection
az network ddos-protection plan create \
  --resource-group project \
  --name DdosProtectionPlan \
  --location ItalyNorth \
  --sku Standard

az network vnet update \
  --resource-group project \
  --name VN4 \
  --ddos-protection-plan DdosProtectionPlan


