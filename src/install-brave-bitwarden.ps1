# Install Brave Browser with Bitwarden Extension - Simple & Reliable
param(
    [switch]$SkipBrowserInstall,
    [switch]$SkipAutoLaunch,
    [switch]$Quiet
)

function Write-StatusMessage {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Green
    }
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Install-BraveBrowser {
    Write-StatusMessage "Checking if Brave Browser is already installed..."
    
    # Check if Brave executable exists (more reliable than WMI)
    $braveExe = $null
    $possiblePaths = @(
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:PROGRAMFILES\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:PROGRAMFILES(X86)\BraveSoftware\Brave-Browser\Application\brave.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $braveExe = $path
            break
        }
    }
    
    if ($braveExe) {
        Write-StatusMessage "Brave Browser is already installed at: $braveExe"
        return $true
    }

    Write-StatusMessage "Installing Brave Browser using winget..."
    
    if (-not (Test-WingetAvailable)) {
        Write-ErrorMessage "winget is not available. Please install Windows Package Manager first."
        return $false
    }

    try {
        $process = Start-Process -FilePath "winget" -ArgumentList "install", "--id=Brave.Brave", "--silent", "--accept-package-agreements", "--accept-source-agreements" -Wait -PassThru -NoNewWindow
        
        # Handle different winget exit codes
        switch ($process.ExitCode) {
            0 {
                Write-StatusMessage "Brave Browser installed successfully."
                return $true
            }
            -1978335189 {
                # Package already installed and up-to-date
                Write-StatusMessage "Brave Browser is already installed and up-to-date."
                return $true
            }
            -1978335212 {
                # No newer package versions available
                Write-StatusMessage "Brave Browser is already at the latest version."
                return $true
            }
            default {
                Write-ErrorMessage "Failed to install Brave Browser. Exit code: $($process.ExitCode)"
                
                # Double-check if installation actually succeeded despite error code
                Start-Sleep -Seconds 2
                foreach ($path in $possiblePaths) {
                    if (Test-Path $path) {
                        Write-StatusMessage "Brave Browser appears to be installed successfully despite error code."
                        return $true
                    }
                }
                return $false
            }
        }
    } catch {
        Write-ErrorMessage "Error installing Brave Browser: $($_.Exception.Message)"
        return $false
    }
}

function Install-BitwardenExtension {
    Write-StatusMessage "Checking if Bitwarden extension is already installed..."
    
    # Check if Bitwarden extension is already installed
    $braveUserDataPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
    $extensionsPath = "$braveUserDataPath\Default\Extensions"
    $bitwardenExtensionId = "nngceckbapebfimnlniiiahkandclblb"
    $bitwardenPath = "$extensionsPath\$bitwardenExtensionId"
    
    if (Test-Path $bitwardenPath) {
        # Check if there are version directories (indicating extension is actually installed)
        $versionDirs = Get-ChildItem $bitwardenPath -Directory -ErrorAction SilentlyContinue
        if ($versionDirs.Count -gt 0) {
            Write-StatusMessage "Bitwarden extension is already installed in Brave."
            return "already_installed"
        }
    }
    
    Write-StatusMessage "Setting up Bitwarden extension installation..."
    
    # Skip registry approach - it's often blocked by group policies
    # Use direct browser approach instead
    Write-StatusMessage "Using direct browser method for maximum compatibility."
    
    # Find Brave executable
    $braveExe = $null
    $possiblePaths = @(
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:PROGRAMFILES\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:PROGRAMFILES(X86)\BraveSoftware\Brave-Browser\Application\brave.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $braveExe = $path
            break
        }
    }
    
    if (-not $braveExe) {
        Write-ErrorMessage "Could not find Brave Browser executable."
        return $false
    }
    
    try {
        # Open the Bitwarden extension page in the Chrome Web Store
        $bitwardenExtensionUrl = "https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb"
        
        Write-StatusMessage "Opening Bitwarden extension page in Brave..."
        Start-Process -FilePath $braveExe -ArgumentList $bitwardenExtensionUrl -NoNewWindow
        
        # Give the browser a moment to load
        Start-Sleep -Seconds 2
        
        Write-StatusMessage "Bitwarden extension page opened successfully."
        return "browser_opened"
        
    } catch {
        Write-ErrorMessage "Failed to open Brave with extension page: $($_.Exception.Message)"
        return $false
    }
}

function Show-PostInstallInstructions {
    param([bool]$ExtensionAlreadyInstalled = $false)
    
    Write-Host ""
    Write-Host "=== Installation Complete ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "✅ Brave Browser has been installed" -ForegroundColor Green
    
    if ($ExtensionAlreadyInstalled) {
        Write-Host "✅ Bitwarden extension is already installed" -ForegroundColor Green
        Write-Host ""
        Write-Host "You're all set! Both Brave Browser and Bitwarden extension are ready to use." -ForegroundColor Green
        Write-Host ""
    } else {
        Write-Host "✅ Bitwarden extension page opened in browser" -ForegroundColor Green
        Write-Host ""
        Write-Host "To complete the setup:" -ForegroundColor Cyan
        Write-Host "1. Look for the Bitwarden extension page in your Brave browser" -ForegroundColor White
        Write-Host "2. Click the 'Add to Brave' button" -ForegroundColor White
        Write-Host "3. Confirm by clicking 'Add extension' if prompted" -ForegroundColor White
        Write-Host "4. The Bitwarden icon will appear in your browser toolbar" -ForegroundColor White
        Write-Host ""
        Write-Host "If the page didn't open:" -ForegroundColor Yellow
        Write-Host "Visit: https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb" -ForegroundColor White
        Write-Host ""
        Write-Host "This approach works reliably across all Windows configurations!" -ForegroundColor Green
        Write-Host ""
    }
}

function Start-BraveToActivateExtension {
    Write-StatusMessage "Brave should now display the Bitwarden extension page."
    Write-StatusMessage "Simply click 'Add to Brave' to complete the installation!"
}

# Main execution
try {
    Write-StatusMessage "Starting Brave Browser and Bitwarden extension installation..."
    
    $success = $true
    
    if (-not $SkipBrowserInstall) {
        $success = Install-BraveBrowser
        if ($success) {
            # Give Brave installation a moment to complete
            Start-Sleep -Seconds 2
        }
    }
    
    if ($success) {
        $extensionResult = Install-BitwardenExtension
        $success = $extensionResult -ne $false
    }
    
    if ($success) {
        $extensionAlreadyInstalled = $extensionResult -eq "already_installed"
        $browserOpened = $extensionResult -eq "browser_opened"
        
        if ($browserOpened -and -not $SkipAutoLaunch) {
            Start-BraveToActivateExtension
        }
        
        Show-PostInstallInstructions -ExtensionAlreadyInstalled $extensionAlreadyInstalled
        Write-StatusMessage "Installation completed successfully!"
    } else {
        Write-ErrorMessage "Installation process completed with errors. Please check the output above."
        exit 1
    }
    
} catch {
    Write-ErrorMessage "Unexpected error occurred: $($_.Exception.Message)"
    exit 1
}