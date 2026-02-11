# Windows PC Setup Script - Automated Configuration
# Runs all setup scripts to configure a new Windows PC

param(
    [switch]$Quiet
)

function Write-SetupMessage {
    param(
        [string]$Message,
        [string]$Color = "Cyan"
    )
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-SetupError {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-SetupSuccess {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Run-SetupScript {
    param(
        [string]$ScriptPath,
        [string]$Description,
        [string[]]$Arguments = @()
    )
    
    Write-SetupMessage "⚡ $Description..." "Yellow"
    
    if (-not (Test-Path $ScriptPath)) {
        Write-SetupError "❌ Script not found: $ScriptPath"
        return $false
    }
    
    try {
        $argumentList = @($ScriptPath) + $Arguments
        if ($Quiet) {
            $argumentList += "-Quiet"
        }
        
        $result = & powershell.exe -ExecutionPolicy Bypass -File @argumentList -ErrorAction Stop
        
        Write-SetupSuccess "✅ $Description completed successfully"
        return $true
        
    } catch {
        Write-SetupError "❌ $Description failed: $($_.Exception.Message)"
        return $false
    }
}

function Show-SetupSummary {
    param(
        [hashtable]$Results
    )
    
    Write-Host ""
    Write-Host "===============================================" -ForegroundColor Yellow
    Write-Host "       WINDOWS PC SETUP COMPLETE" -ForegroundColor Yellow
    Write-Host "===============================================" -ForegroundColor Yellow
    Write-Host ""
    
    $allSuccess = $true
    foreach ($task in $Results.Keys) {
        $status = if ($Results[$task]) { "✅ Success" } else { "❌ Failed" }
        $color = if ($Results[$task]) { "Green" } else { "Red" }
        
        Write-Host "$task`: $status" -ForegroundColor $color
        
        if (-not $Results[$task]) {
            $allSuccess = $false
        }
    }
    
    Write-Host ""
    if ($allSuccess) {
        Write-Host "🎉 All setup tasks completed successfully!" -ForegroundColor Green
        Write-Host "Your Windows PC is now configured and ready to use." -ForegroundColor Green
    } else {
        Write-Host "⚠️  Some setup tasks failed. Please review the output above." -ForegroundColor Yellow
        Write-Host "You may need to run failed scripts manually." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Setup scripts location: .\src\" -ForegroundColor Cyan
    Write-Host "Test scripts location: .\tests\" -ForegroundColor Cyan
    Write-Host ""
}

# Main execution
Write-SetupMessage "🚀 Starting Windows PC Setup..." "Magenta"
Write-SetupMessage "This will configure your new Windows PC with essential software and settings." "White"
Write-Host ""

$setupResults = @{}

# Define setup tasks
$setupTasks = @(
    @{
        Script = ".\src\create-directories.ps1"
        Description = "Creating essential directories"
    },
    @{
        Script = ".\src\install-brave-bitwarden.ps1"
        Description = "Installing Brave Browser and Bitwarden extension"
    }
)

# Execute each setup task
foreach ($task in $setupTasks) {
    $success = Run-SetupScript -ScriptPath $task.Script -Description $task.Description
    $setupResults[$task.Description] = $success
    
    if ($success) {
        Write-Host ""
    } else {
        Write-SetupMessage "Continuing with next setup task..." "Yellow"
        Write-Host ""
    }
}

# Show final summary
Show-SetupSummary -Results $setupResults

# Exit with appropriate code
$failedTasks = $setupResults.Values | Where-Object { $_ -eq $false }
if ($failedTasks.Count -gt 0) {
    exit 1
} else {
    exit 0
}