# Copy configuration as regular files: Windows-to-WSL links break Zed's file access.
[CmdletBinding()]
param(
    [ValidateSet('push', 'pull')]
    [string]$Direction = 'push',
    [string]$ConfigDirectory = (Join-Path $env:APPDATA 'Zed')
)

$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$sourceDirectory = $PSScriptRoot
$destinationDirectory = $ConfigDirectory
if ($Direction -eq 'pull') {
    $sourceDirectory = $ConfigDirectory
    $destinationDirectory = $PSScriptRoot
}

foreach ($name in @('settings.json', 'keymap.json')) {
    $source = Join-Path $sourceDirectory $name
    $destination = Join-Path $destinationDirectory $name
    $item = Get-Item -LiteralPath $destination -ErrorAction SilentlyContinue
    $isLink = $item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    $sourceHash = (Get-FileHash -LiteralPath $source).Hash
    if ($item -and !$isLink -and $sourceHash -eq (Get-FileHash -LiteralPath $destination).Hash) {
        Write-Host "Unchanged: $destination"
        continue
    }

    $temp = "$destination.sync-$stamp"
    $backup = "$destination.bak-$stamp"
    try {
        Copy-Item -LiteralPath $source -Destination $temp
        if ((Get-FileHash -LiteralPath $temp).Hash -ne $sourceHash) {
            throw "Copy verification failed: $name"
        }
        if ($item) {
            # Back up contents, not the link, so the backup remains independent.
            Copy-Item -LiteralPath $destination -Destination $backup
            if ((Get-FileHash -LiteralPath $backup).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
                throw "Backup verification failed: $name"
            }
            Remove-Item -LiteralPath $destination -Force
        }
        try {
            Move-Item -LiteralPath $temp -Destination $destination
        } catch {
            if ($item) { Copy-Item -LiteralPath $backup -Destination $destination }
            throw
        }
        Write-Host "Synced: $destination"
        if ($item) { Write-Host "Backup: $backup" }
    } finally {
        if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Force }
    }
}
