# SQL Core AHUB Calculator

Azure Hybrid Use Benefit (AHUB) allows for taking advantage of cost savings of Azure services that are licensed with Software Assurance, in this case SQL licenses.
[SQL AHUB Information](https://azure.microsoft.com/en-us/pricing/hybrid-benefit/#services&clcid=0x409)

## Getting Started

This is a simple Powershell script that will scan a selected Azure Subscription for SQL resources that are accessible to you. It will provide an output
which shows AHUB eligible totals of :
* SQL PaaS vCores.
* SQL PaaS DTU's and conversion to vCores if changed.
* SQL IaaS registered VM cores by SQL Edition.

This tool is designed to give a high level view of SQL resources to aid in licensing decisions. If you do not have access to certain resources, resources which are not AHUB eligible or SQL IaaS VM's are not registered with the [SQL VM Resource Provider](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sql/virtual-machines-windows-sql-register-with-resource-provider), they will not be included in the calculation. In short, the results of this tool are best effort for guidance and may not accurately reflect all resources across reviewed subscriptions.

### Using the Core Calculator
1. [Open Azure Cloud Shell in your Azure Portal](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart-powershell#start-cloud-shell)
2. Run `cd ~`
3. Clone the repository with: `git clone https://github.com/nilopmsft/SQLAHUBCoreCalculator.git`
4. Run the powershell script with `./SQLAHUBCoreCalculator/calculator.ps1`
