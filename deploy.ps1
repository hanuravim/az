# Login Azure
$applicationId =  "c80d3d3a-b0a4-4839-9deb-8ffa9d261fae";
$securePasswordPS = "ksoHkMcrahdAuq+VtnpgOwu4KCW08sPx940KddRJpO0=" | ConvertTo-SecureString -AsPlainText -Force
$securePasswordAz = "ksoHkMcrahdAuq+VtnpgOwu4KCW08sPx940KddRJpO0="
$tenantId = '15ccb6d1-d335-4996-b6f9-7b6925f08121'
$subscriptionID = '311890e7-f78d-496c-9ca2-f4b4b422fb0f'


#PowerShell Login 
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $applicationId, $securePasswordPS
Connect-AzureRmAccount -ServicePrincipal -Credential $credential -TenantId $tenantId -Subscription $subscriptionID

#Az Login
az login --service-principal -u $applicationId --password $securePasswordAz --tenant $tenantId --subscription $subscriptionID

#Service Principal details for AKS, KeyVault etc..
$SPNId = $applicationId
$SPNSecret = $securePasswordAz
$ObjectId = (az ad sp show --id $applicationId | ConvertFrom-Json).objectId

#region Parameters
# Resourse Group
$RG_Name_aks= 'hanutest01'
$locationaks= 'northeurope'
$RG_Namelog=    'hanutestlog01'
$locationlog=   'eastus'
$TemplatePath = 'C:\Users\overt.DESKTOP-VLC2MBR\Desktop\network-infrastructure-master\arm\'

#Tags
$ApplicationName = 'noo'
$uai = 'uai3026608'
$SupportEmail = 'networkopssupport@ge.com'
$env = 'qa'
$preserve = 'true'

#StorageAccount
$storageAccountTemplate = $TemplatePath + 'StorageAccount.json'
$storageAccountParam =    $TemplatePath + 'StorageAccount.parameters.json'
$storageAccountName =     'hanuteststorage001'

#KeyVault
$kVParam = $TemplatePath + 'keyVault.parameters.json'
$kVTemplate = $TemplatePath + 'keyVault.json'
$AppInsightName='hanuappinsght'
$keyVaultName = 'hanukvlt01'

#Log Analytics
$omsParam =    $TemplatePath + 'oms.parameters.json'
$omsTemplate = $TemplatePath + 'oms.json'
$workspaceName = 'hanuoms01'

#Postgress SQL
$postgresqlParam = $TemplatePath + 'NewPostgreSqlServer.parameters.json'
$postgresqlTemplate = $TemplatePath + 'NewPostgreSqlServer.json'
$sqladministratorLogin= 'geinadmin'
$sqladministratorLoginPassword= 'admin@1234'
$PsqlserverName = 'hanupostgresql'

#VNET
$VNETParam = $TemplatePath + 'vnet.parameters.json'
$VNETETemplate = $TemplatePath + 'vnet.json'
$VnetName = 'hanuvnet01'

#AKS
$AKSParam = $TemplatePath + 'AKS.parameters.json'
$AKSTemplate = $TemplatePath + 'AKS.json'
$aksDnsPrefix = 'hanuaksdns'
$nsgName = ''
$aksResourceName = 'hanuaks01'
$aksbuddyGroup = 'MC_' + $RG_Name_aks +'_'+ $aksResourceName +'_' + $locationaks

#Application Gateway
$AppGWParam = $TemplatePath + 'AppGateway.parameters.json'
$AppGWTemplate = $TemplatePath + 'AppGateway.json'
$domainNameLabel = 'hanulbl1'
$applicationGatewaypublicIpAddressName = 'hanulbpip'
$AppGwName = 'hanuappgw1'

#Automation Account
$autoAccParam = $TemplatePath + 'automationAccount.parameters.json'
$autoAccTemplate = $TemplatePath + 'automationAccount.json'
$runbookName = 'dbrunBook'
$logAnalyticsRunbookUri = 'https://hanuteststorage01.blob.core.windows.net/runbooks/DiagnosticLogging.ps1'
$pythonModuleUri= 'https://hanuteststorage01.blob.core.windows.net/runbooks/psycopg2-2.7.6.1-cp27-cp27m-win_amd64.whl'
$dbrunbookUri = 'https://hanuteststorage01.blob.core.windows.net/runbooks/dbrunbook.py'
$automationaccountName = 'hanuauto1'

#Logic App
$LogicAppParam = $TemplatePath + 'LogicApp.parameters.json'
$LogicAppTemplate = $TemplatePath + 'LogicApp.json'
$workflows_GE_IN_LogicApp_name = 'hanulogicapp1'

#Check or Create Resource group
Get-AzureRmResourceGroup -Name $RG_Name_aks -ev notPresentaks -ea 0
if ($notPresentaks) { Write-Host "Failover RG '$RG_Name_aks' does not exist.Creating new in $locationaks..." -ForegroundColor Yellow
New-AzureRmResourceGroup -Name $RG_Name_aks -Location $locationaks
} else { Write-Host "Using existing resource group '$RG_Name_aks'"-ForegroundColor Yellow ;}

Get-AzureRmResourceGroup -Name $RG_Namelog -ev notPresentlog -ea 0
if ($notPresentlog) { Write-Host "Failover RG '$RG_Namelog' does not exist.Creating new in $locationlog..." -ForegroundColor Yellow
New-AzureRmResourceGroup -Name $RG_Namelog -Location $locationlog
} else { Write-Host "Using existing resource group '$RG_Namelog'"-ForegroundColor Yellow ;}

#Deploy Storage Account
az group deployment create --resource-group $RG_Name_aks --template-file $storageAccountTemplate --parameters @$storageAccountParam --parameters storageAccountName=$storageAccountName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve 

#Deploy KeyVault
az group deployment create --resource-group $RG_Name_aks --template-file $kVTemplate --parameters @$kVParam --parameters keyVaultName=$keyVaultName --parameters objectId=$ObjectId `
--parameters servicePrincipalClientSecret=$SPNSecret --parameters AppInsightName=$AppInsightName --parameters sqlserverName=$PsqlserverName --parameters sqladministratorLogin=$sqladministratorLogin `
--parameters sqladministratorLoginPassword=$sqladministratorLoginPassword `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve

#Deploy Log Analytics
az group deployment create --resource-group $RG_Namelog --template-file $omsTemplate --parameters @$omsParam --parameters workspaceName=$workspaceName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve

#Deploy Postgress SQL
az group deployment create --resource-group $RG_Name_aks --template-file $postgresqlTemplate --parameters @$postgresqlParam --parameters sqlserverName=$PsqlserverName `
--parameters sqladministratorLogin=$sqladministratorLogin --parameters sqladministratorLoginPassword=$sqladministratorLoginPassword `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve

#Deploy VNET
az group deployment create --resource-group $RG_Name_aks --template-file $VNETETemplate --parameters @$VNETParam --parameters VnetName=$VnetName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve `
                
#Deploy AKS
az group deployment create --resource-group $RG_Name_aks --template-file $AKSTemplate --parameters @$AKSParam --parameters aksResourceName=$aksResourceName --parameters VnetName=$VnetName `
--parameters aksDnsPrefix=$aksDnsPrefix  `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve `

#Deploy Application Gateway
az group deployment create --resource-group $RG_Name_aks --template-file $AppGWTemplate --parameters @$AppGWParam --parameters applicationGatewayName=$AppGwName --parameters domainNameLabel=$domainNameLabel `
--parameters applicationGatewaypublicIpAddressName=$applicationGatewaypublicIpAddressName --parameters VnetName=$VnetName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve

#Deploy Automation Account
az group deployment create --resource-group $RG_Name_aks --template-file $autoAccTemplate --parameters @$autoAccParam --parameters automationaccountName=$automationaccountName --parameters logAnalyticsRunbookUri=$logAnalyticsRunbookUri `
--parameters runbookName=$runbookName --parameters dbrunbookUri=$dbrunbookUri --parameters pythonModuleUri=$pythonModuleUri --parameters storageAccountName=$storageAccountName --parameters workspaceName=$workspaceName --parameters logWorkspaceResourceGroup=$RG_Namelog `
--parameters keyVaultName=$keyVaultName --parameters servicePrincipalClientSecret=$SPNSecret --parameters aksServicePrincipalClientId=$SPNId `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve

#Deploy Logic App
az group deployment create --resource-group $RG_Name_aks --template-file $LogicAppTemplate --parameters @$LogicAppParam --parameters workflows_GE_IN_LogicApp_name=$workflows_GE_IN_LogicApp_name --parameters automationaccountName=$automationaccountName `
--parameters runbookName=$runbookName `
--parameters ApplicationName=$ApplicationName --parameters uai=$uai --parameters SupportEmail=$SupportEmail --parameters env=$env --parameters preserve=$preserve

#Miscellenous configurations
#Start Diagnostic PowerShell Runbook
Start-AzureRmAutomationRunbook -Name 'diagnosticsRunbook' -ResourceGroupName $RG_Name_aks -AutomationAccountName $automationaccountName

#Postgress VNET Rule Creategav-ne-net-stg-postgresql01.postgres.database.azure.com
az postgres server vnet-rule create -g $RG_Name_aks -s $PsqlserverName -n 'postgres-aks-vnet' --subnet 'aks-subnet' --vnet-name $VnetName

#Add NSG to AKS Subnet
$nsgName = (az resource list --resource-group $aksbuddyGroup --resource-type Microsoft.Network/networkSecurityGroups | ConvertFrom-Json).id
$routeTable = (az resource list --resource-group $aksbuddyGroup --resource-type Microsoft.Network/routeTables | ConvertFrom-Json).id
az network vnet subnet update --vnet-name $VnetName --name app-gateway --resource-group $RG_Name_aks --network-security-group $nsgName

#Add Route table to AKS subnet
az network vnet subnet update --vnet-name $VnetName --name app-gateway --resource-group $RG_Name_aks --route-table $routeTable

