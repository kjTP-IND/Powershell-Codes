@{
    Root = 'c:\Users\TPADMIN\OneDrive - K&J Communications, Inc\Documents\Powershell Codes\DefaultAndRemoval.ps1'
    OutputPath = 'c:\Users\TPADMIN\OneDrive - K&J Communications, Inc\Documents\Powershell Codes\out'
    Package = @{
        Enabled = $true
        Obfuscate = $false
        HideConsoleWindow = $false
        DotNetVersion = 'v4.6.2'
        FileVersion = '1.0.0'
        FileDescription = ''
        ProductName = ''
        ProductVersion = ''
        Copyright = ''
        RequireElevation = $false
        ApplicationIconPath = ''
        PackageType = 'Console'
    }
    Bundle = @{
        Enabled = $true
        Modules = $true
        # IgnoredModules = @()
    }
}
        