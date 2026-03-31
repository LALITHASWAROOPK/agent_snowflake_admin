$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

$pythonExe = Join-Path $repoRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $pythonExe)) {
    Write-Host "Virtual env python not found at $pythonExe. Falling back to 'python'."
    $pythonExe = "python"
}

if (-not (Test-Path ".env")) {
    Write-Warning ".env not found in repo root. MCP may fail to authenticate."
}

$listener = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    $pids = $listener | Select-Object -ExpandProperty OwningProcess -Unique
    foreach ($procId in $pids) {
        try {
            Stop-Process -Id $procId -Force -ErrorAction Stop
            Write-Host "Stopped process $procId on port 3000"
        }
        catch {
            Write-Warning "Could not stop process ${procId}: $($_.Exception.Message)"
        }
    }
}

Write-Host "Starting generic Admin MCP server..."
& $pythonExe "mcp/server.py"
