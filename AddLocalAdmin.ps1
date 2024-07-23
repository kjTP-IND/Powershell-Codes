Clear-Host
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

#User to search for
$USERNAME = 'kjadmin'

#Declare LocalUser Object
$ObjLocalUser = $null

#Password
$Password = ConvertTo-SecureString 'kjKJ513920' -AsPlainText -Force

try {
    Write-Verbose "Searching for $($USERNAME) in LocalUser DataBase."
    $ObjLocalUser = Get-LocalUser $USERNAME
    Write-Verbose "User $($USERNAME) was found"
}
catch [Microsoft.PowerShell.Commands.UserNotFoundException]{
    "User $($USERNAME) was not found" | Write-Warning
}
catch {
    "An unspecified error occured." | Write-Error
    Exit #Stop Powershell
}

#Create the user if not found
if (!$ObjLocalUser) {
    Write-Verbose "Creating user $($USERNAME)"
    New-LocalUser -Name $USERNAME -Password $Password
    Add-LocalGroupMember -Group "Administrators" -Member $USERNAME
}