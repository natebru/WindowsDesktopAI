# Create Obsidian Vault
param(
    [string]$VaultPath = "C:\Obsidian\ObsidianVault",
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

function Write-WarningMessage {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Yellow
    }
}

function Test-ObsidianVaultExists {
    param([string]$Path)
    
    return (Test-Path $Path) -and (Test-Path (Join-Path $Path ".obsidian"))
}

function New-ObsidianVault {
    param([string]$VaultPath)
    
    try {
        # Create vault directory if it doesn't exist
        if (-not (Test-Path $VaultPath)) {
            Write-StatusMessage "Creating vault directory: $VaultPath"
            New-Item -Path $VaultPath -ItemType Directory -Force | Out-Null
        } else {
            Write-StatusMessage "Vault directory already exists: $VaultPath"
        }
        
        # Create .obsidian directory
        $obsidianDir = Join-Path $VaultPath ".obsidian"
        if (-not (Test-Path $obsidianDir)) {
            Write-StatusMessage "Creating .obsidian configuration directory"
            New-Item -Path $obsidianDir -ItemType Directory -Force | Out-Null
        } else {
            Write-StatusMessage ".obsidian directory already exists"
        }
        
        # Create basic app.json configuration
        $appJsonPath = Join-Path $obsidianDir "app.json"
        if (-not (Test-Path $appJsonPath)) {
            Write-StatusMessage "Creating app.json configuration"
            $appConfig = @{
                "promptDelete" = $true
                "showLineNumber" = $true
                "spellcheck" = $true
                "useMarkdownLinks" = $false
                "newFileLocation" = "root"
                "attachmentFolderPath" = "/"
            } | ConvertTo-Json -Depth 3
            
            Set-Content -Path $appJsonPath -Value $appConfig -Encoding UTF8
        } else {
            Write-StatusMessage "app.json already exists"
        }
        
        # Create basic appearance.json configuration
        $appearanceJsonPath = Join-Path $obsidianDir "appearance.json"
        if (-not (Test-Path $appearanceJsonPath)) {
            Write-StatusMessage "Creating appearance.json configuration"
            $appearanceConfig = @{
                "baseFontSize" = 16
                "theme" = "obsidian"
            } | ConvertTo-Json -Depth 3
            
            Set-Content -Path $appearanceJsonPath -Value $appearanceConfig -Encoding UTF8
        } else {
            Write-StatusMessage "appearance.json already exists"
        }
        
        # Create core-plugins.json
        $corePluginsPath = Join-Path $obsidianDir "core-plugins.json"
        if (-not (Test-Path $corePluginsPath)) {
            Write-StatusMessage "Creating core-plugins.json configuration"
            $corePlugins = @(
                "file-explorer",
                "global-search",
                "switcher",
                "graph",
                "backlink",
                "outgoing-links",
                "tag-pane",
                "page-preview",
                "daily-notes",
                "templates",
                "note-composer",
                "command-palette",
                "markdown-importer",
                "word-count",
                "open-with-default-app",
                "file-recovery"
            ) | ConvertTo-Json
            
            Set-Content -Path $corePluginsPath -Value $corePlugins -Encoding UTF8
        } else {
            Write-StatusMessage "core-plugins.json already exists"
        }
        
        # Create community-plugins.json (empty by default)
        $communityPluginsPath = Join-Path $obsidianDir "community-plugins.json"
        if (-not (Test-Path $communityPluginsPath)) {
            Write-StatusMessage "Creating community-plugins.json configuration"
            Set-Content -Path $communityPluginsPath -Value "[]" -Encoding UTF8
        } else {
            Write-StatusMessage "community-plugins.json already exists"
        }
        
        # Create workspace.json (basic workspace layout)
        $workspacePath = Join-Path $obsidianDir "workspace.json"
        if (-not (Test-Path $workspacePath)) {
            Write-StatusMessage "Creating workspace.json configuration"
            $workspaceConfig = @{
                "main" = @{
                    "id" = "main"
                    "type" = "split"
                    "dimension" = "vertical"
                    "children" = @(
                        @{
                            "id" = "leaf-1"
                            "type" = "leaf"
                            "state" = @{
                                "type" = "empty"
                                "state" = @{}
                            }
                        }
                    )
                }
                "left" = @{
                    "id" = "left"
                    "type" = "split"
                    "dimension" = "vertical"
                    "children" = @(
                        @{
                            "id" = "left-leaf"
                            "type" = "leaf"
                            "state" = @{
                                "type" = "file-explorer"
                                "state" = @{}
                            }
                        }
                    )
                }
                "right" = @{
                    "id" = "right"
                    "type" = "split"
                    "dimension" = "vertical"
                    "children" = @()
                }
                "active" = "leaf-1"
                "lastOpenFiles" = @()
            } | ConvertTo-Json -Depth 5
            
            Set-Content -Path $workspacePath -Value $workspaceConfig -Encoding UTF8
        } else {
            Write-StatusMessage "workspace.json already exists"
        }
        
        # Create a welcome note
        $welcomeNotePath = Join-Path $VaultPath "Welcome.md"
        if (-not (Test-Path $welcomeNotePath)) {
            Write-StatusMessage "Creating welcome note"
            $welcomeContent = @"
# Welcome to Your Obsidian Vault

This vault was created automatically on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss').

## Getting Started

- Create new notes by clicking the "New note" button or using Ctrl+N
- Link to other notes using [[Note Name]] syntax
- Use tags like #tag to organize your notes
- Explore the graph view to see connections between notes

## Useful Commands

- **Ctrl+O**: Quick switcher
- **Ctrl+Shift+F**: Search across all notes
- **Ctrl+G**: Open graph view
- **Ctrl+P**: Command palette

Happy note-taking!
"@
            Set-Content -Path $welcomeNotePath -Value $welcomeContent -Encoding UTF8
        } else {
            Write-StatusMessage "Welcome note already exists"
        }
        
        return $true
        
    } catch {
        Write-ErrorMessage "Error creating Obsidian vault: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Write-StatusMessage "Creating Obsidian vault at: $VaultPath"

# Check if vault already exists and is valid
if (Test-ObsidianVaultExists -Path $VaultPath) {
    Write-StatusMessage "Obsidian vault already exists and appears to be properly configured at: $VaultPath"
    exit 0
}

# Create the vault
if (New-ObsidianVault -VaultPath $VaultPath) {
    Write-StatusMessage "Successfully created Obsidian vault at: $VaultPath"
    Write-StatusMessage "You can now open this vault in Obsidian by selecting 'Open folder as vault' and choosing: $VaultPath"
    exit 0
} else {
    Write-ErrorMessage "Failed to create Obsidian vault"
    exit 1
}