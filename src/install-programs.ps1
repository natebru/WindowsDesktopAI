# Install Essential Programs using WinGet
param(
    [switch]$SkipConfirmation,
    [switch]$Quiet,
    [string[]]$ExcludePrograms = @(),
    [string]$ProgramsFile = (Join-Path $PSScriptRoot "programs.yaml")
)

function Import-ProgramsFromYaml {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-ErrorMessage "Programs file not found: $FilePath"
        return @()
    }
    
    try {
        # Check if powershell-yaml module is available
        if (Get-Module -ListAvailable -Name powershell-yaml) {
            Import-Module powershell-yaml -ErrorAction Stop
            $yamlContent = Get-Content $FilePath -Raw
            $data = ConvertFrom-Yaml $yamlContent
            
            return $data.programs | ForEach-Object {
                $program = @{
                    Name = $_.name
                    Id = $_.id  
                    Description = $_.description
                }
                if ($_.source) {
                    $program.Source = $_.source
                }
                $program
            }
        } else {
            Write-WarningMessage "powershell-yaml module not found. Install it with: Install-Module powershell-yaml"
            Write-StatusMessage "Falling back to simple YAML parsing..."
            
            # Simple YAML parsing for our specific structure
            $content = Get-Content $FilePath
            $programs = @()
            $currentProgram = @{}
            
            foreach ($line in $content) {
                $line = $line.Trim()
                if ($line -match "^\s*-\s*name:\s*[\"'](.+)[\"']") {
                    if ($currentProgram.Count -gt 0) {
                        $programs += $currentProgram
                    }
                    $currentProgram = @{Name = $matches[1]}
                } elseif ($line -match "^\s*id:\s*[\"'](.+)[\"']") {
                    $currentProgram.Id = $matches[1]
                } elseif ($line -match "^\s*description:\s*[\"'](.+)[\"']") {  
                    $currentProgram.Description = $matches[1]
                } elseif ($line -match "^\s*source:\s*[\"'](.+)[\"']") {
                    $currentProgram.Source = $matches[1]
                }
            }
            
            if ($currentProgram.Count -gt 0) {
                $programs += $currentProgram
            }
            
            return $programs
        }
    } catch {
        Write-ErrorMessage "Error parsing programs file: $($_.Exception.Message)"
        return @()
    }
}

# Load programs from YAML file
$programs = Import-ProgramsFromYaml -FilePath $ProgramsFile

if ($programs.Count -eq 0) {
    Write-ErrorMessage "No programs loaded. Exiting."
    exit 1
}

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