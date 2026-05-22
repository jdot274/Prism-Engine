#[CmdletBinding()]
param(
    [switch]$DryRun
)

. (Join-Path $PSScriptRoot 'github-lib.ps1')

$files = Get-ChildItem -Path $script:QueueDir -Filter '*.json' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '.*' } |
    Sort-Object Name

if (-not $files) {
    Write-Host 'GitHub Queue is empty.'
    exit 0
}

Write-Host "Flushing $($files.Count) queued issues to GitHub..."
$failures = 0

foreach ($f in $files) {
    try {
        $wrapper = Get-Content $f.FullName -Raw | ConvertFrom-Json
        $payload = $wrapper.payload
        
        Write-Host "  -> $($f.Name)  title='$($payload.title)'"

        if ($DryRun) {
            continue
        }

        # Send to GitHub
        Create-GitHubIssue -Title $payload.title -Body $payload.body -Labels @($payload.labels) -SessionId $payload.session

        Remove-Item $f.FullName -Force
        Write-Host "    Successfully flushed and removed." -ForegroundColor Green
    } catch {
        $failures++
        Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
        Write-HookLog "flush-queue failed on $($f.Name): $($_.Exception.Message)" 'ERROR'
    }
}

if ($failures -gt 0) {
    Write-Host "$failures issue(s) failed to flush. Inspect $script:LogFile."
    exit 1
}

Write-Host 'GitHub Queue flushed.'
exit 0
