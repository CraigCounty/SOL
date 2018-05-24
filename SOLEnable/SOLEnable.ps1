cp $env:programdata\id_rsa $env:tmp
$pswd = Read-Host -Prompt "Enter password" -AsSecureString
$pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))
ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@vtest "powershell -c &{(gc `$env:programdata\solenable.reg)|%{`$_ -replace 'xxxxx', '$pswd'}|sc `$env:programdata\solenable.reg;regedit /s $env:programdata\solenable.reg;restart-computer -force}"