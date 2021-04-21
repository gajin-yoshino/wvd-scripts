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

- version 2.1
Start and Deallocate VMs and you can specify VMs skipped in this process.
tagged VM is skipped in the process.
       tag: power
    value: skip-start   skip start of Automation job
              skip-stop    skip stop of Automation job

### input parameter

$Action start / stop
$vmResourceGroup    Resource Group which has VMs

## vmPowerControlInRG.ps1

Start and Deallocate all VMs in the listed resource groups

### input parameter
$Action start / stop
$vmResourceGroup    list Resource Groups with CSV format
