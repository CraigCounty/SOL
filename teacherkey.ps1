#for use on teacher computer to prep lab
#domain account needed so it can  be used on every computer. don't know how to get local admin to work on each machine with get-cred
#workflow needed for parallel, get-cred outside workflow as user interaction needed
#bitstransfer needed so creds can be used
#psexec needed as i'm too dumb to get psremoting to work on domain

function get-ipmac { #gets ip and mac from hostname of awake computer
    param
    (
        [parameter(mandatory = $true,
            valuefrompipeline = $true,
            position = 0)]
        [string[]]$computername
    )
    foreach ($inputmachine in $computername ) {
        if (!(test-connection -cn $inputmachine -quiet)) {
            write-host "$inputmachine : is offline`n" -backgroundcolor red
        }
        else {
            $macaddress = "n/a"
            $ipaddress = "n/a"
            $ipaddress = ([system.net.dns]::gethostbyname($inputmachine).addresslist[0]).ipaddresstostring
            $ipmac = get-wmiobject -class win32_networkadapterconfiguration -computername $inputmachine
            $macaddress = ($ipmac | where { $_.ipaddress -eq $ipaddress}).macaddress
            return $computername, $ipaddress, $macaddress
        }
    }
}

$room = read-host "room"

if (!(test-path ($rcsv = "$env:programdata\$room.csv"))) {
    ni $rcsv -fo
    $headers = "hostname", "ipaddress", "macaddress"
    $psObject = New-Object psobject
    foreach ($header in $headers) {
        Add-Member -InputObject $psobject -MemberType noteproperty -Name $header -Value ""
    }
    $psObject | Export-Csv ($rcsv = "$env:programdata\$room.csv") -NoTypeInformation
}

$acred = get-credential "ccps\z"
$scred = get-credential SOL

(iwr -useb raw.githubusercontent.com/craigcounty/sol/master/$room).content|out-file ($computers = "$env:tmp\$room.txt") #get list of computers in lab

$computers = get-content $computers

workflow enable-sol {
    param(
        [string[]]$computers,
        [string[]]$rcsv,
        $acred,
        $scred
    )
    $aun = $acred.username
    $apw = $acred.getnetworkcredential().password
    $sun = $scred.username
    $spw = $scred.getnetworkcredential().password
    foreach -parallel ($computer in $computers) {
        $ipmac = get-ipmac $computer
        $remove = import-csv $rcsv|where {$_.hostname -ne $computer}
        $remove|export-csv $rcsv -notypeinfo
        $hash = @{
            "hostname"   = ($ipmac[0]|out-string).trim()
            "ipaddress"  = $ipmac[1]
            "macaddress" = $ipmac[2]
        }
        $newRow = New-Object PsObject -Property $hash
        $newRow
        Export-Csv $rcsv -inputobject $newRow -append -Force -notypeinfo

        start-bitstransfer $env:programdata\authorized_keys \\$computer\c$\users\administrator\.ssh\ -credential $acred
        psexec \\$computer -u $aun -p $apw powershell -c "&{nlu $sun -password (convertto-securestring $spw -asplaintext -force);}"
    }
} enable-sol -computers $computers -rcsv $rcsv -acred $acred -scred $scred

#workflow adds extra headers, next will remove and sort
$sort = import-csv $rcsv|select hostname, ipaddress, macaddress -unique -ExcludeProperty PSComputerName, PSShowComputerName, PSSourceJobInstanceId|sort hostname
$sort|export-csv $rcsv -notype