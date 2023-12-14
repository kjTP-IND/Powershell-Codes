SetUserFTA HTTP ChromeHTML;
SetUserFTA HTTPS ChromeHTML;
SetUserFTA .HTML ChromeHTML;
SetUserFTA .HTM ChromeHTML;
SetUserFTA MAILTO Outlook.URL.mailto.15;
SetUserFTA .EML Outlook.URL.mailto.15;
SetUserFTA .PDF Acrobat.Document.DC;
Get-AppxPackage ClipChamp.Clipchamp | Remove-AppxPackage;
Get-AppxPackage Microsoft.ZuneVideo | Remove-AppxPackage;
Get-AppxPackage Microsoft.MicrosoftSolitaireCollection | Remove-AppxPackage;
Get-AppxPackage SpotifyAB.SpotifyMusic | Remove-AppxPackage;
Get-AppxPackage Microsoft.GamingApp | Remove-AppxPackage;
Get-AppxPackage Microsoft.Xbox.TCUI | Remove-AppxPackage;
Get-AppxPackage Microsoft.XboxApp | Remove-AppxPackage;
Get-AppxPackage Microsoft.MicrosoftOfficeHub | Remove-AppxPackage;
Get-AppxPackage Microsoft.ScreenSketch | Remove-AppxPackage;
Get-AppxPackage Microsoft.MixedReality.Portal | Remove-AppxPackage;

