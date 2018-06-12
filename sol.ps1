#hidden script for public desktop on teacher computer
#copies lab key to temp folder to get correct permissions
#SOL creds set during labkey script
#github link is simple list of computers
cp $env:programdata\id_rsa $env:tmp
$pswd = get-credential SOL
$pswd = $pswd.getnetworkcredential().password
(iwr -useb raw.githubusercontent.com/craigcounty/sol/master/ms-lab).content|out-file ($computers = "$env:tmp\ms-lab.txt")
$computers = get-content $computers
workflow enable-sol {
    param(
        [string[]]$computers,
        $pswd
    )
    foreach -parallel ($computer in $computers) {
        ssh -o "StrictHostKeyChecking=no"-i $env:tmp\id_rsa administrator@$computer "powershell -c &{(gc `$env:programdata\solenable.reg)|%{`$_ -replace 'xxxxx', '$pswd'}|sc `$env:programdata\solenable.reg;regedit /s $env:programdata\solenable.reg;restart-computer -force}"
    }
} enable-sol -computers $computers -pswd $pswd