# test_connection.ps1
$ErrorActionPreference = "Stop"
$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot

# Load .env
$envFile = Join-Path $PROJECT_ROOT ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
    }
}

$DEPLOY_HOST = $env:DEPLOY_HOST
$DEPLOY_USER = $env:DEPLOY_USER
$DEPLOY_PASS = $env:DEPLOY_PASS
$DEPLOY_PROTOCOL = $env:DEPLOY_PROTOCOL
$WINSCP_PATH = $env:WINSCP_PATH
$DEPLOY_KEY_PATH = $env:DEPLOY_KEY_PATH
$DEPLOY_PORT = $env:DEPLOY_PORT

Write-Host "--- Test Polaczenia WinSCP ---"
Write-Host "Protocol: $DEPLOY_PROTOCOL"
Write-Host "Host:     $DEPLOY_HOST"
Write-Host "Port:     $DEPLOY_PORT"
Write-Host "User:     $DEPLOY_USER"
Write-Host "Key:      $DEPLOY_KEY_PATH"
Write-Host "WinSCP:   $WINSCP_PATH"

$tempScript = Join-Path $env:TEMP "winscp_test.txt"
"option batch on" | Out-File $tempScript -Encoding UTF8
"option confirm off" | Out-File $tempScript -Append -Encoding UTF8

$userEncoded = [Uri]::EscapeDataString($DEPLOY_USER)

$hostString = $DEPLOY_HOST
if ($DEPLOY_PORT) {
    $hostString = "${DEPLOY_HOST}:${DEPLOY_PORT}"
}

$switchString = "-hostkey=*"
if ($DEPLOY_KEY_PATH) {
    $switchString += " -privatekey=""$DEPLOY_KEY_PATH"""
    $openCmd = "open {0}://{1}@{2}/ {3}" -f $DEPLOY_PROTOCOL, $userEncoded, $hostString, $switchString
    Write-Host ("Command:  open {0}://{1}@{2}/ {3}" -f $DEPLOY_PROTOCOL, $userEncoded, $hostString, $switchString)
}
else {
    $passEncoded = [Uri]::EscapeDataString($DEPLOY_PASS)
    $openCmd = "open {0}://{1}:{2}@{3}/ {4}" -f $DEPLOY_PROTOCOL, $userEncoded, $passEncoded, $hostString, $switchString
    Write-Host ("Command:  open {0}://{1}:***@{2}/ {3}" -f $DEPLOY_PROTOCOL, $userEncoded, $hostString, $switchString)
    $mkdirCmd = "mkdir ""/public_html/releases/"""
    $mkdirCmd | Out-File $tempScript -Append -Encoding UTF8
}
$openCmd | Out-File $tempScript -Append -Encoding UTF8
"ls" | Out-File $tempScript -Append -Encoding UTF8
"exit" | Out-File $tempScript -Append -Encoding UTF8

try {
    & $WINSCP_PATH /script="$tempScript" /log="$PSScriptRoot\..\releases\winscp_test_log.xml" /loglevel=0
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUKCES! Polaczenie udane." -ForegroundColor Green
    }
    else {
        Write-Host "BLAD! Kod wyjscia: $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Sprawdz logi: captures/winscp_test_log.xml"
    }
}
finally {
    if (Test-Path $tempScript) { Remove-Item $tempScript }
}
Write-Host "Nacisnij Enter..."
$null = Read-Host
