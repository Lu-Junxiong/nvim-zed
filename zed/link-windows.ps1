# Run once from an elevated Windows PowerShell.
[CmdletBinding()]
param(
    [string]$ConfigDirectory = (Join-Path $env:APPDATA 'Zed')
)

$ErrorActionPreference = 'Stop'
$names = @('settings.json', 'keymap.json')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$prepared = @()
$done = @()

try {
    # Prepare and verify both links before replacing either configuration.
    foreach ($name in $names) {
        $original = Join-Path $ConfigDirectory $name
        $target = Join-Path $PSScriptRoot $name
        $item = Get-Item -LiteralPath $original
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "Already a link; inspect before replacing: $original"
        }
        $temp = "$original.link-$stamp"
        New-Item -ItemType SymbolicLink -Path $temp -Target $target | Out-Null
        $prepared += $temp
        if ((Get-FileHash -LiteralPath $temp).Hash -ne (Get-FileHash -LiteralPath $original).Hash) {
            throw "Files differ; reconcile them before linking: $name"
        }
    }

    foreach ($name in $names) {
        $original = Join-Path $ConfigDirectory $name
        $backup = "$original.bak-$stamp"
        Move-Item -LiteralPath $original -Destination $backup
        try {
            Move-Item -LiteralPath "$original.link-$stamp" -Destination $original
        } catch {
            Move-Item -LiteralPath $backup -Destination $original
            throw
        }
        $done += $name
    }

    foreach ($name in $names) {
        Get-Item -LiteralPath (Join-Path $ConfigDirectory $name) |
            Select-Object FullName, LinkType, Target
    }
    Write-Host "Original files preserved as *.bak-$stamp"
} catch {
    foreach ($name in $done) {
        $original = Join-Path $ConfigDirectory $name
        Remove-Item -LiteralPath $original -Force
        Move-Item -LiteralPath "$original.bak-$stamp" -Destination $original
    }
    throw
} finally {
    foreach ($temp in $prepared) {
        if (Test-Path -LiteralPath $temp) {
            Remove-Item -LiteralPath $temp -Force
        }
    }
}
