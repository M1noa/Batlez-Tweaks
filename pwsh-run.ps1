# Enhanced script with improved elevation system
param(
    [switch]$Debug = $false,
    [switch]$ElevatedRun = $false
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

# Function to create and run elevated script
function Start-ElevatedScript {
    param([bool]$DebugMode = $false)
    
    Write-Log "Creating elevated script for admin execution..."
    
    # Create the full script content as a string
    $elevatedScriptContent = @"
# This is the elevated version of the script
`$Debug = `$$DebugMode

# Function to write timestamped logs
function Write-Log {
    param([string]`$Message, [string]`$Level = "INFO")
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logMessage = "[`$timestamp] [`$Level] `$Message"
    Write-Host `$logMessage
    
    # Also write to a log file for persistence
    `$logFile = Join-Path `$env:TEMP "batlez-tweaks-debug.log"
    Add-Content -Path `$logFile -Value `$logMessage -ErrorAction SilentlyContinue
}

# Function to pause execution (useful for debugging)
function Pause-Execution {
    param([string]`$Message = "Press any key to continue...")
    if (`$Debug) {
        Write-Log `$Message "DEBUG"
        Read-Host `$Message
    }
}

try {
    Write-Log "Elevated script started. Debug mode: `$Debug"
    Write-Log "Current user: `$(`$env:USERNAME)"
    Write-Log "Running as administrator: `$([Security.Principal.WindowsPrincipal]([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
    
    # Set repo and .bat filename
    `$repoOwner = "Batlez"
    `$repoName = "Batlez-Tweaks"
    `$batFileName = "Batlez Tweaks.bat"
    `$branch = "main"
    
    Write-Log "Repository: `$repoOwner/`$repoName"
    Write-Log "Branch: `$branch"
    Write-Log "Batch file: `$batFileName"
    
    # Download the .bat file to temp
    `$tempBat = Join-Path `$env:TEMP `$batFileName
    `$rawUrl = "https://raw.githubusercontent.com/`$repoOwner/`$repoName/`$branch/`$([uri]::EscapeDataString(`$batFileName))"
    
    Write-Log "Download URL: `$rawUrl"
    Write-Log "Temp file location: `$tempBat"
    
    Pause-Execution "About to start downloading the batch file..."
    
    Write-Log "Downloading batch file..." "INFO"
    try {
        Invoke-WebRequest -Uri `$rawUrl -OutFile `$tempBat -ErrorAction Stop
        Write-Log "Download completed successfully"
        
        # Verify file was downloaded
        if (Test-Path `$tempBat) {
            `$fileSize = (Get-Item `$tempBat).Length
            Write-Log "File downloaded successfully. Size: `$fileSize bytes"
            
            if (`$fileSize -eq 0) {
                throw "Downloaded file is empty (0 bytes)"
            }
        } else {
            throw "Downloaded file not found at expected location"
        }
    }
    catch {
        Write-Log "Download failed: `$(`$_.Exception.Message)" "ERROR"
        throw
    }
    
    Pause-Execution "About to execute the batch file..."
    
    # Execute the .bat file
    Write-Log "Running `$batFileName as administrator..."
    try {
        `$process = Start-Process -FilePath `$tempBat -Verb RunAs -Wait -PassThru -ErrorAction Stop
        Write-Log "Batch file execution completed with exit code: `$(`$process.ExitCode)"
    }
    catch {
        Write-Log "Failed to execute batch file: `$(`$_.Exception.Message)" "ERROR"
        throw
    }
    
    # Cleanup
    Write-Log "Cleaning up temporary files..."
    try {
        if (Test-Path `$tempBat) {
            Remove-Item `$tempBat -Force -ErrorAction Stop
            Write-Log "Temporary batch file deleted"
        }
    }
    catch {
        Write-Log "Cleanup warning: `$(`$_.Exception.Message)" "WARN"
    }
    
    Write-Log "Script completed successfully!" "SUCCESS"
}
catch {
    Write-Log "FATAL ERROR: `$(`$_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: `$(`$_.ScriptStackTrace)" "ERROR"
    
    if (`$Debug) {
        Write-Log "Error details:" "ERROR"
        Write-Log "Exception Type: `$(`$_.Exception.GetType().FullName)" "ERROR"
        Write-Log "Inner Exception: `$(`$_.Exception.InnerException)" "ERROR"
    }
}
finally {
    if (`$Debug) {
        Write-Log "Press any key to close this window..."
        Read-Host "Press Enter to exit"
    } else {
        # Give user a moment to see the results
        Start-Sleep -Seconds 3
    }
    
    # Show log file location
    `$logFile = Join-Path `$env:TEMP "batlez-tweaks-debug.log"
    if (Test-Path `$logFile) {
        Write-Log "Debug log saved to: `$logFile"
    }
}
"@

    # Write the script to a temporary file
    $elevatedScriptPath = Join-Path $env:TEMP "batlez-tweaks-elevated.ps1"
    try {
        $elevatedScriptContent | Out-File -FilePath $elevatedScriptPath -Encoding UTF8 -Force
        Write-Log "Elevated script written to: $elevatedScriptPath"
        
        # Launch the elevated script
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$elevatedScriptPath`""
        Write-Log "Launching elevated PowerShell with arguments: $arguments"
        
        Start-Process powershell $arguments -Verb RunAs -Wait
        Write-Log "Elevated process completed"
        
        # Cleanup the temporary elevated script
        if (Test-Path $elevatedScriptPath) {
            Remove-Item $elevatedScriptPath -Force -ErrorAction SilentlyContinue
            Write-Log "Temporary elevated script cleaned up"
        }
    }
    catch {
        Write-Log "Failed to create or run elevated script: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Main script execution
try {
    Write-Log "Script started. Debug mode: $Debug, ElevatedRun: $ElevatedRun"
    Write-Log "Current user: $($env:USERNAME)"
    Write-Log "Current directory: $(Get-Location)"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)"
    
    # Check if we're already running as admin
    $windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($windowsIdentity)
    $isAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    Write-Log "Admin check result: $isAdmin"
    
    if (-not $isAdmin) {
        Write-Log "Not running as admin. Starting elevation process..." "WARN"
        Pause-Execution "About to request administrator privileges..."
        
        # Use the new elevation system
        Start-ElevatedScript -DebugMode $Debug
        
        Write-Log "Elevation process completed, exiting current process"
        exit
    }
    
    Write-Log "Already running as administrator - this shouldn't happen with the new system" "WARN"
    Write-Log "Proceeding with main logic anyway..."
    
    # If we somehow get here (running as admin), execute the main logic
    # Set repo and .bat filename
    $repoOwner = "Batlez"
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
    Invoke-WebRequest -Uri $rawUrl -OutFile $tempBat -ErrorAction Stop
    Write-Log "Download completed successfully"
    
    # Execute the .bat file
    Write-Log "Running $batFileName as administrator..."
    $process = Start-Process -FilePath $tempBat -Verb RunAs -Wait -PassThru
    Write-Log "Batch file execution completed with exit code: $($process.ExitCode)"
    
    # Cleanup
    Remove-Item $tempBat -Force -ErrorAction SilentlyContinue
    Write-Log "Cleanup completed"
    
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
    if ($Debug) {
        Write-Log "Press any key to close this window..."
        Read-Host "Press Enter to exit"
    }
    
    # Show log file location
    $logFile = Join-Path $env:TEMP "batlez-tweaks-debug.log"
    if (Test-Path $logFile) {
        Write-Log "Debug log saved to: $logFile"
        if ($Debug) {
            Write-Log "You can view the full log with: notepad `"$logFile`""
        }
    }
}
