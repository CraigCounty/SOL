$pswd = Read-Host -Prompt "Enter password" -AsSecureString
$pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))
psexec -u administrator \\vtest -p $pswd cmd /c "powershell -c sp -path 'hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -name 'DefaultPassword' -value $pswd && regedit /s \\fs1\public\grouppolicy\test.reg"
shutdown -m \\vtest /r /t 0
try{psexec -u ccps\soltesting  \\vtest -p $pswd cmd /c "regedit /s \\fs1\public\grouppolicy\soldisable.reg"} catch {sleep -s 1}

$pswd = Read-Host -Prompt "Enter password" -AsSecureString
$pswd = [system.runtime.interopservices.marshal]::ptrtostringauto([system.runtime.interopservices.marshal]::securestringtobstr($pswd))
psexec -u ccps\soltesting  \\vtest -p $pswd cmd /c "regedit /s \\fs1\public\grouppolicy\soldisable.reg"