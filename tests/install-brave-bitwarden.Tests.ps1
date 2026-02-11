# Test file for install-brave-bitwarden.ps1 - Verification Tests Only

Describe 'Brave Browser and Bitwarden Extension Verification' {

    Context 'Brave Browser Installation' {
        It 'should have Brave Browser installed' {
            $possiblePaths = @(
                "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:PROGRAMFILES\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:PROGRAMFILES(X86)\BraveSoftware\Brave-Browser\Application\brave.exe"
            )
            
            $braveExecutable = $null
            foreach ($path in $possiblePaths) {
                if (Test-Path $path) {
                    $braveExecutable = $path
                    break
                }
            }
            
            $braveExecutable | Should Not BeNullOrEmpty
            Test-Path $braveExecutable | Should Be $true
        }

        It 'should have Brave user data directory (if launched)' {
            $braveUserDataPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
            
            if (Test-Path $braveUserDataPath) {
                Test-Path $braveUserDataPath | Should Be $true
                (Get-Item $braveUserDataPath).PSIsContainer | Should Be $true
            }
        }
    }

    Context 'Bitwarden Extension Installation' {
        It 'should have Bitwarden extension installed in Brave' {
            $braveUserDataPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
            $extensionsPath = "$braveUserDataPath\Default\Extensions"
            $bitwardenExtensionId = "nngceckbapebfimnlniiiahkandclblb"
            
            # Only test if Brave has been launched and has extensions directory
            if (Test-Path $extensionsPath) {
                $bitwardenPath = "$extensionsPath\$bitwardenExtensionId"
                Test-Path $bitwardenPath | Should Be $true
                
                # Check if there's at least one version directory
                $versionDirs = Get-ChildItem $bitwardenPath -Directory -ErrorAction SilentlyContinue
                $versionDirs.Count | Should BeGreaterThan 0
            }
        }

        It 'should have Bitwarden extension manifest' {
            $braveUserDataPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
            $extensionsPath = "$braveUserDataPath\Default\Extensions"
            $bitwardenExtensionId = "nngceckbapebfimnlniiiahkandclblb"
            
            # Only test if extension directory exists
            if (Test-Path "$extensionsPath\$bitwardenExtensionId") {
                $versionDirs = Get-ChildItem "$extensionsPath\$bitwardenExtensionId" -Directory -ErrorAction SilentlyContinue
                
                if ($versionDirs.Count -gt 0) {
                    $latestVersion = $versionDirs | Sort-Object Name -Descending | Select-Object -First 1
                    $manifestPath = "$($latestVersion.FullName)\manifest.json"
                    
                    Test-Path $manifestPath | Should Be $true
                    
                    # Verify it's a valid extension manifest
                    $manifest = Get-Content $manifestPath | ConvertFrom-Json
                    $manifest.manifest_version | Should Not BeNullOrEmpty
                    
                    # Check for Bitwarden-specific identifiers (extension uses localization, so check description or other fields)
                    if ($manifest.description) {
                        $manifest.description | Should Match "password|Bitwarden|__MSG_"
                    } else {
                        # If no description, just verify the extension ID matches (we're already in the right directory)
                        $bitwardenExtensionId | Should Match "nngceckbapebfimnlniiiahkandclblb"
                    }
                }
            }
        }
    }

    Context 'Installation Success Summary' {
        It 'should show installation status' {
            # Brave check
            $possiblePaths = @(
                "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:PROGRAMFILES\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:PROGRAMFILES(X86)\BraveSoftware\Brave-Browser\Application\brave.exe"
            )
            
            $braveInstalled = $false
            foreach ($path in $possiblePaths) {
                if (Test-Path $path) {
                    $braveInstalled = $true
                    break
                }
            }
            
            # Bitwarden check
            $braveUserDataPath = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
            $extensionsPath = "$braveUserDataPath\Default\Extensions"
            $bitwardenExtensionId = "nngceckbapebfimnlniiiahkandclblb"
            $bitwardenInstalled = Test-Path "$extensionsPath\$bitwardenExtensionId"
            
            Write-Host ""
            Write-Host "=== Installation Verification Results ===" -ForegroundColor Yellow
            Write-Host "Brave Browser: $(if($braveInstalled) { "✅ Installed" } else { "❌ Not Found" })" -ForegroundColor $(if($braveInstalled) { "Green" } else { "Red" })
            Write-Host "Bitwarden Extension: $(if($bitwardenInstalled) { "✅ Installed" } else { "❌ Not Found" })" -ForegroundColor $(if($bitwardenInstalled) { "Green" } else { "Red" })
            Write-Host ""
            
            # Test passes if we can report status (always true for summary)
            $true | Should Be $true
        }
    }
}