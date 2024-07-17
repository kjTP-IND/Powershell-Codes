$VIC = Get-Item "C:\Users\ss-it\Accountable Physician Advisors LLC\ARCS Operations - PBI\VIC Files\VIC Bills Timing Report.xlsx"
$Hill = Get-Item "C:\Users\ss-it\Accountable Physician Advisors LLC\ARCS Operations - PBI\Hill Files\Hill Bills Timing Report.xlsx"
$SCS = Get-Item "C:\Users\ss-it\Accountable Physician Advisors LLC\ARCS Operations - PBI\SCS Files\SCS Bills Timing Report.xlsx"
$VIVE = Get-Item "C:\Users\ss-it\Accountable Physician Advisors LLC\ARCS Operations - PBI\VIVE Files\COVC Bills Timing Report.xlsx"
$OVS = Get-Item "C:\Users\ss-it\Accountable Physician Advisors LLC\ARCS Operations - PBI\OVS Files\OVS Bills Timing Report.xlsx"
$STVI = Get-Item "C:\Users\ss-it\Accountable Physician Advisors LLC\ARCS Operations - PBI\STVI Files\STVI Bills Timing Report.xlsx"

$folders = @($VIC, $Hill, $SCS, $VIVE, $OVS, $STVI)

$files = @()

foreach ($folder in $folders) {
    if ($folder.LastWriteTime -gt (Get-Date).AddHours(-24)) {
        #$files += Split-Path -Path $folder -Leaf
    } else {
        
        $files += Split-Path -Path $folder -Parent | Split-Path -Leaf
    }
}

Write-Output $files