cp $env:programdata\id_rsa $env:tmp
$pswd = get-credential SOL
$pswd = $pswd.getnetworkcredential().password
$computers = (iwr -useb raw.githubusercontent.com/craigcounty/sol/master/ms-lab).content
ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@$computers "powershell -c &{(gc `$env:programdata\solenable.reg)|%{`$_ -replace 'xxxxx', '$pswd'}|sc `$env:programdata\solenable.reg;regedit /s $env:programdata\solenable.reg;restart-computer -force}"