#hidden script for public desktop on teacher computer
#copies lab key to temp folder to get correct permissions
#SOL creds set during labkey script
#github link is simple list of computers

function wol {
    [cmdletbinding()]
    param(
        [parameter(mandatory = $true, position = 1)]
        [string]$mac,
        [string]$ip = "255.255.255.255",
        [int]$port = 9
    )
    $broadcast = [net.ipaddress]::parse($ip)

    $mac = (($mac.replace(":", "")).replace("-", "")).replace(".", "")
    $target = 0, 2, 4, 6, 8, 10 | % {[convert]::tobyte($mac.substring($_, 2), 16)}
    $packet = (, [byte]255 * 6) + ($target * 16)

    $udpclient = new-object system.net.sockets.udpclient
    $udpclient.connect($broadcast, $port)
    [void]$udpclient.send($packet, 102)
}

$pcs = import-csv '\\172.16.10.5\lists$\.master.csv'

$pcs = ($pcs|where {$_.hostname -match "hs-lab"}|where {$_.hostname -notmatch "-t"})

$pcs|foreach {
    wol ($_.macaddress.replace("-", ""))
}

#import-csv "$env:programdata\ms-lab.csv"|foreach {send-wol $_.mac}
$pcs = $pcs.hostname
cp $env:programdata\id_rsa $env:tmp
$pswd = get-credential SOL
$pswd = $pswd.getnetworkcredential().password
#(iwr -useb raw.githubusercontent.com/craigcounty/sol/master/ms-lab).content|out-file ($computers = "$env:tmp\ms-lab.txt")
#$computers = get-content $computers
workflow enable-sol {
    param(
        [string[]]$computers,
        $pswd
    )
    foreach -parallel ($computer in $computers) {
        echo $computer
        ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@$computer "powershell -c shutdown /r /t 0"
    }
} enable-sol -computers $pcs -pswd $pswd









<#
#hidden script for public desktop on teacher computer
#copies lab key to temp folder to get correct permissions
#SOL creds set during labkey script
#github link is simple list of computers

function wol {
    [cmdletbinding()]
    param(
        [parameter(mandatory = $true, position = 1)]
        [string]$mac,
        [string]$ip = "255.255.255.255",
        [int]$port = 9
    )
    $broadcast = [net.ipaddress]::parse($ip)

    $mac = (($mac.replace(":", "")).replace("-", "")).replace(".", "")
    $target = 0, 2, 4, 6, 8, 10 | % {[convert]::tobyte($mac.substring($_, 2), 16)}
    $packet = (, [byte]255 * 6) + ($target * 16)

    $udpclient = new-object system.net.sockets.udpclient
    $udpclient.connect($broadcast, $port)
    [void]$udpclient.send($packet, 102)
}

$pcs = import-csv '\\172.16.10.5\lists$\.master.csv'

$pcs = ($pcs|where {$_.hostname -match "hs-lab-01"}|where {$_.hostname -notmatch "-t"})

$pcs|foreach {
    wol ($_.macaddress.replace("-", ""))
}

#import-csv "$env:programdata\ms-lab.csv"|foreach {send-wol $_.mac}
$pcs = $pcs.hostname
cp $env:programdata\id_rsa $env:tmp
$pswd = get-credential SOL
$pswd = $pswd.getnetworkcredential().password
#(iwr -useb raw.githubusercontent.com/craigcounty/sol/master/ms-lab).content|out-file ($computers = "$env:tmp\ms-lab.txt")
#$computers = get-content $computers
workflow enable-sol {
    param(
        [string[]]$computers,
        $pswd
    )
    foreach -parallel ($computer in $computers) {
        echo $computer
        ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@$computer "powershell -c shutdown /r /t 0"
    }
} enable-sol -computers $pcs -pswd $pswd
#>