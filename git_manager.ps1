# Git Manager for MultiSpace Cloner
# Advanced Git Upload System with Error Handling

Param(
    [string]$Message = "",
    [switch]$Quick,
    [switch]$Status,
    [switch]$Help
)

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-Help {
    Write-ColorText "=== Git Manager for MultiSpace Cloner ===" $Cyan
    Write-Host ""
    Write-ColorText "Usage:" $Yellow
    Write-Host "  .\git_manager.ps1 [options]"
    Write-Host ""
    Write-ColorText "Options:" $Yellow
    Write-Host "  -Message 'text'    Custom commit message"
    Write-Host "  -Quick             Quick upload with auto message"
    Write-Host "  -Status            Show git status only"
    Write-Host "  -Help              Show this help"
    Write-Host ""
    Write-ColorText "Examples:" $Yellow
    Write-Host "  .\git_manager.ps1 -Message 'Added new features'"
    Write-Host "  .\git_manager.ps1 -Quick"
    Write-Host "  .\git_manager.ps1 -Status"
}

function Test-GitAvailable {
    try {
        git --version | Out-Null
        return $true
    }
    catch {
        Write-ColorText "❌ Git is not installed or not in PATH" $Red
        return $false
    }
}

function Test-GitRepository {
    try {
        git status | Out-Null
        return $true
    }
    catch {
        Write-ColorText "❌ This is not a git repository" $Red
        Write-ColorText "💡 Initialize with: git init" $Yellow
        return $false
    }
}

function Get-GitStatus {
    Write-ColorText "📋 Current Git Status:" $Cyan
    Write-Host ""
    
    # Show branch info
    $branch = git branch --show-current
    Write-ColorText "🌿 Current branch: $branch" $Green
    
    # Show status
    $status = git status --porcelain
    if ($status) {
        Write-ColorText "📝 Changes detected:" $Yellow
        git status --short
    } else {
        Write-ColorText "✅ Working directory clean" $Green
    }
    
    Write-Host ""
    
    # Show last commit
    Write-ColorText "📅 Last commit:" $Cyan
    git log -1 --oneline
    Write-Host ""
}

function Invoke-GitUpload {
    param([string]$CommitMessage)
    
    Write-ColorText "🚀 Starting Git Upload Process..." $Cyan
    Write-Host ""
    
    # Check for changes
    $hasChanges = git diff --quiet; $?
    $hasStagedChanges = git diff --cached --quiet; $?
    
    if ($hasChanges -and $hasStagedChanges) {
        Write-ColorText "ℹ️  No changes detected" $Yellow
        $continue = Read-Host "Continue anyway? (y/N)"
        if ($continue -ne "y" -and $continue -ne "Y") {
            Write-ColorText "Operation cancelled" $Yellow
            return
        }
    }
    
    # Add changes
    Write-ColorText "📦 Adding all changes..." $Yellow
    try {
        git add .
        Write-ColorText "✅ Changes added successfully" $Green
    }
    catch {
        Write-ColorText "❌ Failed to add changes: $_" $Red
        return
    }
    
    # Generate commit message if not provided
    if (-not $CommitMessage) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $CommitMessage = "Auto commit - $timestamp"
    }
    
    # Commit changes
    Write-ColorText "💾 Committing changes..." $Yellow
    try {
        git commit -m $CommitMessage
        Write-ColorText "✅ Changes committed successfully" $Green
        Write-ColorText "📝 Commit message: $CommitMessage" $Cyan
    }
    catch {
        Write-ColorText "❌ Failed to commit changes: $_" $Red
        return
    }
    
    # Push to remote
    Write-ColorText "🚀 Pushing to GitHub..." $Yellow
    try {
        git push
        Write-ColorText "✅ Successfully pushed to GitHub!" $Green
        Write-Host ""
        Write-ColorText "🎉 Upload completed successfully!" $Green
    }
    catch {
        Write-ColorText "❌ Failed to push to GitHub: $_" $Red
        Write-Host ""
        Write-ColorText "💡 Possible solutions:" $Yellow
        Write-Host "   1. Check your internet connection"
        Write-Host "   2. Verify GitHub credentials"
        Write-Host "   3. Make sure remote origin is set correctly"
        Write-Host ""
        Write-ColorText "🔧 To set remote origin:" $Cyan
        Write-Host "   git remote add origin https://github.com/username/repository.git"
    }
}

# Main execution
Clear-Host
Write-ColorText "=== MultiSpace Cloner - Git Manager ===" $Cyan
Write-Host ""

if ($Help) {
    Show-Help
    exit
}

if (-not (Test-GitAvailable)) {
    exit 1
}

if (-not (Test-GitRepository)) {
    exit 1
}

if ($Status) {
    Get-GitStatus
    exit
}

if ($Quick) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Invoke-GitUpload "Quick update - $timestamp"
} elseif ($Message) {
    Invoke-GitUpload $Message
} else {
    Get-GitStatus
    Write-Host ""
    $userMessage = Read-Host "💬 Enter commit message (or press Enter for auto-generated)"
    Invoke-GitUpload $userMessage
}

Write-Host ""
Write-ColorText "Press any key to exit..." $Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")