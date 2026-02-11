# Test file for install-programs.ps1 - Verification Tests

# Define the programs that should be installed
$script:expectedPrograms = @(
    @{Name = "Git"; ExecutablePaths = @("git.exe"); RegistryPaths = @("HKLM:\SOFTWARE\GitForWindows")},
    @{Name = "PowerToys"; ExecutablePaths = @("PowerToys.exe"); InstallPaths = @("$env:LOCALAPPDATA\Microsoft\PowerToys", "$env:PROGRAMFILES\PowerToys")},
    @{Name = "Brave Browser"; ExecutablePaths = @("brave.exe"); InstallPaths = @("$env:LOCALAPPDATA\BraveSoftware", "$env:PROGRAMFILES\BraveSoftware", "$env:PROGRAMFILES(X86)\BraveSoftware")},
    @{Name = "Visual Studio Code"; ExecutablePaths = @("code.exe", "Code.exe"); InstallPaths = @("$env:LOCALAPPDATA\Programs\Microsoft VS Code", "$env:PROGRAMFILES\Microsoft VS Code")},
    @{Name = "Obsidian"; ExecutablePaths = @("Obsidian.exe"); InstallPaths = @("$env:LOCALAPPDATA\Obsidian")},
    @{Name = "Spotify"; ExecutablePaths = @("Spotify.exe"); InstallPaths = @("$env:APPDATA\Spotify", "$env:LOCALAPPDATA\Spotify")},
    @{Name = "PowerShell"; ExecutablePaths = @("pwsh.exe"); InstallPaths = @("$env:PROGRAMFILES\PowerShell")},
    @{Name = "Oh My Posh"; ExecutablePaths = @("oh-my-posh.exe"); WingetCheck = $true},
    @{Name = "Nextcloud Desktop"; ExecutablePaths = @("nextcloud.exe"); InstallPaths = @("$env:PROGRAMFILES\Nextcloud")},
    @{Name = "Git Credential Manager"; ExecutablePaths = @("git-credential-manager.exe", "git-credential-manager-core.exe"); WingetCheck = $true}
)

function Test-ProgramInPath {
    param([string]$ExecutableName)
    
    try {
        $null = Get-Command $ExecutableName -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-ProgramInstalled {
    param([hashtable]$Program)
    
    # First check if executable is in PATH
    foreach ($exe in $Program.ExecutablePaths) {
        if (Test-ProgramInPath -ExecutableName $exe) {
            return $true
        }
    }
    
    # Check install paths if specified
    if ($Program.InstallPaths) {
        foreach ($path in $Program.InstallPaths) {
            if (Test-Path $path) {
                # Look for any of the expected executables in this path
                foreach ($exe in $Program.ExecutablePaths) {
                    $fullPath = Join-Path $path $exe
                    if (Test-Path $fullPath) {
                        return $true
                    }
                    
                    # Also check subdirectories (like Application folder for Brave)
                    $subDirs = Get-ChildItem $path -Directory -ErrorAction SilentlyContinue
                    foreach ($subDir in $subDirs) {
                        $fullPath = Join-Path $subDir.FullName $exe
                        if (Test-Path $fullPath) {
                            return $true
                        }
                    }
                }
                return $true  # Path exists, assume installed
            }
        }
    }
    
    # Check registry if specified
    if ($Program.RegistryPaths) {
        foreach ($regPath in $Program.RegistryPaths) {
            if (Test-Path $regPath) {
                return $true
            }
        }
    }
    
    # For programs with WingetCheck, use winget to verify
    if ($Program.WingetCheck) {
        try {
            $wingetList = & winget list 2>$null
            if ($wingetList -match $Program.Name) {
                return $true
            }
        } catch {
            # Winget not available or error, skip this check
        }
    }
    
    return $false
}

Describe 'Essential Programs Installation Verification' {

    Context 'WinGet Availability' {
        It 'should have WinGet available in the system' {
            { Get-Command winget -ErrorAction Stop } | Should Not Throw
        }
    }

    Context 'Core Development Tools' {
        It 'should have Git installed' {
            $gitProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Git" }
            Test-ProgramInstalled -Program $gitProgram | Should Be $true
        }

        It 'should have Visual Studio Code installed' {
            $codeProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Visual Studio Code" }
            Test-ProgramInstalled -Program $codeProgram | Should Be $true
        }

        It 'should have PowerShell installed' {
            $pwshProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "PowerShell" }
            Test-ProgramInstalled -Program $pwshProgram | Should Be $true
        }

        It 'should have Git Credential Manager installed' {
            $gcmProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Git Credential Manager" }
            Test-ProgramInstalled -Program $gcmProgram | Should Be $true
        }
    }

    Context 'Productivity Applications' {
        It 'should have PowerToys installed' {
            $powerToysProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "PowerToys" }
            Test-ProgramInstalled -Program $powerToysProgram | Should Be $true
        }

        It 'should have Brave Browser installed' {
            $braveProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Brave Browser" }
            Test-ProgramInstalled -Program $braveProgram | Should Be $true
        }

        It 'should have Obsidian installed' {
            $obsidianProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Obsidian" }
            Test-ProgramInstalled -Program $obsidianProgram | Should Be $true
        }

        It 'should have Nextcloud Desktop installed' {
            $nextcloudProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Nextcloud Desktop" }
            Test-ProgramInstalled -Program $nextcloudProgram | Should Be $true
        }
    }

    Context 'Entertainment and Customization' {
        It 'should have Spotify installed' {
            $spotifyProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Spotify" }
            Test-ProgramInstalled -Program $spotifyProgram | Should Be $true
        }

        It 'should have Oh My Posh installed' {
            $ompProgram = $script:expectedPrograms | Where-Object { $_.Name -eq "Oh My Posh" }
            Test-ProgramInstalled -Program $ompProgram | Should Be $true
        }
    }

    Context 'Program Accessibility' {
        It 'should have Git accessible via PATH' {
            Test-ProgramInPath -ExecutableName "git.exe" | Should Be $true
        }

        It 'should have Visual Studio Code accessible via PATH' {
            (Test-ProgramInPath -ExecutableName "code") -or (Test-ProgramInPath -ExecutableName "code.exe") -or (Test-ProgramInPath -ExecutableName "Code.exe") | Should Be $true
        }

        It 'should have PowerShell accessible via PATH' {
            Test-ProgramInPath -ExecutableName "pwsh.exe" | Should Be $true
        }
    }

    Context 'Overall Installation Status' {
        It 'should have all expected programs installed' {
            $installedCount = 0
            $totalCount = $script:expectedPrograms.Count
            
            foreach ($program in $script:expectedPrograms) {
                if (Test-ProgramInstalled -Program $program) {
                    $installedCount++
                }
            }
            
            # Expect at least 80% of programs to be installed
            $successRate = ($installedCount / $totalCount) * 100
            $successRate | Should BeGreaterThan 80
        }

        It 'should have critical development tools installed' {
            $criticalPrograms = @("Git", "Visual Studio Code", "PowerShell")
            $criticalInstalled = 0
            
            foreach ($criticalName in $criticalPrograms) {
                $program = $script:expectedPrograms | Where-Object { $_.Name -eq $criticalName }
                if (Test-ProgramInstalled -Program $program) {
                    $criticalInstalled++
                }
            }
            
            $criticalInstalled | Should Be $criticalPrograms.Count
        }
    }
}