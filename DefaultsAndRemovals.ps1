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