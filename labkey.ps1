#for use on lab computer
#creates new key, copies it to teacher computer programdata, adds it to authorized_keys, copies authorized_keys to teacher computer
#sets permissions on sol stuff to stop students
#restarting services and fixing permissions probably useless

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

$room = read-host "room"

$pcs = import-csv '\\172.16.10.5\lists$\.master.csv'

$pcs = ($pcs|where {$_.hostname -match $room})

$pcs|format-table

pause


if (!(test-path ($s = "$env:homedrive\users\administrator\.ssh"))) {ni $s -ty d -f >''}
cd ($cd = "$env:programfiles\openssh-win64")
if (!(test-path id_rsa)) {.\ssh-keygen.exe -t rsa -f id_rsa}
restart-service ssh-agent
restart-service sshd
.\ssh-add.exe id_rsa
$tc = $room + "-t"
net use t: \\$tc\c$\programdata
cp id_rsa t:
icacls t:\id_rsa /deny ccps\students:F
icacls $env:programdata\solenable.reg /deny ccps\students:F
icacls $env:programdata\solenable.ps1 /deny ccps\students:F
$p = read-host "local user 'sol' password" -assecure
#nlu SOL -password $p
#foreach computer
($ak = gc id_rsa.pub)|ac $s\authorized_keys
cp $s\authorized_keys t:

$pcs|foreach {
    wol ($_.macaddress.replace("-", ""))
}

workflow key {
    param(
        $pcs,
        $ak
    )
    foreach -parallel ($pc in $pcs) {
        $ak|ac \\$($pc.hostname)\c$\users\administrator\.ssh\authorized_keys
        cp id_rsa \\$($pc.hostname)\c$\programdata\id_rsa
    }
} key -pcs $pcs -ak $ak


(gc $env:programdata\ssh\sshd_config) | % {$_ -replace '#PasswordAuthentication yes', 'PasswordAuthentication no'} | sc $env:programdata\ssh\sshd_config
.\FixHostFilePermissions.ps1 -Confirm:$false
.\FixUserFilePermissions.ps1 -Confirm:$false
new-netfirewallrule -name sshd -displayname 'openssh server (sshd)' -enabled true -direction inbound -protocol tcp -action allow -localport 22 >''2>&1
restart-service ssh-agent
restart-service sshd
set-service ssh-agent -star automatic
set-service sshd -star automatic





















<#

$acred = Get-Credential
$aun = $acred.UserName
$apw = $acred.GetNetworkCredential().Password
$scred = Get-Credential
$sun = $scred.UserName
$spw = $scred.GetNetworkCredential().Password
new-psdrive a -psp filesystem \\vtest\c$\users\administrator\.ssh -cred $acred
cp $env:programdata\authorized_keys a: -force
psexec \\vtest -u $aun -p $apw powershell -c "&{nlu $sun -password (convertto-securestring $spw -asplaintext -force)}"
remove-psdrive a

foreach computer
cp $env:programdata\id_rsa $env:tmp
ssh -i ($id = "$env:tmp\id_rsa") administrator@$computer "powershell -c &{"

sp "hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "AutoAdminLogon" "1"
sp "hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" "DefaultUserName" "sol"
sp "DefaultPassword"="$p"



cp $env:programdata\id_rsa $env:tmp
$pswd = get-credential SOL
$pswd = $pswd.getnetworkcredential().password
ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@vtest "powershell -c &{(gc `$env:programdata\solenable.reg)|%{`$_ -replace 'xxxxx', '$pswd'}|sc `$env:programdata\solenable.reg;regedit /s $env:programdata\solenable.reg;restart-computer -force}"


cp $env:programdata\id_rsa $env:tmp
$pswd = Read-Host -Prompt "Enter password" -AsSecureString
$pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))
ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@vtest "powershell -c &{(gc `$env:programdata\solenable.reg)|%{`$_ -replace 'xxxxx', '$pswd'}|sc `$env:programdata\solenable.reg;regedit /s $env:programdata\solenable.reg;restart-computer -force}"


cp $env:programdata\id_rsa $env:tmp
$pswd = Read-Host -Prompt "Enter password" -AsSecureString
$pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))
ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@desktop "powershell -c &{(gc `$env:programdata\SOLEnable.reg)|%{`$_ -replace 'xxxxx', '$pswd'}|sc `$env:programdata\solenable.reg;regedit /s $env:programdata\solenable.reg;restart-computer -force}"#>