param (
    [string]$CsvPath = "C:\Development\ArcOnboard\arcdeployment.csv",
    [string]$OnboardingScriptPath = "C:\Development\ArcOnboard\onboard-server.ps1"
)

# Get the current computer name
$currentComputerName = $env:COMPUTERNAME

# Read the CSV file
$servers = Import-Csv -Path $CsvPath

# Find the server parameters based on the current computer name
$server = $servers | Where-Object { $_.ServerName -eq $currentComputerName }

if ($server) {
    # Call the onboarding script with the parameters from the CSV
    & $OnboardingScriptPath -SubscriptionId $server.SubscriptionID -ResourceGroup $server.'Resource Group' -Location $server.Location -Tags $server.Tags -TenantId $server.TenantID -ApplicationName $server.'Application Name'
} else {
    Write-Host "No matching server found for the current computer name: $currentComputerName" -ForegroundColor Red
}
