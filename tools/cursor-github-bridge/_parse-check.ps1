$ErrorActionPreference = 'Continue'
foreach ($f in 'github-lib.ps1','sync-to-github.ps1','flush-queue.ps1') {
    $path = Join-Path $PSScriptRoot $f
    try {
        $null = [scriptblock]::Create((Get-Content $path -Raw))
        Write-Host ("OK  : " + $f)
    } catch {
        Write-Host ("FAIL: " + $f + " -- " + $_.Exception.Message)
    }
}

. (Join-Path $PSScriptRoot 'github-lib.ps1')
Write-Host ("QueueDir = " + $script:QueueDir)

$blocks = Extract-CaptureBlocks -Text @"
hello world

``````finding
title: Test Finding
topics: [A, B]
confidence: Confirmed
body: |
  Just a test.
``````

middle stuff

``````action
title: Probe action
owner: Agent
status: Open
notes: |
  Action notes here.
``````
"@
Write-Host ("Extracted blocks: " + $blocks.Count + " (kinds: " + (($blocks.Kind) -join ',') + ")")
