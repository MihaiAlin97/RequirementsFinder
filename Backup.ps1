$String="Set state PRUEFEN
Set speed to a valid value in message 1A1h from Auswahl panel
Set speed unit to km/h (PIA_KI_EINHEIT_WEG=0x01)
Check speed unit sent in message 1C0h
Repeat for mph (PIA_KI_EINHEIT_WEG=0x02)"

$tst=[System.Collections.ArrayList]@(Parser($String))
Write-Host $tst[4]





New-Object Contact("lens")