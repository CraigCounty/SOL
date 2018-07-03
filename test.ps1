# sends magic packet for WOL to computer or group of computers and opens vnc

#add options for ssh, rdp, install msi, psexec
#ssh into switches

function wol {

    [CmdletBinding()]
    param(
        [string]$mac,
        [string]$ip = "255.255.255.255", # broadcast if not specified
        [int]$port = 9
    )

    $broadcast = [net.ipaddress]::parse($ip)
    $target = 0, 2, 4, 6, 8, 10 | % {[convert]::tobyte($mac.substring($_, 2), 16)}
    $packet = (, [byte]255 * 6) + ($target * 16)
    $udpclient = new-object system.net.sockets.udpclient
    $udpclient.connect($broadcast, $port)
    [void]$udpclient.send($packet, 102)

}

function z {

    [CmdletBinding()]
    param(
        [string]$selection,
        $c,
        [switch]$v,
        [switch]$w,
        [switch]$p,
        [switch]$d,
        [switch]$i
    )

    if (!$selection) {$selection = read-host "which?"}

    $pcs = import-csv '\\172.16.10.5\lists$\.master.csv'

    $pcs = ($pcs|where {$_.hostname -match $selection})

    $pcs|format-table

    pause

    $pcs|foreach {
        wol ($_.macaddress.replace("-", ""))
    }

    if ($v) {

        $pswd = read-host "pswd" -assecurestring
        $pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))

        $pcs|foreach {
            start 'C:\Program Files\TightVNC\tvnviewer.exe' -args  "-host=$($_.ipaddress)", "-password=$pswd"}

    }

    if ($p) {
        $user = (read-host "user")
        $pswd = read-host "pswd" -assecurestring
        $pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))
        if (!$c) {$c = (read-host "command")}
        workflow psexec {
            param(
                $pcs,
                $d,
                $i,
                $user,
                $pswd,
                $c
            )
            foreach -parallel ($pc in $pcs) {
                if ($d -and $i) {start "$env:programdata\chocolatey\bin\psexec.exe" -args "\\$($pc.ipaddress) -u $user -p $pswd -d -e -i cmd /c $c"}
                if ($i -and !$d) {start "$env:programdata\chocolatey\bin\psexec.exe" -args "\\$($pc.ipaddress) -u $user -p $pswd -e -i cmd /c $c"}
                if ($d -and !$i) {start "$env:programdata\chocolatey\bin\psexec.exe" -args "\\$($pc.ipaddress) -u $user -p $pswd -d -e cmd /c $c"}
                else {start "$env:programdata\chocolatey\bin\psexec.exe" -args "\\$($pc.ipaddress) -u $user -p $pswd -d -e cmd /c $c"}
                #echo $pc
            }
        } psexec -pcs $pcs -d $d -i $i -user $user -pswd $pswd -c $c
    }
}
