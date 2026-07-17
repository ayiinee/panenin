$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$EnvPath = Join-Path $Root ".env"

if (-not (Test-Path $EnvPath)) {
    throw "File .env tidak ditemukan di $Root"
}

$Values = @{}
Get-Content $EnvPath | ForEach-Object {
    if ($_ -match "^\s*([A-Za-z_][A-Za-z0-9_]*)=(.*)$") {
        $Values[$matches[1]] = $matches[2].Trim().Trim('"').Trim("'")
    }
}

foreach ($Required in @("FONNTE_TOKEN", "FONNTE_WEBHOOK_SECRET", "PUBLIC_WEBHOOK_URL")) {
    if (-not $Values[$Required]) {
        throw "$Required belum diisi di .env"
    }
}

$BaseWebhook = $Values["PUBLIC_WEBHOOK_URL"] `
    -replace "\?.*$", "" `
    -replace "/[a-fA-F0-9]{64}$", ""

if (-not $BaseWebhook.EndsWith("/webhook/fonnte")) {
    throw "PUBLIC_WEBHOOK_URL harus berakhir dengan /webhook/fonnte"
}

$Sha256 = [System.Security.Cryptography.SHA256]::Create()
try {
    $SecretBytes = [System.Text.Encoding]::UTF8.GetBytes(
        $Values["FONNTE_WEBHOOK_SECRET"]
    )
    $PathToken = (
        [System.BitConverter]::ToString($Sha256.ComputeHash($SecretBytes))
    ).Replace("-", "").ToLowerInvariant()
}
finally {
    $Sha256.Dispose()
}

$Headers = @{ Authorization = $Values["FONNTE_TOKEN"] }
$Profile = Invoke-RestMethod `
    -Uri "https://api.fonnte.com/device" `
    -Method Post `
    -Headers $Headers `
    -TimeoutSec 30

if ($Profile.status -ne $true -or -not $Profile.device -or -not $Profile.name) {
    throw "Profil device Fonnte tidak valid atau token tidak cocok."
}

$Result = Invoke-RestMethod `
    -Uri "https://api.fonnte.com/update-device" `
    -Method Post `
    -Headers $Headers `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        name = [string]$Profile.name
        device = [string]$Profile.device
        webhook = "$BaseWebhook/$PathToken"
        autoread = "true"
        personal = "true"
        group = "false"
        quick = "false"
        resend = "false"
    } `
    -TimeoutSec 30

if ($Result.status -ne $true) {
    $Reason = if ($Result.reason) { $Result.reason } else { "unknown error" }
    throw "Gagal memperbarui Fonnte: $Reason"
}

Write-Host "Webhook Fonnte berhasil diperbarui."
Write-Host "Endpoint publik : $BaseWebhook/[secure-token]"
Write-Host "Autoread        : ON"
Write-Host "Personal chat   : ON"
Write-Host "Self chat       : OFF"
Write-Host "Group chat      : OFF"
