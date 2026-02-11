# Define the expected directories that should be created
$script:expectedDirectories = @(
    'C:\temp',
    'C:\git\gh', 
    'C:\obsidian'
)

Describe 'create-directories filesystem verification' {

    It 'should create C:\temp directory' {
        Test-Path 'C:\temp' | Should Be $true
        (Get-Item 'C:\temp').PSIsContainer | Should Be $true
    }

    It 'should create C:\git\gh directory' {
        Test-Path 'C:\git\gh' | Should Be $true
        (Get-Item 'C:\git\gh').PSIsContainer | Should Be $true
    }

    It 'should create C:\obsidian directory' {
        Test-Path 'C:\obsidian' | Should Be $true
        (Get-Item 'C:\obsidian').PSIsContainer | Should Be $true
    }

    It 'should create all expected directories' {
        foreach ($dir in $script:expectedDirectories) {
            Test-Path $dir | Should Be $true
        }
    }

    It 'should create directories with proper attributes' {
        foreach ($dir in $script:expectedDirectories) {
            $item = Get-Item $dir -ErrorAction SilentlyContinue
            $item | Should Not BeNullOrEmpty
            $item.PSIsContainer | Should Be $true
        }
    }
}
