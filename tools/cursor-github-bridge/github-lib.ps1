# github-lib.ps1 — shared helpers for the GitHub knowledge-capture hook system.
# Dot-source this from sync-to-github.ps1, backfill.ps1 and flush-queue.ps1.
#
# Never logs secrets. Uses the pre-authenticated 'gh' CLI.

$script:QueueDir   = Join-Path $PSScriptRoot 'queue'
$script:OffsetFile = Join-Path $script:QueueDir '.last-processed-offsets.json'
$script:LogFile    = Join-Path $script:QueueDir '.hook.log'

# Desired repository labels
$script:Labels = @(
    [pscustomobject]@{ Name = 'type/finding';        Color = '1D76DB'; Description = 'Core system finding or fact' }
    [pscustomobject]@{ Name = 'type/decision';       Color = '5319E7'; Description = 'Strategic architecture/technology decision' }
    [pscustomobject]@{ Name = 'type/action-item';    Color = 'E99695'; Description = 'Actionable developer TODO or requirement' }
    [pscustomobject]@{ Name = 'status/graduated-tool'; Color = '0E8A16'; Description = 'Evolved from action item into active stack tool' }
    [pscustomobject]@{ Name = 'confidence/confirmed'; Color = '0E8A16'; Description = 'Confirmed facts or verified setups' }
    [pscustomobject]@{ Name = 'confidence/likely';    Color = 'FBCA04'; Description = 'Highly probable facts or planned paths' }
    [pscustomobject]@{ Name = 'confidence/hypothesis';Color = 'D93F0B'; Description = 'Unverified assumptions or active bets' }
)

function Write-HookLog {
    param([string]$Message, [string]$Level = 'INFO')
    try {
        New-Item -ItemType Directory -Force -Path $script:QueueDir | Out-Null
        $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'), $Level, $Message
        Add-Content -Path $script:LogFile -Value $line -ErrorAction SilentlyContinue
    } catch { }
}

# Redact known secret patterns from text BEFORE it goes anywhere persistent.
function Redact-Secrets {
    param([string]$Text)
    if (-not $Text) { return $Text }
    $patterns = @(
        @{ Pattern = 'gh[pousr]_[A-Za-z0-9_]{20,}'; Replacement = '<redacted-github-token>' }
        @{ Pattern = 'github_pat_[A-Za-z0-9_]+';   Replacement = '<redacted-github-pat>' }
        @{ Pattern = 'sk-[A-Za-z0-9_-]{20,}';      Replacement = '<redacted-openai-key>' }
        @{ Pattern = 'sk-ant-[A-Za-z0-9_-]+';      Replacement = '<redacted-anthropic-key>' }
        @{ Pattern = 'secret_[A-Za-z0-9]{40,}';    Replacement = '<redacted-notion-secret>' }
        @{ Pattern = 'ntn_[A-Za-z0-9_]{40,}';      Replacement = '<redacted-notion-integration-token>' }
        @{ Pattern = 'AIza[A-Za-z0-9_-]{30,}';     Replacement = '<redacted-google-api-key>' }
        @{ Pattern = '"Authorization"\s*:\s*"Bearer [^"]+"'; Replacement = '"Authorization": "Bearer <redacted>"' }
    )
    foreach ($p in $patterns) {
        $Text = [regex]::Replace($Text, $p.Pattern, $p.Replacement)
    }
    return $Text
}

$script:LabelsChecked = $false

# Ensure all labels exist in the current GitHub repo.
function Ensure-GitHubLabels {
    if ($script:LabelsChecked) { return }
    Write-HookLog "checking GitHub labels..."
    try {
        $existingLabels = & gh label list --json name 2>$null | ConvertFrom-Json
        $existingNames = if ($existingLabels) { $existingLabels.name } else { @() }
        
        foreach ($l in $script:Labels) {
            if ($existingNames -notcontains $l.Name) {
                Write-HookLog "creating missing label: $($l.Name)"
                try {
                    & gh label create $l.Name --color $l.Color --description $l.Description --force 2>$null
                } catch {
                    Write-HookLog "failed to create label $($l.Name): $_" 'WARN'
                }
            }
        }
        $script:LabelsChecked = $true
    } catch {
        Write-HookLog "failed to get labels list: $_" 'WARN'
    }
}

# Track per-transcript byte offset so we don't re-process the same lines.
function Get-Offsets {
    if (-not (Test-Path $script:OffsetFile)) { return @{} }
    try {
        return (Get-Content $script:OffsetFile -Raw | ConvertFrom-Json -AsHashtable)
    } catch {
        return @{}
    }
}

function Set-Offsets {
    param([hashtable]$Offsets)
    New-Item -ItemType Directory -Force -Path $script:QueueDir | Out-Null
    ($Offsets | ConvertTo-Json -Depth 5) | Set-Content -Path $script:OffsetFile -Encoding UTF8
}

# Discover the most recently modified transcript JSONL across Cursor projects.
function Find-LatestTranscript {
    $root = Join-Path $env:USERPROFILE '.cursor\projects'
    if (-not (Test-Path $root)) { return $null }
    $files = Get-ChildItem -Path $root -Recurse -Force -Filter '*.jsonl' -ErrorAction SilentlyContinue |
        Where-Object { $_.DirectoryName -notlike '*subagents*' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    return $files
}

# Extract fenced blocks of type `finding|decision|action` from a markdown string.
function Extract-CaptureBlocks {
    param([string]$Text)
    if (-not $Text) { return @() }
    $blocks = @()
    $pattern = '(?ms)^```(finding|decision|action)\s*\r?\n(.*?)\r?\n```'
    foreach ($m in [regex]::Matches($Text, $pattern)) {
        $blocks += [pscustomobject]@{
            Kind = $m.Groups[1].Value
            Body = $m.Groups[2].Value
        }
    }
    return $blocks
}

# Read new assistant-text since the last offset for one transcript file.
function Read-NewAssistantText {
    param([string]$TranscriptPath, [int64]$StartOffset)
    if (-not (Test-Path $TranscriptPath)) { return @{ Text = ''; NewOffset = $StartOffset } }
    $fi = Get-Item -LiteralPath $TranscriptPath
    if ($fi.Length -le $StartOffset) {
        return @{ Text = ''; NewOffset = $fi.Length }
    }
    $fs = [System.IO.File]::Open($TranscriptPath, 'Open', 'Read', 'ReadWrite')
    try {
        [void]$fs.Seek($StartOffset, 'Begin')
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        $newText = $sr.ReadToEnd()
        $sr.Close()
    } finally {
        $fs.Dispose()
    }
    # Each line is a JSON object — pull only the assistant text content.
    $assistantBuf = New-Object System.Text.StringBuilder
    foreach ($line in $newText -split "`n") {
        $line = $line.Trim()
        if (-not $line) { continue }
        try {
            $evt = $line | ConvertFrom-Json
        } catch { continue }
        if ($evt.role -ne 'assistant') { continue }
        if (-not $evt.message.content) { continue }
        foreach ($block in $evt.message.content) {
            if ($block.type -eq 'text' -and $block.text) {
                [void]$assistantBuf.AppendLine($block.text)
            }
        }
    }
    return @{
        Text      = $assistantBuf.ToString()
        NewOffset = $fi.Length
    }
}

# Parse YAML-like keys from fenced blocks
function Parse-BlockYaml {
    param([string]$Body)
    $props = @{}
    $currentKey = $null
    $multiline = $false
    $multilineBuf = New-Object System.Text.StringBuilder
    foreach ($line in $Body -split "`r?`n") {
        if ($multiline) {
            if ($line -match '^[A-Za-z_-]+:\s') {
                $props[$currentKey] = $multilineBuf.ToString().TrimEnd()
                $multiline = $false
                $multilineBuf = New-Object System.Text.StringBuilder
                # fall through to handle this new key
            } else {
                [void]$multilineBuf.AppendLine(($line -replace '^\s\s', ''))
                continue
            }
        }
        if ($line -match '^([A-Za-z_-]+):\s*\|\s*$') {
            $currentKey = $Matches[1].ToLower()
            $multiline = $true
            continue
        }
        if ($line -match '^([A-Za-z_-]+):\s*(.+)$') {
            $k = $Matches[1].ToLower()
            $v = $Matches[2].Trim()
            $props[$k] = $v
        }
    }
    if ($multiline) {
        $props[$currentKey] = $multilineBuf.ToString().TrimEnd()
    }
    return $props
}

# Create a GitHub Issue using gh CLI. Deduplicates based on existing issue titles to avoid noise!
function Create-GitHubIssue {
    param(
        [Parameter(Mandatory)] [string]$Title,
        [Parameter(Mandatory)] [string]$Body,
        [Parameter(Mandatory)] [string[]]$Labels,
        [string]$SessionId = $null
    )
    # Check if a matching issue already exists (open or closed)
    $exists = $false
    try {
        # gh issue list output is TSV: Number | Title | Labels | Status
        $issues = & gh issue list --limit 100 --state all --json title 2>$null | ConvertFrom-Json
        foreach ($issue in $issues) {
            if ($issue.title.Trim() -eq $Title.Trim()) {
                $exists = $true
                break
            }
        }
    } catch { }

    if ($exists) {
        Write-HookLog "issue already exists, skipping: $Title"
        return
    }

    # Ensure labels exist
    Ensure-GitHubLabels

    # Format command params
    $labelsArg = $Labels -join ','
    
    # Create the issue
    Write-HookLog "creating issue: $Title (labels: $labelsArg)"
    try {
        $newIssueUrl = & gh issue create --title $Title --body $Body --label $labelsArg --assignee "@me" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Created Issue: $newIssueUrl"
            Write-HookLog "created issue successfully: $newIssueUrl"
        } else {
            throw "gh issue create failed: $newIssueUrl"
        }
    } catch {
        Write-HookLog "failed to create issue: $_" 'WARN'
        throw $_
    }
}

# Persist a queued payload to disk; never includes secrets.
function Queue-Payload {
    param(
        [Parameter(Mandatory)] [object]$Payload,
        [string]$Reason = 'offline-or-error'
    )
    New-Item -ItemType Directory -Force -Path $script:QueueDir | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
    $path = Join-Path $script:QueueDir "$stamp.json"
    $wrapper = @{
        queuedAt = (Get-Date -Format 'o')
        reason   = $Reason
        payload  = $Payload
    }
    ($wrapper | ConvertTo-Json -Depth 20) | Set-Content -Path $path -Encoding UTF8
    return $path
}
