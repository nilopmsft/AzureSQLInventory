# SQL Azure Hybrid Use Calculator

Azure Hybrid Use Benefit (AHUB) allows for taking advantage of cost savings of Azure services that are licensed with Software Assurance, in this case SQL licenses.
[SQL AHUB Information](https://azure.microsoft.com/en-us/pricing/hybrid-benefit/#services&clcid=0x409)

This simple Powershell script will provide an output which shows AHUB eligible totals of:
* SQL PaaS vCores.
* SQL PaaS DTU's for conversion to vCore model.
* SQL IaaS registered VM cores by SQL Edition.

This tool is designed to give a high level view of SQL resources to aid in licensing decisions. If you do not have access to certain resources or resources which are not AHUB eligible, including SQL IaaS VM's which are not registered with the [SQL VM Resource Provider](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sql/virtual-machines-windows-sql-register-with-resource-provider), they will not be included in the calculation. In short, the results of this tool are best effort for guidance and may not accurately reflect all resources across reviewed subscriptions.

## Getting Started

1. [Open Azure Cloud Shell in your Azure Portal](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart-powershell#start-cloud-shell)
2. Run `cd ~`
3. Clone the repository with: `git clone https://github.com/nilopmsft/SQLAHUBCoreCalculator.git`
4. Run the powershell script with `./SQLAHUBCoreCalculator/calculator.ps1`
