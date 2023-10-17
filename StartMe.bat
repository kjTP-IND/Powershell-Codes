Powershell -noprofile -ExecutionPolicy Bypass -NoExit -Command "& {Start-Process Powershell -ArgumentList '-NoProfile -NoExit -ExecutionPolicy Bypass -File ""\%~dp0DefaultsAndRemoval.exe\""' -Verb RunAs}"

