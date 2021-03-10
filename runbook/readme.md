# runbook scripts

## startListedVMs.ps1

Start listed VMs in the Resource Group

### input parameter

$RG Resource Group name
$theList    VM names with CSV format

## deallocateStoppedVM.ps1

deallocate stopped VMs

### input parameter

$vmResourceGroups deallocate VMs in this Resource Group

## vmPowerControl .ps1

Start and Deallocate VMs and you can specify VMs skipped in this process.

### input parameter

$Action start / stop
$vmResourceGroup    Resource Group which has VMs
$excludedVMs    list skipped VMs with CSV format

## vmPowerControlInRG.ps1

Start and Deallocate all VMs in the listed resource groups

### input parameter
$Action start / stop
$vmResourceGroup    list Resource Groups with CSV format
