#!/usr/bin/env pwsh
# sync-to-github.ps1 — Cursor `stop` hook.
#
# Reads the last assistant turn from the most-recent transcript JSONL,
# extracts `finding` / `decision` / `action` fenced blocks, and pushes them
# to the Prism Engine GitHub Issues board AND the Obsidian AI Knowledge Vault.
#
# Failure semantics:
#   - Any unhandled error returns exit 0 (fail-open). The hook must never block
#     the agent. Unsent payloads are written to the local queue/ folder.
#   - No secrets are ever written to disk or the log.

$ErrorActionPreference = 'Continue'

# Always read stdin (Cursor sends a JSON payload), but we don't strictly need it.
$stdin = ''
try {
    if (-not [Console]::IsInputRedirected) {
        # No stdin attached — likely a manual test invocation. Continue silently.
    } else {
        $stdin = [Console]::In.ReadToEnd()
    }
} catch { }

. (Join-Path $PSScriptRoot 'github-lib.ps1')

Write-HookLog "sync-to-github/vault invoked (stdin bytes: $($stdin.Length))"

$vaultDir = "C:\Users\joeyw\Desktop\ai-knowledge-vault"
$graphPath = Join-Path $vaultDir "concepts-graph.json"
$indexerScript = Join-Path $vaultDir "tools\update-vault-index.ps1"

# Helpers inside sync script
function Get-KebabCase {
    param([string]$Title)
    $clean = $Title.ToLower()
    $clean = [regex]::Replace($clean, '[^a-z0-9\s-]', '')
    $clean = [regex]::Replace($clean, '[\s-]+', '-')
    return $clean.Trim('-')
}

function Resolve-ConceptRelations {
    param(
        [string]$TopicList,
        [string]$GraphPath
    )
    
    $parent = "General"
    $siblings = @()
    $children = @()
    
    if (-not (Test-Path $GraphPath)) {
        return @{ "parent" = "General"; "siblings" = @(); "children" = @() }
    }
    
    try {
        $graph = Get-Content $GraphPath -Raw | ConvertFrom-Json
        $concepts = $graph.concepts
        
        # Split topics list, e.g. "[PlayCanvas, GaussianSplats]" or "PlayCanvas, GaussianSplats"
        $topics = $TopicList -replace '[\[\]]', '' -split ',\s*' | ForEach-Object { $_.Trim('"', "'") }
        
        foreach ($topic in $topics) {
            foreach ($p in $concepts.PSObject.Properties) {
                if ($p.Name.ToLower() -eq $topic.ToLower()) {
                    $node = $p.Value
                    if ($node.parent -and $node.parent -ne "Root" -and $node.parent -ne "None") { $parent = $node.parent }
                    if ($node.siblings) { $siblings += @($node.siblings) }
                    if ($node.children) { $children += @($node.children) }
                }
            }
        }
    } catch {
        Write-HookLog "failed to resolve concept relations: $_" 'WARN'
    }
    
    $siblings = $siblings | Select-Object -Unique | Where-Object { $_ }
    $children = $children | Select-Object -Unique | Where-Object { $_ }
    
    return @{
        "parent" = $parent
        "siblings" = $siblings
        "children" = $children
    }
}

try {
    # 1. Resolve transcript to read from. Prefer payload hint, else most recent.
    $transcriptPath = $null
    if ($stdin) {
        try {
            $payload = $stdin | ConvertFrom-Json
            foreach ($k in 'transcript_path','transcriptPath','transcript','agent_transcript_path') {
                if ($payload.$k) { $transcriptPath = [string]$payload.$k; break }
            }
        } catch { }
    }
    if (-not $transcriptPath) {
        $latest = Find-LatestTranscript
        if ($latest) { $transcriptPath = $latest.FullName }
    }
    if (-not $transcriptPath -or -not (Test-Path $transcriptPath)) {
        Write-HookLog "no transcript found, exiting" 'WARN'
        exit 0
    }

    # 2. Read only new content since last offset.
    $offsets = Get-Offsets
    $startOffset = if ($offsets[$transcriptPath]) { [int64]$offsets[$transcriptPath] } else { 0 }
    $read = Read-NewAssistantText -TranscriptPath $transcriptPath -StartOffset $startOffset
    $newText = $read.Text
    $newOffset = $read.NewOffset

    if (-not $newText) {
        $offsets[$transcriptPath] = $newOffset
        Set-Offsets $offsets
        Write-HookLog "no new assistant text"
        exit 0
    }

    # 3. Extract capture blocks.
    $blocks = Extract-CaptureBlocks -Text $newText
    if (-not $blocks -or $blocks.Count -eq 0) {
        $offsets[$transcriptPath] = $newOffset
        Set-Offsets $offsets
        Write-HookLog "no capture blocks in new text"
        exit 0
    }
    Write-HookLog "found $($blocks.Count) capture blocks"

    # 4. Redact and process blocks.
    $sessionId = [System.IO.Path]::GetFileNameWithoutExtension($transcriptPath)

    foreach ($b in $blocks) {
        $sanitizedBody = Redact-Secrets $b.Body
        $props = Parse-BlockYaml -Body $sanitizedBody
        
        $title = $props['title']
        if (-not $title) {
            Write-HookLog "block missing title, skipping" 'WARN'
            continue
        }

        # Resolve links and concept taxonomy
        $topicsText = if ($props['topics']) { $props['topics'] } else { $props['tags'] }
        $relations = Resolve-ConceptRelations -TopicList $topicsText -GraphPath $graphPath
        
        $parentConcept = $relations.parent
        $siblingConcepts = $relations.siblings
        $childConcepts = $relations.children

        # Build GitHub Issue properties
        $labels = [System.Collections.Generic.List[string]]::new()
        $labels.Add("type/$($b.Kind)")

        $bodyBuilder = New-Object System.Text.StringBuilder
        [void]$bodyBuilder.AppendLine("<!-- PRISM-ENGINE AGENT CAPTURE -->")
        [void]$bodyBuilder.AppendLine("## Ledger Metadata")
        [void]$bodyBuilder.AppendLine("| Property | Value |")
        [void]$bodyBuilder.AppendLine("| --- | --- |")
        [void]$bodyBuilder.AppendLine("| **Type** | $($b.Kind.ToUpper()) |")
        [void]$bodyBuilder.AppendLine("| **Session ID** | ``$sessionId`` |")

        if ($topicsText) {
            [void]$bodyBuilder.AppendLine("| **Topics** | $topicsText |")
        }
        if ($props['confidence']) {
            $conf = $props['confidence'].ToLower()
            $labels.Add("confidence/$conf")
            [void]$bodyBuilder.AppendLine("| **Confidence** | $($props['confidence']) |")
        }
        if ($props['status']) {
            $stat = $props['status'].ToLower()
            $labels.Add("status/$stat")
            [void]$bodyBuilder.AppendLine("| **Status** | $($props['status']) |")
        }
        [void]$bodyBuilder.AppendLine("| **Parent Concept** | $parentConcept |")
        [void]$bodyBuilder.AppendLine()
        [void]$bodyBuilder.AppendLine("---")
        [void]$bodyBuilder.AppendLine()

        # Build Vault Markdown Frontmatter
        $vaultFM = New-Object System.Text.StringBuilder
        [void]$vaultFM.AppendLine("---")
        [void]$vaultFM.AppendLine("title: `"$title`"")
        [void]$vaultFM.AppendLine("type: `"$($b.Kind)`"")
        
        $tagArrayStr = if ($topicsText) {
            $cleanTags = $topicsText -replace '[\[\]]', '' -split ',\s*' | ForEach-Object { Get-KebabCase $_ }
            $cleanTags += Get-KebabCase $b.Kind
            "[" + (($cleanTags | Select-Object -Unique) -join ", ") + "]"
        } else {
            "[$($b.Kind)]"
        }
        [void]$vaultFM.AppendLine("tags: $tagArrayStr")
        
        [void]$vaultFM.AppendLine("created: `"$((Get-Date).ToString('yyyy-MM-dd'))`"")
        [void]$vaultFM.AppendLine("session: `"$sessionId`"")
        if ($props['confidence']) { [void]$vaultFM.AppendLine("confidence: `"$($props['confidence'])`"") }
        if ($props['status']) { [void]$vaultFM.AppendLine("status: `"$($props['status'])`"") }
        [void]$vaultFM.AppendLine("parent: `"$parentConcept`"")
        if ($siblingConcepts.Count -gt 0) {
            $sibsStr = "[" + (($siblingConcepts | ForEach-Object { "`"$_`"" }) -join ", ") + "]"
            [void]$vaultFM.AppendLine("siblings: $sibsStr")
        }
        if ($childConcepts.Count -gt 0) {
            $kidsStr = "[" + (($childConcepts | ForEach-Object { "`"$_`"" }) -join ", ") + "]"
            [void]$vaultFM.AppendLine("children: $kidsStr")
        }
        [void]$vaultFM.AppendLine("---")
        [void]$vaultFM.AppendLine()

        # Build content body based on block type
        $vaultBody = New-Object System.Text.StringBuilder
        [void]$vaultBody.AppendLine("# $title")
        [void]$vaultBody.AppendLine()

        switch ($b.Kind) {
            'finding' {
                [void]$bodyBuilder.AppendLine("## Finding / Discovery")
                [void]$bodyBuilder.AppendLine($props['body'])
                
                [void]$vaultBody.AppendLine("## Finding / Discovery")
                [void]$vaultBody.AppendLine($props['body'])
            }
            'decision' {
                [void]$bodyBuilder.AppendLine("## Decision")
                [void]$bodyBuilder.AppendLine($props['rationale'])
                if ($props['trade-offs']) {
                    [void]$bodyBuilder.AppendLine()
                    [void]$bodyBuilder.AppendLine("### Trade-Offs")
                    [void]$bodyBuilder.AppendLine($props['trade-offs'])
                }
                
                [void]$vaultBody.AppendLine("## Rationale")
                [void]$vaultBody.AppendLine($props['rationale'])
                if ($props['trade-offs']) {
                    [void]$vaultBody.AppendLine()
                    [void]$vaultBody.AppendLine("### Trade-Offs")
                    [void]$vaultBody.AppendLine($props['trade-offs'])
                }
            }
            'action' {
                [void]$bodyBuilder.AppendLine("## Action Item / TODO")
                [void]$bodyBuilder.AppendLine($props['notes'])
                if ($props['owner']) {
                    [void]$bodyBuilder.AppendLine()
                    [void]$bodyBuilder.AppendLine("**Owner**: @$($props['owner'])")
                }
                if ($props['due']) {
                    [void]$bodyBuilder.AppendLine()
                    [void]$bodyBuilder.AppendLine("**Due Date**: $($props['due'])")
                }
                
                [void]$vaultBody.AppendLine("## Plan")
                [void]$vaultBody.AppendLine($props['notes'])
                [void]$vaultBody.AppendLine()
                [void]$vaultBody.AppendLine("| Property | Value |")
                [void]$vaultBody.AppendLine("| --- | --- |")
                if ($props['owner']) { [void]$vaultBody.AppendLine("| **Owner** | @$($props['owner']) |") }
                if ($props['due']) { [void]$vaultBody.AppendLine("| **Due Date** | $($props['due']) |") }
                if ($props['status']) { [void]$vaultBody.AppendLine("| **Status** | `$($props['status'])` |") }
            }
        }

        # Concept Map Section for Vault
        [void]$vaultBody.AppendLine()
        [void]$vaultBody.AppendLine("## 🕸️ Concept Navigation Map")
        [void]$vaultBody.AppendLine()
        [void]$vaultBody.AppendLine("- ⬆️ **Parent**: [[$parentConcept]]")
        
        if ($siblingConcepts.Count -gt 0) {
            $sibsLinks = ($siblingConcepts | ForEach-Object { "[[$_]]" }) -join ", "
            [void]$vaultBody.AppendLine("- ⬅️ **Siblings**: $sibsLinks")
        } else {
            [void]$vaultBody.AppendLine("- ⬅️ **Siblings**: *None*")
        }
        
        if ($childConcepts.Count -gt 0) {
            $kidsLinks = ($childConcepts | ForEach-Object { "[[$_]]" }) -join ", "
            [void]$vaultBody.AppendLine("- ⬇️ **Children**: $kidsLinks")
        } else {
            [void]$vaultBody.AppendLine("- ⬇️ **Children**: *None*")
        }

        # Determine vault directory and filename
        $folderName = if ($b.Kind -eq 'action') { "01_Projects" } else { "03_KnowledgeGraph" }
        $fileName = (Get-KebabCase $title) + ".md"
        $vaultFilePath = Join-Path $vaultDir (Join-Path $folderName $fileName)

        # Write note to Vault!
        $fullVaultContent = $vaultFM.ToString() + $vaultBody.ToString()
        [System.IO.File]::WriteAllText($vaultFilePath, $fullVaultContent, [System.Text.Encoding]::UTF8)
        Write-HookLog "Saved Obsidian note: $vaultFilePath"

        # Try to post to GitHub Issues as well
        $issueBody = $bodyBuilder.ToString()
        try {
            Create-GitHubIssue -Title $title -Body $issueBody -Labels $labels.ToArray() -SessionId $sessionId
        } catch {
            $reason = $_.Exception.Message
            Write-HookLog "GitHub Issue create failed ($reason), queuing payload" 'WARN'
            
            $queuePath = Queue-Payload -Reason $reason -Payload (@{
                title   = $title
                body    = $issueBody
                labels  = $labels.ToArray()
                session = $sessionId
            })
            Write-HookLog "queued to $queuePath"
        }
    }

    # 5. Rebuild Vault index dynamically
    if (Test-Path $indexerScript) {
        Write-HookLog "Executing vault indexer..."
        pwsh.exe -NoProfile -ExecutionPolicy Bypass -File $indexerScript
    }

    # 6. Commit Vault Changes locally
    try {
        Write-HookLog "Staging and committing local vault changes..."
        $null = & git -C $vaultDir add . 2>&1
        $status = & git -C $vaultDir status --porcelain 2>&1
        if ($status) {
            $null = & git -C $vaultDir commit -m "auto: Sync captured knowledge and rebuild index" 2>&1
            Write-HookLog "Committed vault changes successfully."
        } else {
            Write-HookLog "No vault changes to commit."
        }
    } catch {
        Write-HookLog "Failed to commit vault changes: $_" 'WARN'
    }

    # 7. Advance offset.
    $offsets[$transcriptPath] = $newOffset
    Set-Offsets $offsets
    Write-HookLog "done; new offset = $newOffset"
    exit 0
} catch {
    $errStr = $_.Exception.Message
    Write-HookLog "unexpected error: $errStr" 'ERROR'
    exit 0
}
