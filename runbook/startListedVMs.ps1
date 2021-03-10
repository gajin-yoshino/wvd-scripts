# Start CSV listed VMs in the ResourceGroup

Param (
    [parameter(HelpMessage="ResourceGroup for the listed VMs")]
    [string] $RG,
    [parameter(HelpMessage="list VMs to start as CSV")]
    [string] $theList
)

function start-vm {
    Param (
        [parameter(mandatory=$true)]
        [string] $vmid
    )
    $result = Start-AzVM -Id $vmid -NoWait -AzContext $AzureContext
    write-output ($vmid.split("/")[8]  + ":START:" + $result.StartTime + ":" + $result.StatusCode) 
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

# list all vms in the list
$targetVMs = New-Object System.Collections.ArrayList
$theList.split(",") | ForEach-Object {
    $vmName = $_.Trim()
    $vm = Get-AzVM -ResourceGroupName $RG -Name $vmName -ErrorAction SilentlyContinue
    If($null -eq $vm) {
        Write-Error ("host is not found: " + $vmName)
    } else {
        $targetVMs += $vm
    }
}

# start VMs
$targetVMs | ForEach-Object {
    start-vm -vmid $_.Id
    #debug
    #write-output ("Start: " + $_.Name)
}
