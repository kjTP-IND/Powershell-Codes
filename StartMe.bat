Powershell -noprofile -ExecutionPolicy Bypass -Command "& {Start-Process Powershell -ArgumentList -NoExit '-NoProfile -ExecutionPolicy Bypass -File ""& '.\%~dp0DefaultsAndRemoval.exe\'""' -Verb RunAs}"

