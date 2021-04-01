using namespace System.Net

# parameters in a step of LogicApp
# {
#     "VMName": "@{triggerBody()['vmName']}",
#     "resourceGroup": "@{triggerBody()['resourceGroupName']}"
#   }

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

#retrieve input parameter
$VMName = $Request.Body.VMName + "<domain suffix>"
$vmRG = $Request.Body.resourceGroup
$body = "<<Initial value>>"

$pools = @{
    "# VM RG"           =@("PoolName", "Pool RG")
}

$returnCode = $null

if ($pools[$vmRG.ToLower()]) {
    $hostPool = $pools[$vmRG.ToLower()][0]
    $poolRG = $pools[$vmRG.ToLower()][1]
    $sessionHost = Get-AzWvdSessionHost -ResourceGroupName $poolRG -HostPoolName $hostPool -Name $VMName

    $body = $sessionHost.AssignedUser
    $returnCode = [HttpStatusCode]::OK 
} else {
    Write-Error "this resource group is not applicable: $vmRG"  
    $returnCode = [HttpStatusCode]::NotFound
}


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $returnCode
    Body = $body
})
