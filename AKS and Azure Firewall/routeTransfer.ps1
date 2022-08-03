[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$subscriptionId = "xxxx-xxxx-subId-xxxx-xxxx",
    [Parameter(Mandatory=$false)]
    [string]$avxGwRtName = "av-gw-az-transit-firenet-dmz-firewall",
    [Parameter(Mandatory=$false)]
    [string]$avxHaGwRtName = "av-gw-az-transit-firenet-hagw-dmz-firewall",
    [Parameter(Mandatory=$false)]
    [string]$avxGwRtRgName = "az-avtx-rg",
    [Parameter(Mandatory=$false)]
    [string]$azFwRtName = "az-fw-rt",
    [Parameter(Mandatory=$false)]
    [string]$azFwRtRgName = "az-avtx-rg",
    [Parameter(Mandatory=$false)]
    [string]$azFwIlbIp = "10.0.3.4",
    [Parameter(Mandatory=$false)]
    [string]$avxGwFwIp = "10.0.0.69"
)
try {
    Set-AzContext -Subscription $subscriptionId
}
catch {
    "Unable to connect to subscription $subscriptionId, check that the Azure Function has a managed identity and correct permissions over the specified subscription"
}

try {
    $avxGwRtBackup = Get-AzRouteTable -Name $avxGwRtName -ResourceGroupName $avxGwRtRgName
    $avxHaGwRtBackup = Get-AzRouteTable -Name $avxHaGwRtName -ResourceGroupName $avxGwRtRgName
    $azFwRtBackup = Get-AzRouteTable -Name $azFwRtName -ResourceGroupName $azFwRtRgName
}
catch {
    "Unable to retrieve route table information with provided parameters."
}

try {
    $avxGwRt = Get-AzRouteTable -Name $avxGwRtName -ResourceGroupName $avxGwRtRgName
    $avxHaGwRt = Get-AzRouteTable -Name $avxHaGwRtName -ResourceGroupName $avxGwRtRgName

    Write-Host "Checking Aviatrix Gateway routes..."
    foreach ($route in $avxGwRtBackup.Routes)
    {
        if ($route.Name -match "avx")
        {
            if ($route.NextHopIpAddress -eq $azFwIlbIp)
            {
                Write-Host "AvxGw - No need to change IP for route"$route.Name
            }
            else {
                Write-Host "AvxGw - Changing NextHopIp for route"$route.Name"from"$route.NextHopIpAddress"to"$azFwIlbIp
                $avxGwRt | Set-AzRouteConfig -Name $route.Name -AddressPrefix $route.AddressPrefix -NextHopType $route.NextHopType -NextHopIpAddress $azFwIlbIp | Out-null
            }
        }
        else {
            Write-Host "AvxGw - Route"$route.Name"is not an Aviatrix managed route......skipping"
        }
    }

    Write-Host "Checking Aviatrix HA Gateway routes..."

    foreach ($haRoute in $avxHaGwRtBackup.Routes)
    {
        if ($haRoute.Name -match "avx")
        {
            if ($haRoute.NextHopIpAddress -eq $azFwIlbIp)
            {
                Write-Host "AvxHaGw - No need to change IP for route"$haRoute.Name
            }
            else {
                Write-Host "AvxHaGw - Changing NextHopIp for route"$haRoute.Name"from"$haRoute.NextHopIpAddress"to"$azFwIlbIp
                $avxHaGwRt | Set-AzRouteConfig -Name $haRoute.Name -AddressPrefix $haRoute.AddressPrefix -NextHopType $haRoute.NextHopType -NextHopIpAddress $azFwIlbIp | Out-null
            }
        }
        else {
            Write-Host "AvxHaGw - Route"$haRoute.Name"is not an Aviatrix managed route......skipping"
        }
    }

    #Check if any changes have been made and then commit changes to the Avx primary and HA Route Table
    if ($avxGwRt.Routes -ne $avxGwRtBackup.Routes)
    {
        Set-AzRouteTable -RouteTable $avxGwRt | Out-Null
    }

    if ($avxHaGwRt.Routes -ne $avxHaGwRtBackup.Routes)
    {
        Set-AzRouteTable -RouteTable $avxHaGwRt | Out-Null
    }
}
catch {
    "Unable to change the NextHopIp of one or more routes....reverting changes"
    Set-AzRouteTable -RouteTable $avxGwRtBackup | Out-Null
    Set-AzRouteTable -RouteTable $avxHaGwRtBackup | Out-Null
}


try {
    #This will part of the script is necessary If Azure Firewall is in the same VNET as Firenet Transit
    #If Azure Firewall is in a separate VNET, then just configure the RFC1918 address space with next hop > Transit Firenet Eth1
    #Additionally, if AzFw is in a separate VNET, we need to exclude the VNET CIDR from the routes to add to AzFw RT to prevent routing loop
    $azFwRt = Get-AzRouteTable -Name $azFwRtName -ResourceGroupName $azFwRtRgName
    Write-Host "Checking routes to add from"$avxGwRt.Name"to"$azFwRt.Name
    $avxGwRtRoutes = (Get-AzRouteTable -Name $avxGwRtName -ResourceGroupName $avxGwRtRgName).Routes | Where-Object {($_.Name -match "avx") -and ($_.AddressPrefix -ne "0.0.0.0/0")}
    $azFwRtRoutes = (Get-AzRouteTable -Name $azFwRtName -ResourceGroupName $azFwRtRgName).Routes | Where-Object {($_.Name -match "avx") -and ($_.AddressPrefix -ne "0.0.0.0/0")}
    foreach ($avxGwRtRoute in $avxGwRtRoutes)
    {
        $avxGwRtRoute.NextHopIpAddress = $avxGwFwIp
        if ($avxGwRtRoute.AddressPrefix -notin ($azFwRtRoutes | Select-Object -expand AddressPrefix))
        {
            Write-Host "Route"$avxGwRtRoute.Name"will be added to"$azFwRt.Name
            $azFwRt | Add-AzRouteConfig -Name $avxGwRtRoute.Name -AddressPrefix $avxGwRtRoute.AddressPrefix -NextHopType $avxGwRtRoute.NextHopType -NextHopIpAddress $avxGwRtRoute.NextHopIpAddress
        }
        else {
            Write-Host $avxGwRtRoute.Name"already exists in"$azFwRt.Name
        }
    }
    #Committing changes to the AzFw Route Table
    Set-AzRouteTable -RouteTable $azFwRt | Out-null
}
catch {
    "Unable to add one or more routes from source route table to destination route table.....reverting changes"
    #Rolling back to original state of route table
    Set-AzRouteTable -RouteTable $azFwRtBackup | Out-Null
}