$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$pidFile = Join-Path $root 'data\observer.pid'
if (-not (Test-Path $pidFile)) {
  Write-Host 'Agent Observatory is not running (no PID file).'
  exit 0
}
$observerPid = [int](Get-Content $pidFile -Raw).Trim()
$p = Get-CimInstance Win32_Process -Filter "ProcessId=$observerPid"
if ($null -eq $p) {
  Remove-Item $pidFile -Force
  Write-Host 'Stale PID file removed.'
  exit 0
}
$cmd = [string]$p.CommandLine
if ($cmd -notmatch 'run\.py|observatory\.app') {
  Write-Host "PID $observerPid does not look like Agent Observatory. Refusing to kill it."
  exit 1
}
Stop-Process -Id $observerPid -Force
Start-Sleep -Milliseconds 300
Remove-Item $pidFile -Force
Write-Host "Agent Observatory stopped (PID $observerPid)."
