# Install Essential Programs using WinGet
param(
    [switch]$SkipConfirmation,
    [switch]$Quiet,
    [string[]]$ExcludePrograms = @()
)

$programs = @(
    @{Name = "Git"; Id = "Git.Git"; Description = "Version control system"},
    @{Name = "PowerToys"; Id = "Microsoft.PowerToys"; Description = "Microsoft PowerToys utilities"},
    @{Name = "Brave Browser"; Id = "Brave.Brave"; Description = "Privacy-focused web browser"},
    @{Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode"; Description = "Code editor"},
    @{Name = "Obsidian"; Id = "Obsidian.Obsidian"; Description = "Note-taking application"},
    @{Name = "Spotify"; Id = "Spotify.Spotify"; Description = "Music streaming service"},
    @{Name = "PowerShell"; Id = "Microsoft.PowerShell"; Description = "Modern PowerShell"},
    @{Name = "Oh My Posh"; Id = "JanDeDobbeleer.OhMyPosh"; Source = "winget"; Description = "Prompt theme engine"},
    @{Name = "Nextcloud Desktop"; Id = "Nextcloud.NextcloudDesktop"; Description = "Cloud sync client"},
    @{Name = "Git Credential Manager"; Id = "Git.GCM"; Description = "Git credential helper"}
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

function Write-WarningMessage {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Yellow
    }
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Install-Program {
    param(
        [hashtable]$Program
    )
    
    Write-StatusMessage "Installing $($Program.Name)..."
    
    try {
        $installArgs = @('install', $Program.Id, '--accept-source-agreements', '--accept-package-agreements')
        
        if ($Program.Source) {
            $installArgs += '--source'
            $installArgs += $Program.Source
        }
        
        if ($SkipConfirmation) {
            $installArgs += '--silent'
        }
        
        $result = & winget @installArgs
        
        # WinGet exit codes:
        # 0 = Success
        # -1978335189 = Already installed (0x8A15002B)
        # -1978335153 = No newer version available
        if ($LASTEXITCODE -eq 0) {
            Write-StatusMessage "Successfully installed $($Program.Name)"
            return $true
        } elseif ($LASTEXITCODE -eq -1978335189 -or $LASTEXITCODE -eq -1978335153) {
            Write-StatusMessage "$($Program.Name) is already installed or up to date"
            return $true
        } else {
            Write-ErrorMessage "Failed to install $($Program.Name). Exit code: $LASTEXITCODE"
            return $false
        }
    } catch {
        Write-ErrorMessage "Error installing $($Program.Name): $($_.Exception.Message)"
        return $false
    }
}

function Show-ProgramList {
    Write-Host "Programs to be installed:" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    
    $filteredPrograms = $programs | Where-Object { $_.Name -notin $ExcludePrograms }
    
    foreach ($program in $filteredPrograms) {
        Write-Host "  • $($program.Name) - $($program.Description)" -ForegroundColor White
    }
    
    if ($ExcludePrograms.Count -gt 0) {
        Write-Host ""
        Write-Host "Excluded programs:" -ForegroundColor Yellow
        Write-Host "==================" -ForegroundColor Yellow
        foreach ($excluded in $ExcludePrograms) {
            Write-Host "  • $excluded" -ForegroundColor Yellow
        }
    }
}

# Main execution
Write-StatusMessage "Starting program installation..."

if (-not (Test-WingetAvailable)) {
    Write-ErrorMessage "WinGet is not available. Please install it from the Microsoft Store or GitHub."
    exit 1
}

# Filter out excluded programs
$programsToInstall = $programs | Where-Object { $_.Name -notin $ExcludePrograms }

if (-not $Quiet) {
    Show-ProgramList
    Write-Host ""
}

if (-not $SkipConfirmation -and -not $Quiet) {
    $response = Read-Host "Do you want to continue with the installation? (Y/n)"
    if ($response -eq 'n' -or $response -eq 'N') {
        Write-StatusMessage "Installation cancelled by user."
        exit 0
    }
}

$successCount = 0
$failCount = 0

foreach ($program in $programsToInstall) {
    if (Install-Program -Program $program) {
        $successCount++
    } else {
        $failCount++
    }
    
    # Small delay to avoid overwhelming WinGet
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-StatusMessage "Installation Summary:"
Write-StatusMessage "====================="
Write-StatusMessage "Successfully installed: $successCount programs"

if ($failCount -gt 0) {
    Write-ErrorMessage "Failed to install: $failCount programs"
} else {
    Write-StatusMessage "All programs installed successfully!"
} 