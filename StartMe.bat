Powershell.exe -noprofile -ExecutionPolicy Bypass -NoExit -Command "&{Start-Process Powershell.exe -ArgumentList -File '\"%~dp0DefaultAndRemoval.ps1\"' -Verb RunAs}"

