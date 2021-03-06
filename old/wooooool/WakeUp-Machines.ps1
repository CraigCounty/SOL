#######################################################
##
## WakeUp-Machines.ps1, v1.0, 2012
##
## Created by Matthijs ten Seldam, Microsoft
##
#######################################################

<#
.SYNOPSIS
Starts a list of physical machines by using Wake On LAN.

.DESCRIPTION
WakeUp-Machines starts a list of servers using a Wake On LAN tool. It then sends echo requests to verify that the machine has TCP/IP connectivity. It waits for a specified amount of echo replies before starting the next machine in the list.

.PARAMETER Machines
The name of the file containing the machines to wake.

.PARAMETER Interface
The IP address of the interface to use to wake up the machines.

.PARAMETER Subnet
The subnet mask of the interface to use to wake up the machines.

.EXAMPLE
WakeUp-Machines machines.csv 192.168.0.1 255.255.255.0

.EXAMPLE
WakeUp-Machines c:\tools\machines.csv 192.168.0.1 255.255.255.0

.INPUTS
None

.OUTPUTS
None

.NOTES
Make sure the Wake On LAN command line tool is available in the same location as the script!

The CSV file with machines must be outlined using Name, MAC Address and IP Address with the first line being Name,MacAddress,IpAddress.
See below for an example of a properly formatted CSV file.

Name,MacAddress,IpAddress
Host1,A0DEF169BE02,192.168.0.11
Host3,AC1708486CA2,192.168.0.12
Host2,FDDEF15D5401,192.168.0.13

.LINK
http://blogs.technet.com/matthts
#>


param(
    [Parameter(Mandatory=$true, HelpMessage="Provide the path to the CSV file containing the machines to wake.")]
    [string] $Machines, 
    [Parameter(Mandatory=$true, HelpMessage="Provide the IP address of the interface to use for Wake On LAN.")]
    [string] $Interface,
    [Parameter(Mandatory=$true, HelpMessage="Provide the subnet mask of the interface to use for Wake On LAN.")]
    [string] $Subnet
    )


## Predefined variables
$WolCmd=".\wolcmd.exe"
$TimeOut = 30
$Replies = 10

clear;Write-Host

## Verify if WOL tool exists
try
{
    Get-ChildItem $WolCmd | Out-Null
}
Catch
{
    Write-Host "$WolCmd file not found!";Write-Host
    exit
}

## Read CSV file with machine names
try
{
    $File=Import-Csv $Machines
}
Catch
{
    Write-Host "$Machines file not found!";Write-Host
    exit
}


$i=1
foreach($Machine in $File)
{
    $Name=$Machine.Name
    $MAC=$Machine.MacAddress
    $IP=$Machine.IpAddress

    ## Send magic packet to wake machine
    Write-Progress -ID 1 -Activity "Waking up machine $Name" -PercentComplete ($i*100/$file.Count)
    Invoke-Expression "$WolCmd $MAC $Interface $Subnet" | Out-Null

    $j=1
    ## Go into loop until machine replies to echo
    $Ping = New-Object System.Net.NetworkInformation.Ping
    do
    {
        $Echo = $Ping.Send($IP)
        Write-Progress -ID 2 -ParentID 1 -Activity "Waiting for $Name to respond to echo" -PercentComplete ($j*100/$TimeOut)
        sleep 1
        
        if ($j -eq $TimeOut)
        {
            Write-Host "Time out expired, aborting.";Write-Host
            exit
        }
        $j++
    }
    while ($Echo.Status.ToString() -ne "Success" )

    ## Machine is alive, keep sending for $Replies amount
    for ($k = 1; $k -le $Replies; $k++) 
    { 
       Write-Progress -ID 2 -ParentID 1 -Activity "Waiting for $Name to respond to echo" -PercentComplete (100) 
       Write-Progress -Id 3 -ParentId 2 -Activity "Receiving echo reply"  -PercentComplete ($k*100/$Replies)
       sleep 1
    }
    $i++
    Write-Progress -Id 3 -Completed $true
    $Ping=$null
}


