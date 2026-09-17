$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$py = Get-Command py -ErrorAction SilentlyContinue
$python = Get-Command python -ErrorAction SilentlyContinue
if ($py) {
  Start-Process -FilePath $py.Source -ArgumentList @('-3','run.py','--no-browser') -WorkingDirectory $root -WindowStyle Hidden
} elseif ($python) {
  Start-Process -FilePath $python.Source -ArgumentList @('run.py','--no-browser') -WorkingDirectory $root -WindowStyle Hidden
} else {
  Write-Host 'Python 3 not found.'
  exit 1
}
for ($i=0; $i -lt 30; $i++) {
  Start-Sleep -Milliseconds 200
  try {
    $r = Invoke-RestMethod -Uri 'http://127.0.0.1:8755/api/health' -TimeoutSec 1
    if ($r.ok) { Start-Process 'http://127.0.0.1:8755/'; Write-Host 'Agent Observatory started in background.'; exit 0 }
  } catch {}
}
Write-Host 'Observer process was launched, but the dashboard did not answer within 6 seconds. Run DIAGNOSE.ps1 if needed.'
