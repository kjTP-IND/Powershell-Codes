#Download Chocolatey and install SetUserFTA
#As ADMIN
Set-ExecutionPolicy bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'));
choco install setuserfta -Force -Confirm:$False;
$Credentials = Get-Credential
#AS Local User
$ProcessJob = Start-Job -Credential $Credentials -ScriptBlock {
    SetUserFTA HTTP ChromeHTML;
    SetUserFTA HTTPS ChromeHTML;
    SetUserFTA .HTML ChromeHTML;
    SetUserFTA .HTM ChromeHTML;
    SetUserFTA MAILTO Outlook.URL.mailto.15;
    SetUserFTA .EML Outlook.URL.mailto.15;
    SetUserFTA .PDF AcroExch.Document.DC;
    Get-AppxPackage ClipChamp.Clipchamp | Remove-AppxPackage;
    Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage;
    Get-AppxPackage Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage;
    Get-AppxPackage SpotifyAB.SpotifyMusic | Remove-AppxPackage;
    Get-AppxPackage Microsoft.GamingApp | Remove-AppxPackage;
    Get-AppxPackage Microsoft.Xbox.TCUI | Remove-AppxPackage;
    Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage;
};
Wait-Job $ProcessJob;
Get-Job;
#As ADMIN
choco uninstall setuserfta -Force;
remove-item 'C:\ProgramData\chocolatey\' -Recurse -Force -Confirm:$False; 
remove-item 'C:\ProgramData\ChocolateyHttpCache\' -Recurse -Force -Confirm:$False;
set-executionpolicy -scope process restricted -Force