az login

az gorup create -l francecentral -n hubSpokeNet
az configure --default group=hubSpokeNet

az deployment group create  --template-file logfinale.bicep
az deployment group create  --template-file spoke2.bicep
az deployment group create  --template-file module.bicep
az deployment group create  --template-file VN4.bicep
az deployment group create  --template-file spoke5.bicep
az deployment group create  --template-file Spoke6.bicep

az deployment group create --template-file hub.bicep