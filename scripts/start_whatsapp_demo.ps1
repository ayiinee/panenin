$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Python = Join-Path $Root "backend\.venv\Scripts\python.exe"

if (-not (Test-Path $Python)) {
    throw "Virtual environment backend belum tersedia: $Python"
}

Write-Host "Panenin Core  : http://127.0.0.1:8001"
Write-Host "WhatsApp bot : http://127.0.0.1:8000"
Write-Host "Demo chat    : http://127.0.0.1:8000/demo"

Start-Process -FilePath $Python `
    -ArgumentList "-m", "uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8001" `
    -WorkingDirectory (Join-Path $Root "backend") `
    -WindowStyle Hidden

& $Python -m uvicorn whatsapp_service.app:app --host 127.0.0.1 --port 8000
