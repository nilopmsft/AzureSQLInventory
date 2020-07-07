<#
.Synopsis
    Core calculatore for SQL resources in Azure.
.Description
Script that will scan for all SQL PaaS vCores as well as DTU's and all SQL IaaS registered VM Cores to determine core count for AHUB with SQL Licensing with Software Assurance
#>


function SubscriptionSelection {
    $InputMessage = "`r`nSubscription number"
    $SubSelection = Read-Host $InputMessage
    $valid = IntValidation -UserInput $SubSelection
    while(!($valid.Result)) {
        Write-Host $valid.Message -ForegroundColor Yellow
        $SubSelection = Read-Host $InputMessage
        $valid = IntValidation -UserInput $SubSelection
    }
    while([int32]$SubSelection -ge $subcount) {
        Write-Host "Please select a valid subscription number, $SubSelection is not an option" -ForegroundColor Yellow
        $SubSelection = SubscriptionSelection
    }
    return $SubSelection
}

function PaaSCoreCalculator {
    
    Param(
        #Edition of Object
        $Edition,
        #DTU or Cores of Object
        $Capacity,
        #Existing array of running calculations of cores and dtu's
        $CoreArray
    )
    
    switch ($Edition) {
        "Premium" { $CoreArray["dtu_premium"] = $CoreArray["dtu_premium"] + $Capacity }
        "Standard" { $CoreArray["dtu_standard"] = $CoreArray["dtu_standard"] + $Capacity }
        "Basic" { $CoreArray["dtu_standard"] = $CoreArray["dtu_standard"] + $Capacity }
        "GeneralPurpose" { $CoreArray["vcore_gp"] = $CoreArray["vcore_gp"] + $Capacity }
        "Hyperscale" { $CoreArray["vcore_hs"] = $CoreArray["vcore_hs"] + $Capacity }
        "BusinessCritical" { $CoreArray["vcore_bc"] = $CoreArray["vcore_bc"] + $Capacity }
     }

     return $CoreArray
}

function IaaSCoreCalculator {
    
    Param(
        #Edition of Object
        $Edition,
        #DTU or Cores of Object
        $Capacity,
        #Existing array of running calculations of cores and dtu's
        $CoreArray
    )
    
    switch ($Edition) {
        "Enterprise" {$CoreArray["iaas_enterprise"] = $CoreArray["iaas_enterprise"] + $Capacity }
        "Standard" {$CoreArray["iaas_standard"] = $CoreArray["iaas_standard"] + $Capacity }
        "Web" {$CoreArray["iaas_web"] = $CoreArray["iaas_web"] + $Capacity }
        "Express" {$CoreArray["iaas_express"] = $CoreArray["iaas_express"] + $Capacity }
        "Developer" {$CoreArray["iaas_developer"] = $CoreArray["iaas_developer"] + $Capacity }
     }

     return $CoreArray
}

function ServiceObjectiveCalculator {
    
    Param(
        #SLO of SQL Object
        $ServiceObjectiveName,
        #Existing array of ServiceObjectiveCalculator results
        $ServiceObjectiveArray
    )

    
    if ($ServiceObjectiveArray.ContainsKey($ServiceObjectiveName)) {

        $ServiceObjectiveArray[$ServiceObjectiveName] = $ServiceObjectiveArray[$ServiceObjectiveName] + 1
    
    } else {

        $ServiceObjectiveArray[$ServiceObjectiveName] = 1

    }

    return $ServiceObjectiveArray
}


#Function for just showing some progress in case there is a lot of resources.  Some silly statement if it starts to get to a large amount of them.
function ProgressBar {
    Param(
        #Count for modulus
        $Count
    )

    if (($Count % 5) -eq 0) {
        Write-Host '.' -NoNewLine -ForegroundColor Cyan 
    }

    if(($Count % 100) -eq 0) {
        Write-Host "You unlocked the 'Over 100 SQL Resources' Achievement!" -ForegroundColor Cyan
    }
    if(($Count % 500) -eq 0) {
        Write-Host 'When does this end?!' -ForegroundColor Cyan
    }

    if(($Count % 1000) -eq 0) {
        Write-Host "Over 1000, I don't even know what to say..." -ForegroundColor Cyan
    }

    if(($Count % 5000) -eq 0) {
        Write-Host "UNLIMITED SQL POWER!!" -ForegroundColor Cyan
    }
    
}

#Validate integer based question input both as an input value but also the number of options available
function IntValidation {
    Param(
        #User input
        $UserInput,
        #Options Count to verify its within range
        $OptionCount
    )
    $intref = 0
    if( [int32]::TryParse( $UserInput , [ref]$intref ) -and [int32]$UserInput -le $OptionCount -and [int32]$UserInput -gt 0) {
        return @{Result=$true; Message="Valid"}
    }
    else {
      return @{Result=$false; Message="Please enter a valid selection number"}
    }
}

# Our code entry point, We verify the subscription and move through the steps from here.
Clear-Host
$currentsub = Get-AzContext
$currentsubfull = $currentsub.Subscription.Name + " (" + $currentsub.Subscription.Id + ")"
Write-Host "Azure Hybrid Use Benefit SQL Calulator Tool`r`n" -ForegroundColor Yellow
Write-Host @"
This tool is designed to gather the core count of eligible SQL resources which AHUB or Reserved Capacity could be applied. It will scan for all PaaS 
and IaaS (must be registered with the SQL Resource Provider to be seen) SQL resources in a given subscription after which providing a summary of resources.

NOTE: This tool is using basic ARM calls to gather information. If a resource is not eligible for AHUB/Reservations e.g. Azure SQL Serverless, or you do not 
have permissions to view those resources on the subscription they will not be included. 
The results of this tool are best effort for guidance and may not accurately reflect all resources across reviewed subscriptions.
"@

function MainFunction {
    #Gathering subscription selection, validating input and changing to another subscription if needed
    $rawsubscriptionlist = Get-AzSubscription | Where-Object {$_.State -ne "Disabled"} | Sort-Object -property Name | Select-Object Name, Id 
    $subscriptionlist = [ordered]@{}
    $subscriptionlist.Add(1, "CURRENT SUBSCRIPTION: $($currentsubfull)")
    $subcount = 2
    foreach ($subscription in $rawsubscriptionlist) {
        $subname = $subscription.Name + " (" + $subscription.Id + ")"
        if($subname -ne $currentsubfull) {
            $subscriptionlist.Add($subcount, $subname)
            $subcount++
        }
    }

    Write-Host "`r`nPlease select a subscription from the options below to run the report on.`r`n" -ForegroundColor Yellow

    $subscriptionlist.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key))" "$($_.Value)"}

    $InputMessage = "`r`nSubscription number"
    $SubSelection = Read-Host $InputMessage
    $valid = IntValidation -UserInput $SubSelection -OptionCount $subscriptionlist.Count
    while(!($valid.Result)) {
        Write-Host $valid.Message -ForegroundColor Yellow
        $SubSelection = Read-Host $InputMessage
        $valid = IntValidation -UserInput $SubSelection -OptionCount $subscriptionlist.Count
    }

    if ($SubSelection -ne 1) {
        $selectedsub = $subscriptionlist.[int]$SubSelection
        $selectedsubid = $selectedsub.Substring($selectedsub.Length - 37).TrimEnd(")")
        $changesub = Select-AzSubscription -Subscription $selectedsubid
    }

    $subinfo = Get-AzContext

    #Creating some empty variables for calculations
    $dtu_standard = 0
    $dtu_premium = 0
    $vcore_gp = 0
    $vcore_bc = 0

    $core_array = @{
                    dtu_standard = 0; 
                    dtu_premium = 0; 
                    vcore_gp = 0; 
                    vcore_bc = 0;
                    vcore_hs = 0; 
                    iaas_enterprise = 0;
                    iaas_standard = 0;
                    iaas_web = 0;
                    iaas_express = 0;
                    iaas_developer = 0;
                    }

    $serviceobjective_array = @{}
    
    $count = 0
    $db_count = 0
    $pool_count = 0
    $mi_count = 0
    

    Write-Host "`r`nGathering SQL Information, this may take some time depending on the number of resources" -ForegroundColor Cyan

    #Gathering all single databases and elastic pools
    $sqlservers = Get-AzSqlServer
    foreach ($sqlserver in $sqlservers) {
        
        
            #Get all the databases that are not DW, a Pool and not the master database
            $databases = Get-AzSqlDatabase -ServerName $sqlserver.ServerName $sqlserver.ResourceGroupName | 
                         Where-Object {$_.DatabaseName -ne 'master' `
                         -and $_.Edition -ne 'DataWarehouse' `
                         -and $_.SkuName -ne 'ElasticPool' `
                         -and $_.SkuName -notlike "GP_S*" `
                         } 
        
            #looping through every database
            foreach($db in $databases) {
                #Write-Host $db.DatabaseName $db.Edition $db.SkuName $db.CurrentServiceObjectiveName $db.Capacity

                $db_count++

                $core_array = PaaSCoreCalculator -Edition $db.Edition -Capacity $db.Capacity -CoreArray $core_array

                $singleton_slo = "Singleton_" + $db.Edition + "_" + $db.Capacity

                $serviceobjective_array = ServiceObjectiveCalculator -ServiceObjectiveName $singleton_slo -ServiceObjectiveArray $serviceobjective_array
                
            }

            #Going through all pools on the server
            $pools = Get-AzSqlElasticPool -ServerName $sqlserver.ServerName $sqlserver.ResourceGroupName
            foreach ($pool in $pools)
            {
                $pool_count++

                $core_array = PaaSCoreCalculator -Edition $pool.Edition -Capacity $pool.Capacity -CoreArray $core_array
                
                $pool_slo = "Pool_" + $pool.Edition + "_" + $pool.Capacity
                
                $serviceobjective_array = ServiceObjectiveCalculator -ServiceObjectiveName $pool_slo -ServiceObjectiveArray $serviceobjective_array
                
            }

            $count++;
            ProgressBar -Count $count

     }

     #Gathering All Managed Instances
     $managedInstances = Get-AzSqlInstance
     foreach ($instance in $managedInstances) 
     { 
         #Write-Host $instance.ManagedInstanceName $instance.Sku.Tier $instance.VCores
         $mi_count++
         $core_array = PaaSCoreCalculator -Edition $instance.Sku.Tier -Capacity $instance.VCores -CoreArray $core_array

         $mi_slo = "ManagedInstance_" + $instance.Sku.Tier + "_" + $instance.VCores
              
         $serviceobjective_array = ServiceObjectiveCalculator -ServiceObjectiveName $mi_slo -ServiceObjectiveArray $serviceobjective_array
   

         $count++;
         ProgressBar -Count $count
     }
 
    #loop through SQL registered VM's to get the size of the VM and the SQL edition

    $vm_count = 0; 

    $sql_vms = Get-AzSqlVM
     foreach ($vm in $sql_vms) 
     {
        $vm_details = Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name
        #Write-Host "Name: $($vm.Name), SQL Edition: $($vm.Sku), VM Size: $($vm_details.HardwareProfile.VmSize) `r`n"
        $vm_size = ($vm_details.HardwareProfile.VmSize -split '_') -replace "[^0-9]", '';
        $core_array = IaaSCoreCalculator -Edition $vm.Sku -Capacity $vm_size[1] -CoreArray $core_array
        $vm_count++;
        $count++;
        ProgressBar -Count $count
    
    }


    Clear-Host

    Write-Host "Results for Subscription: $($subinfo.Name)`r`n" -ForegroundColor Green

    Write-Host "SQL PaaS Summary" -ForegroundColor Yellow

    #Summary of all PaaS resources
    $summary_table = @( 
                        @{Resource="Singleton Databases"; "Total"=$db_count},
                        @{Resource="Elastic Pools"; "Total"=$pool_count},
                        @{Resource="Managed Instances"; "Total"=$mi_count}
                     )
    $summary_table | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize Resource, Total

    #Count of service Objectives for SQL PaaS objects
    $socount_table = @()
    foreach ($so in $serviceobjective_array.keys) {
        $socount_table += @{"Resource Tiers"=$so; "Count"=$serviceobjective_array[$so]}
    }

    $socount_table | ForEach {[PSCustomObject]$_} | Sort-Object "Resource Tiers" | Format-Table -AutoSize "Resource Tiers", "Count" 



    Write-Host "vCore" -ForegroundColor Cyan
    #Summary of all vCore counts
    $vcore_table = @( 
                        @{Edition="General Purpose"; "vCore Total"=$core_array["vcore_gp"]},
                        @{Edition="Business Critical"; "vCore Total"=$core_array["vcore_bc"]},
                        @{Edition="Hyperscale"; "vCore Total"=$core_array["vcore_hs"]}
                    )
    $vcore_table | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize Edition, "vCore Total"

    Write-Host "DTU" -ForegroundColor Cyan

    #Summary of all DTU counts
    $dtu_table = @( 
                        @{Edition="Standard/Basic"; "DTU Total"=$core_array["dtu_standard"]},
                        @{Edition="Premium"; "DTU Total"=$core_array["dtu_premium"]}
                    )
    $dtu_table | ForEach {[PSCustomObject]$_} |Format-Table -AutoSize Edition, "DTU Total"

    
    $dtu_ratio = @( 
                        @{Edition="Standard/Basic"; "vCore Conversion"=$core_array["dtu_standard"] / 100; "DTU/vCore Ratio"="100/1"},
                        @{Edition="Premium"; "vCore Conversion"=$core_array["dtu_premium"] / 125; "DTU/vCore Ratio"="125/1"}
                    )

    $dtu_ratio | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize Edition, "vCore Conversion", "DTU/vCore Ratio"
  
    Write-Host "`r`nSQL IaaS Summary" -ForegroundColor Yellow

    #Summary of all SQL IaaS VM's
    $iaas_summary_table = @( @{"SQL VM Count"=$vm_count} )
    $iaas_summary_table| ForEach {[PSCustomObject]$_} | Format-Table -AutoSize

    $iaas_core_table = @(
                                @{"SQL Edition"="Enterprise"; "Core Total"= $core_array["iaas_enterprise"]},
                                @{"SQL Edition"="Standard"; "Core Total"= $core_array["iaas_standard"]},
                                @{"SQL Edition"="Web"; "Core Total"= $core_array["iaas_web"]},
                                @{"SQL Edition"="Express"; "Core Total"= $core_array["iaas_express"]},
                                @{"SQL Edition"="Developer"; "Core Total"= $core_array["iaas_developer"]}
                            )
    $iaas_core_table | ForEach {[PSCustomObject]$_} | Format-Table -AutoSize "SQL Edition", "Core Total"

    
    while(1) {
        
        Write-Host -ForegroundColor Yellow "`r`nWould you like run on another Subscription? " -NoNewLine
        $continue = Read-Host "[Y/N]"

        if ($continue.ToLower() -eq 'y')
        { 
           MainFunction
        } elseif ($continue.ToLower() -eq 'n') {
           Write-Host -ForegroundColor Green "Exiting, thanks for stopping by"
           Exit
        } else {
          Write-Host -ForegroundColor Red "Invalid Selection"
        }
    }

}

MainFunction
