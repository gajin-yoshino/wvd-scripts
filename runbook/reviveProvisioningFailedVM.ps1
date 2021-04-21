#
# start provisininig failed VMs
#   thsi script provided MS support engineer during SR thread "2103040060000026"
#  
Param (
    [parameter(HelpMessage="ResourceGroups as CSV format")]
    [string] $vmResourceGroups
)

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
# degub
#$vmResourceGroups = "rgoavdi-pool-00,rgoavdi-pool-01"
$targetRGs = New-Object System.Collections.ArrayList
foreach($rg in $vmResourceGroups.split(",")) {
      $targetRGs += $rg.Trim()
}

# サブスクリプション配下のプロビジョニング状態が Failed VM 一覧を取得
$VMs = New-Object System.Collections.ArrayList
foreach ($rg in $targetRGs) {
      $VMs += Get-AzVM -ResourceGroupName $rg | Where-Object { $_.ProvisioningState -eq "Failed" }
}

$triggeredVMs = @{}

# プロビジョニング状態が Failed の VM の全台停止を実施
Write-Warning("#of Provisioning Faild VM: {0}" -F $VMs.Count)
foreach ($vm in $VMs) {
      Write-Warning ("{0} is provisioning {1}" -F $vm.Name, $vm.ProvisioningState)
      Stop-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Force -NoWait
      $triggeredVMs[$vm.Name] = $false
      Start-Sleep 1
}

# 20 秒ごとに VM の状態を確認し、Failed の VM で停止が完了した VM の起動を実施
$cnt = 0
while ($cnt -lt $VMs.Count) {
      foreach ($vm in $VMs) {
            if ($triggeredVMs[$vm.Name] -eq $true) { 
                  # Write-Host $vm.Name "has already triggered starting."
                  continue }
            $vm_status = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status
            if ($vm_status.Statuses[0].DisplayStatus -eq "Provisioning succeeded" -and $vm_status.Statuses[1].DisplayStatus -eq "VM deallocated") {
                  Write-Verbose("{0} is finished deallocated. Retry Start VM." -F $vm_status.Name)
                  Start-AzVM -ResourceGroupName $vm_status.ResourceGroupName -Name $vm_status.Name -NoWait
                  $triggeredVMs[$vm.Name] = $true
                  $cnt++
            }
      }
      Write-Verbose("Starting triggered {0}/{1}" -F  $cnt,  $VMs.Count)
      Start-Sleep 20
}
