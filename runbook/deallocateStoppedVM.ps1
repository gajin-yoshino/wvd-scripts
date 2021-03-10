#
# deallocate stopped VM in listed Resource Groups
#
Param (
    [parameter(mandatory=$true, HelpMessage="specify resource groups in CSV form")] 
    [string] $vmResourceGroups
)

function stop-vm {
    Param (
        [parameter(mandatory=$true)]
        [string] $vmResourceGroup,
        [parameter(mandatory=$true)]
        [string] $vmName
    )
    $result = Stop-AzVM -ResourceGroupName $vmResourceGroup -Name $vmName -NoWait -Force -AzContext $AzureContext
    write-output ("[" + $vmName  + "]:STOP:" + $result.StartTime + ":" + $result.StatusCode) 
}

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection

# Wrap authentication in retry logic for transient network failures
$connectionResult = Connect-AzAccount `
                        -ServicePrincipal `
                        -Tenant $connection.TenantID `
                        -ApplicationId $connection.ApplicationID `
                        -CertificateThumbprint $connection.CertificateThumbprint

# https://stackoverflow.com/questions/64957072/start-azvm-cannot-bind-parameter-defaultprofile-when-running-an-azure-runboo
$AzureContext = Set-AzContext -SubscriptionId $Connection.SubscriptionID

# list all vms in $targetRGs
$targetRGs = New-Object System.Collections.ArrayList
$vmResourceGroups.split(",") | ForEach-Object {$targetRGs += $_.Trim()}

$targetRGs | ForEach-Object {
    $vms = Get-AzVM -ResourceGroupName $_ -Status  -ErrorAction SilentlyContinue | Where-Object {$_.PowerState -eq 'VM stopped'} | Select-Object -Property ResourceGroupName,Name
    If($vms) {
        $vms | ForEach-Object {
            #debug
            #Write-Output ("stop-vm -vmResourceGroup [" + $_.ResourceGroupName +  "] -vmName [" + $_.Name +"]")
            stop-vm -vmResourceGroup $_.ResourceGroupName -vmName $_.Name
        }
    }    
}
