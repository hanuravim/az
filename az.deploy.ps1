# Login Azure

# Dev 113 sub

$applicationId =  "”;
$securePasswordPS = "" | ConvertTo-SecureString -AsPlainText -Force
$securePasswordAz = ""
$tenantId = ‘'
$subscriptionID = ‘’


#Resource Group 
$mainRgLocation="northeurope"
$LogRGLocation="eastus" # diffrent location as log analytics is not supprted in northeurope as of now

#provision 
$provisionAKS='true'
$provisionSQL='true'
$provisionLOG='true'
$provisionSTORAGE='true'
$provisionVNET='true'
$provisionAPG='true'
$provisionLogicApp='true'
$provisionAutomationAccnt='true'
$provisionAKS='true'
$provisionServiceBus='false' #this is not provisioned as per requirement . but the ARM templates is avilable if required in future
$provisionRG='true'
$provisionKV='true'
#If ($Data  -eq 'orange')


$nsgName =""
$routeTable=""

#PowerShell Login 
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $applicationId, $securePasswordPS
Connect-AzureRmAccount -ServicePrincipal -Credential $credential -TenantId $tenantId -Subscription $subscriptionID

#Az Login
az login --service-principal -u $applicationId --password $securePasswordAz --tenant $tenantId --subscription $subscriptionID
az account set --subscription $subscriptionID # setting up subscription context 

#Service Principal details for AKS, KeyVault etc..
$SPNId = $applicationId
$SPNSecret = $securePasswordAz
$ObjectId = (az ad sp show --id $applicationId | ConvertFrom-Json).objectId
$envname="lhanudemo"
$EnvPrefix="GAV-NE-NET"

#region Parameters
# Resourse Group
$RG_Name_aks= $EnvPrefix+"-"+$envname
$locationaks= 'northeurope'
$RG_Namelog=    $EnvPrefix+"-"+$envname+"-LOG"
$locationlog=   'eastus'
$TemplatePath = 'C:\Users\503090627\Desktop\GE-Last\arm\'
#Tags
$ApplicationName = 'noo'
$uai = 'uai2008722'
$SupportEmail = 'networkopssupport@ge.com'
$env = $envname.ToLower()
$preserve = 'true'

#StorageAccount
$storageAccountTemplate = $TemplatePath + 'StorageAccount.json'
$storageAccountParam =    $TemplatePath + 'StorageAccount.parameters.json'
$storageAccountName =     ($EnvPrefix.Replace("-","")+$envname+"storage").ToLower()



                 
                   

#KeyVault GAV-NE-NET-STG-APPINSIGHT
$kVParam = $TemplatePath + 'keyVault.parameters.json'
$kVTemplate = $TemplatePath + 'keyVault.json'
$AppInsightName=$EnvPrefix +"-"+$envname+"-"+"APPINSIGHT"
$keyVaultName = ($EnvPrefix.Replace("-","")+$envname+"kv").ToLower()

#Log Analytics GAV-NE-NET-STG-LOGS
$omsParam =    $TemplatePath + 'oms.parameters.json'
$omsTemplate = $TemplatePath + 'oms.json'
$workspaceName = $EnvPrefix+"-"+$envname+"-"+"LOGS"

#Postgress SQL  gav-ne-net-stg-postgresql
$postgresqlParam = $TemplatePath + 'NewPostgreSqlServer.parameters.json'
$postgresqlTemplate = $TemplatePath + 'NewPostgreSqlServer.json'
$sqladministratorLogin= 'geinadmin'
$sqladministratorLoginPassword= 'admin@1234'
$PsqlserverName = ($EnvPrefix+"-"+$envname+"-"+"postgresql").ToLower()

#VNET GAV-NE-NET-STG-DDoS
$newOrExistingDDos="existing"
$VNETParam = $TemplatePath + 'vnet.parameters.json'
$VNETETemplate = $TemplatePath + 'vnet.json'
$VnetName = $EnvPrefix+"-"+$envname+"-"+"VNET-AKS"
$ddosProtectionPlan_name="GAV-CU-INE-NP-DEV-Ddos"#$EnvPrefix+"-"+$envname+"-"+"DDoS"

#AKS gavnenetstgaks
$AKSParam = $TemplatePath + 'AKS.parameters.json'
$AKSTemplate = $TemplatePath + 'AKS.json'
$aksDnsPrefix = ($EnvPrefix.Replace("-","")+$envname+"aks").ToLower()
$aksResourceName = $EnvPrefix+"-"+$envname+"-"+"AKS"
$aksbuddyGroup = 'MC_' + $RG_Name_aks +'_'+ $aksResourceName +'_' + $locationaks

#Application Gateway gav-ne-net-stg
$AppGWParam = $TemplatePath + 'AppGateway.parameters.json'
$AppGWTemplate = $TemplatePath + 'AppGateway.json'
$domainNameLabel = ($EnvPrefix+"-"+$envname).ToLower()
$applicationGatewaypublicIpAddressName = $EnvPrefix+"-"+$envname+"-"+"APPGWY-IP"
$AppGwName = $EnvPrefix+"-"+$envname+"-"+"APPGWY"

#Automation Account  gavnenetstgautomationaccount
$autoAccParam = $TemplatePath + 'automationAccount.parameters.json'
$autoAccTemplate = $TemplatePath + 'automationAccount.json'
$runbookName = 'dbrunBook'
$logAnalyticsRunbookUri = 'https://hanuteststorage01.blob.core.windows.net/runbooks/DiagnosticLogging.ps1'
$pythonModuleUri= 'https://hanuteststorage01.blob.core.windows.net/runbooks/psycopg2-2.7.6.1-cp27-cp27m-win_amd64.whl'
$dbrunbookUri = 'https://hanuteststorage01.blob.core.windows.net/runbooks/dbrunbook.py'
$automationaccountName = ($EnvPrefix+"-"+$envname+"-"+"automationaccount").Replace("-","").ToLower()

#Logic App  
$LogicAppParam = $TemplatePath + 'LogicApp.parameters.json'
$LogicAppTemplate = $TemplatePath + 'LogicApp.json'
$workflows_GE_IN_LogicApp_name = $EnvPrefix+"-"+$envname+"-"+"LogicApp"




if((az group exists -n $RG_Name_aks) -eq 'false' -And $provisionRG -eq 'true')
{
  az group create -l northeurope -n $RG_Name_aks --subscription $subscriptionID --tags "ApplicationName=$ApplicationName" "uai=$uai" "SupportEmail =$SupportEmail" "env=$env" "preserve=$preserve"
}
if((az group exists -n $RG_Namelog) -eq 'false'  -And $provisionRG -eq 'true')
{
  az group create -l $LogRGLocation -n $RG_Namelog --subscription $subscriptionID --tags "ApplicationName=$ApplicationName" "uai=$uai" "SupportEmail =$SupportEmail" "env=$env" "preserve=$preserve"
}


#Deploy Storage Account

If ($provisionSTORAGE -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $storageAccountTemplate --parameters @$storageAccountParam --parameters storageAccountName=$storageAccountName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve 
}

#Upload python module and runbook artifacts files to storage account 

#temp artifacts upload $TemplatePath + 'LogicApp.json'
$DiagnosticLoggingpath=$TemplatePath+ 'DiagnosticLogging.ps1'
$dbrunbookpath=$TemplatePath+ 'dbrunbook.py'
$pymodulepath=$TemplatePath+ 'psycopg2-2.7.6.1-cp27-cp27m-win_amd64.whl'

$Tempcontainer="temparmcontainer"
$key=az storage account keys list --account-name $storageAccountName --query [0].value -o json  
az storage container create --name $Tempcontainer --account-key $key --account-name $storageAccountName 
az storage blob upload -f $dbrunbookpath -c $Tempcontainer --account-key $key --account-name $storageAccountName -n dbrunbook.py
az storage blob upload -f $pymodulepath -c $Tempcontainer --account-key $key --account-name $storageAccountName -n psycopg2-2.7.6.1-cp27-cp27m-win_amd64.whl
az storage blob upload -f $DiagnosticLoggingpath -c $Tempcontainer --account-key $key --account-name $storageAccountName -n DiagnosticLogging.ps1
$end=(Get-Date).AddDays(1).ToString('yyyy-MM-dd')
$saskey=az storage container generate-sas -n $Tempcontainer --account-name $storageAccountName --https-only --permissions dlrw --expiry $end 


$logAnalyticsRunbookUri =  az storage blob url -c $Tempcontainer -n DiagnosticLogging.ps1 --account-key $key --account-name $storageAccountName  --sas-token $saskey
$pythonModuleUri= az storage blob url -c $Tempcontainer -n psycopg2-2.7.6.1-cp27-cp27m-win_amd64.whl --account-key $key --account-name $storageAccountName  --sas-token $saskey
$dbrunbookUri = az storage blob url -c $Tempcontainer -n dbrunbook.py --account-key $key --account-name $storageAccountName  --sas-token $saskey                       

###END of Temp Code ####

#Deploy KeyVault
If ($provisionKV -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $kVTemplate --parameters @$kVParam --parameters keyVaultName=$keyVaultName --parameters objectId=$ObjectId `
--parameters servicePrincipalClientSecret=$SPNSecret --parameters AppInsightName=$AppInsightName --parameters sqlserverName=$PsqlserverName --parameters sqladministratorLogin=$sqladministratorLogin `
--parameters sqladministratorLoginPassword=$sqladministratorLoginPassword `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve
}
#Deploy Log Analytics
If ($provisionLOG -eq 'true'){
az group deployment create --resource-group $RG_Namelog --template-file $omsTemplate --parameters @$omsParam --parameters workspaceName=$workspaceName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve
}
#Deploy Postgress SQL
If ($provisionSQL -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $postgresqlTemplate --parameters @$postgresqlParam --parameters sqlserverName=$PsqlserverName `
--parameters sqladministratorLogin=$sqladministratorLogin --parameters sqladministratorLoginPassword=$sqladministratorLoginPassword `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve
}
#Deploy VNET
If ($provisionVNET -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $VNETETemplate --parameters @$VNETParam --parameters VnetName=$VnetName --parameters ddosProtectionPlan_name=$ddosProtectionPlan_name  --parameters newOrExistingDDos=$newOrExistingDDos `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve 
    az network vnet update -g $RG_Name_aks -n $VnetName --ddos-protection true    --ddos-protection-plan (az resource list -n $ddosProtectionPlan_name | ConvertFrom-Json).id     
  }         
#Deploy AKS
If ($provisionAKS -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $AKSTemplate --parameters @$AKSParam --parameters aksResourceName=$aksResourceName --parameters VnetName=$VnetName `
--parameters aksDnsPrefix=$aksDnsPrefix  `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve 
}
#Deploy Application Gateway
If ($provisionAPG -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $AppGWTemplate --parameters @$AppGWParam --parameters applicationGatewayName=$AppGwName --parameters domainNameLabel=$domainNameLabel `
--parameters applicationGatewaypublicIpAddressName=$applicationGatewaypublicIpAddressName --parameters VnetName=$VnetName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve
}
#Deploy Automation Account
If ($provisionAutomationAccnt -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $autoAccTemplate --parameters @$autoAccParam --parameters automationaccountName=$automationaccountName --parameters logAnalyticsRunbookUri=$logAnalyticsRunbookUri `
--parameters runbookName=$runbookName --parameters dbrunbookUri=$dbrunbookUri --parameters pythonModuleUri=$pythonModuleUri --parameters storageAccountName=$storageAccountName --parameters workspaceName=$workspaceName --parameters logWorkspaceResourceGroup=$RG_Namelog `
--parameters keyVaultName=$keyVaultName --parameters servicePrincipalClientSecret=$SPNSecret --parameters aksServicePrincipalClientId=$SPNId `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve
}
#Deploy Logic App
If ($provisionLogicApp -eq 'true'){
az group deployment create --resource-group $RG_Name_aks --template-file $LogicAppTemplate --parameters @$LogicAppParam --parameters workflows_GE_IN_LogicApp_name=$workflows_GE_IN_LogicApp_name --parameters automationaccountName=$automationaccountName `
--parameters runbookName=$runbookName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve
}
#Miscellenous configurations
#Start Diagnostic PowerShell Runbook
If ($provisionAutomationAccnt -eq 'true'){
Start-AzureRmAutomationRunbook -Name 'diagnosticsRunbook' -ResourceGroupName $RG_Name_aks -AutomationAccountName $automationaccountName
}
If ($provisionSQL -eq 'true'){
#Postgress VNET Rule Creategav-ne-net-stg-postgresql01.postgres.database.azure.com
az postgres server vnet-rule create -g $RG_Name_aks -s $PsqlserverName -n 'postgres-aks-vnet' --subnet 'aks-subnet' --vnet-name $VnetName
}
#nsgName = (az resource list -n $ddosProtectionPlan_name | ConvertFrom-Json).id

#Add NSG to AKS Subnet this is due to the limitation that we can not predict the name of route table and nsg in Aks buddy group 
# we are getting id insted of name because subnet and nsg, route table are in diffrent Rg and name will not resolve 
If ($provisionAKS -eq 'true' ){
$nsgName = az resource list --resource-group $aksbuddyGroup --resource-type Microsoft.Network/networkSecurityGroups --query [0].id -o json
$routeTable = az resource list --resource-group $aksbuddyGroup  --resource-type Microsoft.Network/routeTables --query [0].id -o json 
}

#Add NSG to AKS Subnet this is due to the limitation that we can not predict the name of route table and nsg in Aks buddy group 
# we are getting id insted of name because subnet and nsg, route table are in diffrent Rg and name will not resolve 
If ($provisionVNET -eq 'true' -and $nsgName -ne "" -and $routeTable -ne ""){


# this has to be done for all 3 subnets 
az network vnet subnet update --vnet-name $VnetName --name app-gateway --resource-group $RG_Name_aks --network-security-group $nsgName
#Add Route table to AKS subnet
az network vnet subnet update --vnet-name $VnetName --name app-gateway --resource-group $RG_Name_aks --route-table $routeTable

az network vnet subnet update --vnet-name $VnetName --name aks-subnet --resource-group $RG_Name_aks --network-security-group $nsgName
#Add Route table to AKS subnet
az network vnet subnet update --vnet-name $VnetName --name aks-subnet --resource-group $RG_Name_aks --route-table $routeTable
}

##Delete the container which we have created 

$cexists= az storage container exists --name $Tempcontainer --account-key $key --account-name $storageAccountName --sas-token $saskey --subscription $subscriptionID --query exists -o json 
 if( $cexists -eq 'true')
{
   az storage container delete --name $Tempcontainer --account-key $key --account-name $storageAccountName --sas-token $saskey --subscription $subscriptionID 
 
 }                         
                           
                            









