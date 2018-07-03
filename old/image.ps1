$hash = @{
    "hostname"   = $env:computername
    "ipaddress"  = ((get-netipaddress).ipaddress -match '^172.*'|out-string).trim()
    "macaddress" = (get-netadapter|where ifindex -match (get-netipaddress|where ipaddress -match '^172.*').interfaceindex).macaddress
    "login" = $env:username
    "dateTime" = (get-date|out-string).trim()
}
$newRow = New-Object PsObject -Property $hash
$remove = import-csv ($csv = "\\wsus\lists$\.master.csv")|where {$_.hostname -ne $hash.hostname}
$remove|export-csv $csv -notype
export-csv $csv -inputobject $newRow -append -force -notype