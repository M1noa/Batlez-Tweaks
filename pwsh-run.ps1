# Enhanced script with debugging and error handling
param(
    [switch]$Debug = $false
)

# Function to write timestamped logs
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    
    # Also write to a log file for persistence
    $logFile = Join-Path $env:TEMP "batlez-tweaks-debug.log"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
}

# Function to pause execution (useful for debugging)
function Pause-Execution {
    param([string]$Message = "Press any key to continue...")
    if ($Debug) {
        Write-Log $Message "DEBUG"
        Read-Host $Message
    }
}

try {
    Write-Log "Script started. Debug mode: $Debug"
    Write-Log "Current user: $($env:USERNAME)"
    Write-Log "Current directory: $(Get-Location)"
    
    # Ensure running as admin
    $windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($windowsIdentity)
    $isAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    Write-Log "Admin check result: $isAdmin"
    
    if (-not $isAdmin) {
        Write-Log "Not running as admin. Relaunching as administrator..." "WARN"
        
        # Get the current script path
        if ($PSCommandPath) {
            $scriptPath = $PSCommandPath
            Write-Log "Using PSCommandPath: $scriptPath"
        } else {
            # Fallback for when running via iex
            Write-Log "PSCommandPath not available (likely running via iex). Creating temp script..."
            $scriptContent = Get-Content $MyInvocation.MyCommand.Path -Raw -ErrorAction SilentlyContinue
            if (-not $scriptContent) {
                # If we can't get the script content, re-download it
                $tempScript = Join-Path $env:TEMP "batlez-tweaks-temp.ps1"
                $scriptUrl = "https://raw.githubusercontent.com/M1noa/Batlez-Tweaks/main/pwsh-run.ps1"
                Write-Log "Re-downloading script to: $tempScript"
                Invoke-WebRequest -Uri $scriptUrl -OutFile $tempScript -ErrorAction Stop
                $scriptPath = $tempScript
            }
        }
        
        $debugParam = if ($Debug) { "-Debug" } else { "" }
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $debugParam"
        Write-Log "Launching with arguments: $arguments"
        
        Start-Process powershell $arguments -Verb RunAs
        Write-Log "Admin process launched, exiting current process"
        exit
    }
    
    Write-Log "Running as administrator - proceeding with main logic"
    Pause-Execution "About to start downloading and executing the batch file..."
    
    # Set repo and .bat filename
    $repoOwner = "M1noa"  # Fixed: was "Batlez" but you're using M1noa fork
    $repoName = "Batlez-Tweaks"
    $batFileName = "Batlez Tweaks.bat"
    $branch = "main"
    
    Write-Log "Repository: $repoOwner/$repoName"
    Write-Log "Branch: $branch"
    Write-Log "Batch file: $batFileName"
    
    # Download the .bat file to temp
    $tempBat = Join-Path $env:TEMP $batFileName
    $rawUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/$([uri]::EscapeDataString($batFileName))"
    
    Write-Log "Download URL: $rawUrl"
    Write-Log "Temp file location: $tempBat"
    
    Write-Log "Downloading batch file..." "INFO"
    try {
        Invoke-WebRequest -Uri $rawUrl -OutFile $tempBat -ErrorAction Stop
        Write-Log "Download completed successfully"
        
        # Verify file was downloaded
        if (Test-Path $tempBat) {
            $fileSize = (Get-Item $tempBat).Length
            Write-Log "File downloaded successfully. Size: $fileSize bytes"
        } else {
            throw "Downloaded file not found at expected location"
        }
    }
    catch {
        Write-Log "Download failed: $($_.Exception.Message)" "ERROR"
        throw
    }
    
    Pause-Execution "About to execute the batch file..."
    
    # Execute the .bat file
    Write-Log "Running $batFileName as administrator..."
    try {
        $process = Start-Process -FilePath $tempBat -Verb RunAs -Wait -PassThru -ErrorAction Stop
        Write-Log "Batch file execution completed with exit code: $($process.ExitCode)"
    }
    catch {
        Write-Log "Failed to execute batch file: $($_.Exception.Message)" "ERROR"
        throw
    }
    
    # Cleanup
    Write-Log "Cleaning up temporary files..."
    try {
        if (Test-Path $tempBat) {
            Remove-Item $tempBat -Force -ErrorAction Stop
            Write-Log "Temporary batch file deleted"
        }
        
        # Clean up temp script if it was created
        $tempScript = Join-Path $env:TEMP "batlez-tweaks-temp.ps1"
        if (Test-Path $tempScript) {
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
            Write-Log "Temporary PowerShell script deleted"
        }
    }
    catch {
        Write-Log "Cleanup warning: $($_.Exception.Message)" "WARN"
    }
    
    Write-Log "Script completed successfully!" "SUCCESS"
}
catch {
    Write-Log "FATAL ERROR: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    
    if ($Debug) {
        Write-Log "Error details:" "ERROR"
        Write-Log "Exception Type: $($_.Exception.GetType().FullName)" "ERROR"
        Write-Log "Inner Exception: $($_.Exception.InnerException)" "ERROR"
    }
}
finally {
    if ($Debug -or $isAdmin) {
        Write-Log "Press any key to close this window..."
        Read-Host "Press Enter to exit"
    }
    
    # Show log file location
    $logFile = Join-Path $env:TEMP "batlez-tweaks-debug.log"
    if (Test-Path $logFile) {
        Write-Log "Debug log saved to: $logFile"
    }
}
