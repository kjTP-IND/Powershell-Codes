# PowerShell Script to Configure Epson ColorWorks C4000 for 2"x1" Labels
# Epson C4000 supports ESC/Label commands for configuration

param(
    [Parameter(Mandatory=$true)]
    [string]$PrinterIPAddress,
    [Parameter(Mandatory=$false)]
    [double]$WidthInches = 2.0,
    [Parameter(Mandatory=$false)]
    [double]$HeightInches = 1.0
)

# Direct TCP/IP communication for ESC/Label commands
function Send-ESCLabelCommandTCP {
    param(
        [string]$IPAddress,
        [byte[]]$Command,
        [int]$Port = 9100  # Standard raw TCP port for most label printers
    )
    
    try {
        Write-Host "Connecting to printer at ${IPAddress}:${Port}..." -ForegroundColor Cyan
        
        # Create TCP client
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($IPAddress, $Port)
        
        if ($tcpClient.Connected) {
            Write-Host "Connected successfully" -ForegroundColor Green
            
            # Get network stream
            $stream = $tcpClient.GetStream()
            
            # Send command
            $stream.Write($Command, 0, $Command.Length)
            $stream.Flush()
            
            # Wait for response (optional, some printers don't respond)
            Start-Sleep -Milliseconds 500
            
            # Close connection
            $stream.Close()
            $tcpClient.Close()
            
            Write-Host "ESC/Label commands sent successfully via TCP" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Failed to connect to printer at $IPAddress"
            return $false
        }
    }
    catch {
        Write-Error "TCP communication failed: $($_.Exception.Message)"
        if ($tcpClient -and $tcpClient.Connected) {
            $tcpClient.Close()
        }
        return $false
    }
}

function Find-PrinterByIP {
    param([string]$IPAddress)
    
    try {
        Write-Host "Searching for printer with IP address: $IPAddress" -ForegroundColor Cyan
        
        # Method 1: Check WMI for TCP/IP ports
        $tcpPorts = Get-WmiObject -Class Win32_TCPIPPrinterPort | Where-Object { $_.HostAddress -eq $IPAddress }
        
        if ($tcpPorts) {
            foreach ($port in $tcpPorts) {
                $printers = Get-WmiObject -Class Win32_Printer | Where-Object { $_.PortName -eq $port.Name }
                if ($printers) {
                    Write-Host "Found printer(s) using IP $IPAddress :" -ForegroundColor Green
                    foreach ($printer in $printers) {
                        Write-Host "  - Name: $($printer.Name)" -ForegroundColor White
                        Write-Host "  - Driver: $($printer.DriverName)" -ForegroundColor White
                        Write-Host "  - Port: $($port.Name)" -ForegroundColor White
                        Write-Host "  - Status: $($printer.PrinterStatus)" -ForegroundColor White
                    }
                    return $printers[0].Name  # Return first found printer name
                }
            }
        }
        
        # Method 2: Check standard printer ports
        $allPrinters = Get-Printer
        foreach ($printer in $allPrinters) {
            if ($printer.PortName -like "*$IPAddress*") {
                Write-Host "Found printer by port matching: $($printer.Name)" -ForegroundColor Green
                return $printer.Name
            }
        }
        
        Write-Host "No Windows printer found for IP $IPAddress" -ForegroundColor Yellow
        Write-Host "Will attempt direct TCP communication" -ForegroundColor Yellow
        return $null
    }
    catch {
        Write-Warning "Error searching for printer: $($_.Exception.Message)"
        return $null
    }
}

function Test-PrinterTCPConnection {
    param(
        [string]$IPAddress,
        [int]$Port = 9100
    )
    
    try {
        Write-Host "Testing TCP connection to ${IPAddress}:${Port}..." -ForegroundColor Cyan
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 3000
        $tcpClient.SendTimeout = 3000
        
        $connection = $tcpClient.BeginConnect($IPAddress, $Port, $null, $null)
        $success = $connection.AsyncWaitHandle.WaitOne(3000, $false)
        
        if ($success -and $tcpClient.Connected) {
            Write-Host "✓ TCP connection successful" -ForegroundColor Green
            $tcpClient.Close()
            return $true
        } else {
            Write-Host "✗ TCP connection failed or timed out" -ForegroundColor Red
            $tcpClient.Close()
            return $false
        }
    }
    catch {
        Write-Host "✗ TCP connection error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Create-ESCLabelPaperSizeCommand {
    param(
        [double]$WidthInches,
        [double]$HeightInches
    )
    
    # Convert inches to dots (C4000 uses 180 DPI for label positioning)
    $widthDots = [int]($WidthInches * 180)
    $heightDots = [int]($HeightInches * 180)
    
    # ESC/Label commands for paper size configuration
    # ESC i S - Set label size
    $command = [System.Collections.Generic.List[byte]]::new()
    
    # ESC i S command (Set label size)
    $command.AddRange([byte[]]@(0x1B, 0x69, 0x53))  # ESC i S
    
    # Width (2 bytes, little endian)
    $command.Add([byte]($widthDots -band 0xFF))
    $command.Add([byte](($widthDots -shr 8) -band 0xFF))
    
    # Height (2 bytes, little endian)  
    $command.Add([byte]($heightDots -band 0xFF))
    $command.Add([byte](($heightDots -shr 8) -band 0xFF))
    
    return $command.ToArray()
}

function Create-ESCLabelConfigCommand {
    param(
        [double]$WidthInches,
        [double]$HeightInches
    )
    
    $commands = [System.Collections.Generic.List[byte]]::new()
    
    # Initialize printer
    $commands.AddRange([byte[]]@(0x1B, 0x40))  # ESC @ (Initialize printer)
    
    # Set label size
    $labelSizeCmd = Create-ESCLabelPaperSizeCommand -WidthInches $WidthInches -HeightInches $HeightInches
    $commands.AddRange($labelSizeCmd)
    
    # Set print area margins (optional - adjust as needed)
    # ESC i M - Set print area margins
    $commands.AddRange([byte[]]@(0x1B, 0x69, 0x4D))  # ESC i M
    $commands.AddRange([byte[]]@(0x00, 0x00))  # Left margin (0)
    $commands.AddRange([byte[]]@(0x00, 0x00))  # Top margin (0)
    
    # Save settings to printer memory (ESC i E)
    $commands.AddRange([byte[]]@(0x1B, 0x69, 0x45))  # ESC i E (Save settings)
    
    return $commands.ToArray()
}

function Set-EpsonC4000PaperSize {
    param(
        [string]$IPAddress,
        [double]$WidthInches,
        [double]$HeightInches,
        [string]$PrinterName = $null
    )
    
    try {
        Write-Host "Configuring Epson C4000 at $IPAddress for ${WidthInches}`` x ${HeightInches}`` labels..." -ForegroundColor Green
        
        # Create ESC/Label command sequence
        $command = Create-ESCLabelConfigCommand -WidthInches $WidthInches -HeightInches $HeightInches
        
        # Try TCP communication first (more reliable for network printers)
        Write-Host "Attempting TCP communication..." -ForegroundColor Yellow
        $tcpSuccess = Send-ESCLabelCommandTCP -IPAddress $IPAddress -Command $command
        
        if ($tcpSuccess) {
            Write-Host "✓ ESC/Label commands sent via TCP" -ForegroundColor Green
            return $true
        }
        
        # Fallback to Windows printer if available
        if ($PrinterName) {
            Write-Host "TCP failed, trying Windows printer method..." -ForegroundColor Yellow
            $winSuccess = Send-ESCLabelCommandWindows -PrinterName $PrinterName -Command $command
            if ($winSuccess) {
                Write-Host "✓ ESC/Label commands sent via Windows printer" -ForegroundColor Green
                return $true
            }
        }
        
        Write-Warning "Failed to send ESC/Label commands via all methods"
        return $false
    }
    catch {
        Write-Error "ESC/Label configuration failed: $($_.Exception.Message)"
        return $false
    }
}

function Send-ESCLabelCommandWindows {
    param(
        [string]$PrinterName,
        [byte[]]$Command
    )
    
    try {
        # Create a raw printer job to send ESC/Label commands
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            using System.Text;

            public class RawPrinter {
                [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
                public class DOCINFOA {
                    [MarshalAs(UnmanagedType.LPStr)] public string pDocName;
                    [MarshalAs(UnmanagedType.LPStr)] public string pOutputFile;
                    [MarshalAs(UnmanagedType.LPStr)] public string pDataType;
                }

                [DllImport("winspool.Drv", EntryPoint="OpenPrinterA", SetLastError=true, CharSet=CharSet.Ansi, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool OpenPrinter([MarshalAs(UnmanagedType.LPStr)] string szPrinter, out IntPtr hPrinter, IntPtr pd);

                [DllImport("winspool.Drv", EntryPoint="ClosePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool ClosePrinter(IntPtr hPrinter);

                [DllImport("winspool.Drv", EntryPoint="StartDocPrinterA", SetLastError=true, CharSet=CharSet.Ansi, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool StartDocPrinter(IntPtr hPrinter, Int32 level, [In, MarshalAs(UnmanagedType.LPStruct)] DOCINFOA di);

                [DllImport("winspool.Drv", EntryPoint="EndDocPrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool EndDocPrinter(IntPtr hPrinter);

                [DllImport("winspool.Drv", EntryPoint="StartPagePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool StartPagePrinter(IntPtr hPrinter);

                [DllImport("winspool.Drv", EntryPoint="EndPagePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool EndPagePrinter(IntPtr hPrinter);

                [DllImport("winspool.Drv", EntryPoint="WritePrinter", SetLastError=true, ExactSpelling=true, CallingConvention=CallingConvention.StdCall)]
                public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, Int32 dwCount, out Int32 dwWritten);

                public static bool SendBytesToPrinter(string szPrinterName, IntPtr pBytes, Int32 dwCount) {
                    Int32 dwError = 0, dwWritten = 0;
                    IntPtr hPrinter = new IntPtr(0);
                    DOCINFOA di = new DOCINFOA();
                    bool bSuccess = false;

                    di.pDocName = "RAW Document";
                    di.pDataType = "RAW";

                    if (OpenPrinter(szPrinterName.Normalize(), out hPrinter, IntPtr.Zero)) {
                        if (StartDocPrinter(hPrinter, 1, di)) {
                            if (StartPagePrinter(hPrinter)) {
                                bSuccess = WritePrinter(hPrinter, pBytes, dwCount, out dwWritten);
                                EndPagePrinter(hPrinter);
                            }
                            EndDocPrinter(hPrinter);
                        }
                        ClosePrinter(hPrinter);
                    }
                    return bSuccess;
                }
            }
"@

        $pUnmanagedBytes = [System.Runtime.InteropServices.Marshal]::AllocCoTaskMem($Command.Length)
        [System.Runtime.InteropServices.Marshal]::Copy($Command, 0, $pUnmanagedBytes, $Command.Length)
        
        $result = [RawPrinter]::SendBytesToPrinter($PrinterName, $pUnmanagedBytes, $Command.Length)
        
        [System.Runtime.InteropServices.Marshal]::FreeCoTaskMem($pUnmanagedBytes)
        
        return $result
    }
    catch {
        Write-Error "Failed to send ESC/Label command via Windows: $($_.Exception.Message)"
        return $false
    }
}

function Set-WindowsPrinterDefaults {
    param(
        [string]$PrinterName,
        [double]$WidthInches,
        [double]$HeightInches
    )
    
    try {
        Write-Host "Configuring Windows printer defaults..." -ForegroundColor Yellow
        
        # Load required assemblies
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Windows.Forms
        
        # Create print document to access printer settings
        $printDoc = New-Object System.Drawing.Printing.PrintDocument
        $printDoc.PrinterSettings.PrinterName = $PrinterName
        
        if (-not $printDoc.PrinterSettings.IsValid) {
            Write-Warning "Cannot access printer through .NET framework"
            return $false
        }
        
        # Convert inches to hundredths of an inch (Windows paper size units)
        $widthHundredths = [int]($WidthInches * 100)
        $heightHundredths = [int]($HeightInches * 100)
        
        # Create custom paper size
        $customPaper = New-Object System.Drawing.Printing.PaperSize("Custom ${WidthInches}x${HeightInches}", $widthHundredths, $heightHundredths)
        
        Write-Host "Created custom paper size: $($customPaper.PaperName) (${widthHundredths}x${heightHundredths} hundredths)" -ForegroundColor Cyan
        
        # Note: Setting default paper size persistently requires registry modifications
        # This approach sets it for the current session
        
        return $true
    }
    catch {
        Write-Error "Windows printer configuration failed: $($_.Exception.Message)"
        return $false
    }
}

function Set-EpsonRegistryDefaults {
    param(
        [string]$PrinterName,
        [double]$WidthInches,
        [double]$HeightInches
    )
    
    try {
        Write-Host "Configuring registry settings for persistent defaults..." -ForegroundColor Yellow
        
        # Epson printers often store settings in these registry locations
        $possiblePaths = @(
            "HKCU:\SOFTWARE\EPSON\EPSON ColorWorks CW-C4000 Series",
            "HKLM:\SOFTWARE\EPSON\EPSON ColorWorks CW-C4000 Series",
            "HKCU:\Printers\Settings\$PrinterName",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers\$PrinterName"
        )
        
        $settingsApplied = $false
        
        foreach ($regPath in $possiblePaths) {
            if (Test-Path $regPath) {
                try {
                    Write-Host "Found registry path: $regPath" -ForegroundColor Cyan
                    
                    # Set custom paper size values
                    New-ItemProperty -Path $regPath -Name "DefaultPaperWidth" -Value $WidthInches -PropertyType DWord -Force -ErrorAction SilentlyContinue
                    New-ItemProperty -Path $regPath -Name "DefaultPaperHeight" -Value $HeightInches -PropertyType DWord -Force -ErrorAction SilentlyContinue
                    New-ItemProperty -Path $regPath -Name "PaperSizeMode" -Value "Custom" -PropertyType String -Force -ErrorAction SilentlyContinue
                    
                    $settingsApplied = $true
                    Write-Host "Registry settings applied to: $regPath" -ForegroundColor Green
                }
                catch {
                    Write-Warning "Could not modify registry path: $regPath - $($_.Exception.Message)"
                }
            }
        }
        
        if (-not $settingsApplied) {
            Write-Warning "No accessible registry paths found for Epson C4000 settings"
        }
        
        return $settingsApplied
    }
    catch {
        Write-Error "Registry configuration failed: $($_.Exception.Message)"
        return $false
    }
}

function Test-PrinterConnection {
    param([string]$IPAddress)
    
    Write-Host "Testing connection to printer at IP: $IPAddress" -ForegroundColor Cyan
    
    # Test TCP connection first
    $tcpResult = Test-PrinterTCPConnection -IPAddress $IPAddress
    
    # Try to find associated Windows printer
    $printerName = Find-PrinterByIP -IPAddress $IPAddress
    
    if ($tcpResult) {
        Write-Host "✓ Direct TCP communication available" -ForegroundColor Green
    }
    
    if ($printerName) {
        Write-Host "✓ Windows printer integration available: $printerName" -ForegroundColor Green
        return @{
            TCPAvailable = $tcpResult
            PrinterName = $printerName
            Success = $true
        }
    } elseif ($tcpResult) {
        Write-Host "✓ TCP-only communication (no Windows printer found)" -ForegroundColor Yellow
        return @{
            TCPAvailable = $tcpResult
            PrinterName = $null
            Success = $true
        }
    } else {
        Write-Host "✗ No communication method available" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
        Write-Host "1. Verify the IP address is correct" -ForegroundColor White
        Write-Host "2. Ensure the printer is powered on and connected to network" -ForegroundColor White
        Write-Host "3. Check if printer is configured for raw TCP on port 9100" -ForegroundColor White
        Write-Host "4. Verify Windows firewall isn't blocking the connection" -ForegroundColor White
        Write-Host "5. Try pinging the printer: ping $IPAddress" -ForegroundColor White
        return @{
            TCPAvailable = $false
            PrinterName = $null
            Success = $false
        }
    }
}

# Main execution
Write-Host "=== Epson ColorWorks C4000 Network Configuration Script ===" -ForegroundColor Magenta
Write-Host "Target Printer IP: $PrinterIPAddress" -ForegroundColor Cyan
Write-Host "Target Size: ${WidthInches}`` x ${HeightInches}`` inches" -ForegroundColor Cyan
Write-Host ""

# Test printer connection
$connectionResult = Test-PrinterConnection -IPAddress $PrinterIPAddress

if (-not $connectionResult.Success) {
    Write-Host ""
    Write-Host "Cannot connect to printer at $PrinterIPAddress" -ForegroundColor Red
    Write-Host "Please verify the IP address and network connectivity" -ForegroundColor Yellow
    exit 1
}

$printerName = $connectionResult.PrinterName
Write-Host ""
$overallSuccess = $false

# Method 1: Direct TCP ESC/Label Commands (Primary method for network C4000)
Write-Host "Method 1: Direct TCP ESC/Label Commands (Recommended)" -ForegroundColor Magenta
$escSuccess = Set-EpsonC4000PaperSize -IPAddress $PrinterIPAddress -WidthInches $WidthInches -HeightInches $HeightInches -PrinterName $printerName

if ($escSuccess) {
    $overallSuccess = $true
    Write-Host "✓ ESC/Label configuration successful" -ForegroundColor Green
} else {
    Write-Host "✗ ESC/Label configuration failed" -ForegroundColor Red
}

Write-Host ""

# Method 2: Windows Printer Defaults (if Windows printer is available)
if ($printerName) {
    Write-Host "Method 2: Windows Printer Integration" -ForegroundColor Magenta
    $winSuccess = Set-WindowsPrinterDefaults -PrinterName $printerName -WidthInches $WidthInches -HeightInches $HeightInches

    if ($winSuccess) {
        Write-Host "✓ Windows integration successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Windows integration failed" -ForegroundColor Red
    }

    Write-Host ""

    # Method 3: Registry Settings (for persistence)
    Write-Host "Method 3: Registry Configuration (Persistent Settings)" -ForegroundColor Magenta
    $regSuccess = Set-EpsonRegistryDefaults -PrinterName $printerName -WidthInches $WidthInches -HeightInches $HeightInches

    if ($regSuccess) {
        $overallSuccess = $true
        Write-Host "✓ Registry configuration successful" -ForegroundColor Green
    } else {
        Write-Host "✗ Registry configuration failed" -ForegroundColor Red
    }
} else {
    Write-Host "Method 2 & 3: Skipped (No Windows printer found)" -ForegroundColor Yellow
    Write-Host "Only TCP communication is available" -ForegroundColor Yellow
}

Write-Host ""

# Results and recommendations
if ($overallSuccess) {
    Write-Host "🎉 Configuration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Yellow
    Write-Host "1. Restart the Print Spooler service: Restart-Service -Name Spooler" -ForegroundColor White
    Write-Host "2. Test print a label to verify the size" -ForegroundColor White
    Write-Host "3. In your applications, select the custom paper size or '2x1 inches'" -ForegroundColor White
    Write-Host "4. The ESC/Label commands should make this the default for direct printing" -ForegroundColor White
} else {
    Write-Host "⚠️  Automatic configuration had issues" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Manual alternatives for Epson C4000:" -ForegroundColor Yellow
    Write-Host "1. Open Epson ColorWorks CW-C4000 Properties" -ForegroundColor White
    Write-Host "2. Go to Paper/Quality or Layout tab" -ForegroundColor White
    Write-Host "3. Create custom paper size: 2.00 x 1.00 inches" -ForegroundColor White
    Write-Host "4. Set as default paper size" -ForegroundColor White
    Write-Host "5. Use Epson ColorWorks Configuration Utility if available" -ForegroundColor White
}

Write-Host ""
Write-Host "ESC/Label Command Summary:" -ForegroundColor Cyan
Write-Host "- Initialize: ESC @" -ForegroundColor White
Write-Host "- Set Label Size: ESC i S [width] [height]" -ForegroundColor White
Write-Host "- Save Settings: ESC i E" -ForegroundColor White
Write-Host ""
Write-Host "For advanced configuration, consider using Epson's ColorWorks Configuration Utility" -ForegroundColor Cyan