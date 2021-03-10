#
# power control for All VMs in listed ResourceGroup
#
Param (
    [parameter(mandatory=$true, HelpMessage="select action")] 
    [ValidateSet('start', 'stop')]
    [string] $Action,
    [parameter(mandatory=$true, HelpMessage="specify VM's resource group in CSV form")] 
    [string] $vmResourceGroups
)

function start-vm {
    Param (
        [parameter(mandatory=$true)]
        [string] $vmid
    )
    $result = Start-AzVM -Id $vmid -NoWait -AzContext $AzureContext
    write-output ($vmid.split("/")[8]  + ":START:" + $result.StartTime + ":" + $result.StatusCode) 
}

function stop-vm {
    Param (
        [parameter(mandatory=$true)]
        [string] $vmid
    )
    $result = Stop-AzVM -Id $vmid -NoWait -force -AzContext $AzureContext
    write-output ($vmid.split("/")[8]  + ":STOP:" + $result.StartTime + ":" + $result.StatusCode) 
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

$targetVMs = New-Object System.Collections.ArrayList
$targetRGs | ForEach-Object {
    $vms = Get-AzVM -ResourceGroupName $_ -ErrorAction SilentlyContinue
    If(-not $vms) {
        Write-Error "VM does not exist in  ($_)"
    } else {
        $targetVMs += $vms
    }    
}

# take action for all vms
$targetVMs | ForEach-Object {
    $vmid = $_.Id
    switch ($Action) {
        "start" {start-vm -vmid $vmid}
        "stop" {stop-vm -vmid $vmid}
        default {write-error ("undefined action: " + $Action)}
    }
}
