Param (
    [parameter(mandatory=$true, HelpMessage="select action")] 
    [ValidateSet('start', 'stop')]
    [string] $Action,
    [parameter(mandatory=$true, HelpMessage="specify VM's resource group")] 
    [string] $vmResourceGroup,
    [parameter(HelpMessage="list VMs not included as CSV")]
    [string] $excludedVMs
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

# list all vms in $
$vms = Get-AzVM -ResourceGroupName $vmResourceGroup -ErrorAction SilentlyContinue
If($null -eq $vms) {
    Write-Error ("host is not found: " + $vmName)
}

# filter not targeted VMs
$excluded = New-Object System.Collections.ArrayList
$excludedVMs.split(",") | ForEach-Object {$excluded += $_.Trim()}
$targetVMs = $vms | Where-Object { $excluded -notcontains $_.Name }

$targetVMs | ForEach-Object {
    $vmid = $_.Id
    switch ($Action) {
        "start" {start-vm -vmid $vmid}
        "stop" {stop-vm -vmid $vmid}
        default {write-error ("undefined action: " + $Action)}
    }    
}
