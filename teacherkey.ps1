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

#create csv for ips/macs if it doesn't exist
if (!(test-path ($roomCsv = "$env:programdata\$room.csv"))) {
    ni $roomCsv -fo
    $headers = "hostname", "ipaddress", "macaddress"
    $psobject = new-object psobject
    foreach ($header in $headers) {
        add-member -inputobject $psobject -membertype noteproperty -name $header -value ""
    }
    $psObject | export-csv ($roomCsv = "$env:programdata\$room.csv") -notype
}

#get credentials
$acred = get-credential "ccps\z"
$scred = get-credential SOL

#get list of computers in lab
(iwr -useb raw.githubusercontent.com/craigcounty/sol/master/lists/$room).content|out-file ($computers = "$env:tmp\$room.txt")
$computers = get-content $computers

workflow enable-sol {
    param(
        [string[]]$computers,
        [string[]]$roomCsv,
        $acred,
        $scred
    )
    $aun = $acred.username
    $apw = $acred.getnetworkcredential().password
    $sun = $scred.username
    $spw = $scred.getnetworkcredential().password
    $array = @()

    #this is magic
    foreach -parallel ($computer in $computers) {
        $ipmac = get-ipmac $computer
        $hash = @{
            "hostname"   = ($ipmac[0]|out-string).trim()
            "ipaddress"  = $ipmac[1]
            "macaddress" = $ipmac[2]
        }
        $newRow = New-Object PsObject -Property $hash
        $workflow:array += $newRow
    }
    return $array
}

#remove entries to update
$array = enable-sol -computers $computers -roomCsv $roomCsv -acred $acred -scred $scred
foreach ($a in $array){
    $remove = import-csv $roomCsv|where {$_.hostname -ne $a.hostname}
    $remove|export-csv $roomCsv -notypeinfo
    export-esv $roomCsv -inputobject $a -append -force -notypeinfo
}

#workflow adds extra headers, next will remove and sort
$sort = import-csv $roomCsv|select hostname, ipaddress, macaddress -unique -ExcludeProperty PSComputerName, PSShowComputerName, PSSourceJobInstanceId|sort hostname
$sort|export-csv $roomCsv -notype