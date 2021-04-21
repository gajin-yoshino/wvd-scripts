#
# version 2.1
# changed feature
#  - specify targeted VMs by tags on Vritual Machines
#        tag: power
#     value: skip-start   skip start of Automation job
#               skip-stop    skip stop of Automation job
Param (
    [parameter(mandatory=$true, HelpMessage="select action")] 
    [ValidateSet('start', 'stop')]
    [string] $Action,
    [parameter(mandatory=$true, HelpMessage="VMs in this ResourceGroup are scoped for the action")]
    [string] $vmResourceGroup
)

##
# Declaration Block
#
function Write-Result {
    Param (
        [string] $actionName,
        [string] $resourceGroupName,
        [string] $vmName,
        [string] $statusCode
    )
    Write-Output(ConvertTo-Json(@{"action" = $actionName; "statusCode" = $statusCode; "host" = $vmName; "resourceGroup" = $resourceGroupName}))
}

##
# Excecution Block
# 

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

# specify tag-value
[string] $tag_value = "skip-{0}" -F $Action

#debug
#$vmResourceGroup = "rgOAVDI-Pool-00"
#$tag_value = "skip-start"

    # retrieve VMs filltered by tag-value (excluding not-targeted)
$VMs = Get-AzVM -ResourceGroupName $vmResourceGroup -ErrorAction SilentlyContinue | Where-Object {$_.tags['power'] -ne $tag_value}
If(-not $VMs) {
    Write-Error("Target VMs for {0} are not found in {1}" -F $Action, $vmResourceGroup)
    throw ("Target VMs for {0} are not found in {1}" -F $Action, $vmResourceGroup)
}

# take an action for each VMs
foreach($vm in $VMs) {
    switch ($Action) {
        "start" {
            $result = Start-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait -AzContext $AzureContext
            Write-Result -actionName $Action  -resourceGroupName $vm.ResourceGroupName -vmName $vm.Name -statusCode $result.StatusCode
        }
        "stop" {
            $result = Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -NoWait -Force -AzContext $AzureContexts
            Write-Result -actionName $Action  -resourceGroupName $vm.ResourceGroupName -vmName $vm.Name -statusCode $result.StatusCode
        }
        default {Write-Error ("undefined action: {0}" -F $Action)}
    }
    # I'm not sure the reason why to wait, but a script wrote by SR engineer has this step, so that I took same manner.
    Start-Sleep -Milliseconds  500
}
