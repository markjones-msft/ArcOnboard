param (
    [string]$SubscriptionId,
    [string]$ResourceGroup,
    [string]$Location,
    [string]$Tags,
    [string]$ServicePrincipalId,
    [string]$ServicePrincipalClientSecret,
    [string]$TenantId,
    [string]$CorrelationId = "Batch 1",
    [string]$Cloud = "AzureCloud"
)

$env:SUBSCRIPTION_ID = $SubscriptionId
$env:RESOURCE_GROUP = $ResourceGroup
$env:TENANT_ID = $TenantId
$env:LOCATION = $Location
$env:AUTH_TYPE = "principal"
$env:CORRELATION_ID = $CorrelationId
$env:CLOUD = $Cloud

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072

# Download the installation package
Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/azcmagent-windows" -TimeoutSec 30 -OutFile "$env:TEMP\install_windows_azcmagent.ps1" -proxy "https://proxyserver"

# Install the hybrid agent
& "$env:TEMP\install_windows_azcmagent.ps1" -proxy "https://proxyserver"
if ($LASTEXITCODE -ne 0) { exit 1 }

# Run connect command
& "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe" connect --service-principal-id "$ServicePrincipalId" --service-principal-secret "$ServicePrincipalClientSecret" --resource-group "$env:RESOURCE_GROUP" --tenant-id "$env:TENANT_ID" --location "$env:LOCATION" --subscription-id "$env:SUBSCRIPTION_ID" --cloud "$env:CLOUD" --correlation-id "$env:CORRELATION_ID" --tags "$Tags"
catch {
    $logBody = @{subscriptionId="$env:SUBSCRIPTION_ID";resourceGroup="$env:RESOURCE_GROUP";tenantId="$env:TENANT_ID";location="$env:LOCATION";correlationId="$env:CORRELATION_ID";authType="$env:AUTH_TYPE";operation="onboarding";messageType=$_.FullyQualifiedErrorId;message="$_"}
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) -proxy "https://proxyserver" | out-null
    Write-Host -ForegroundColor red $_.Exception
}