# deploy_apk.ps1
# Skrypt do budowania i deploymentu APK (Build + Copy + Versioning + WinSCP Upload)
# Uzycie: .\scripts\deploy_apk.ps1 [-SkipBuild] [-SkipUpload]

param(
    [switch]$SkipBuild,
    [switch]$SkipUpload = $true
)

$ErrorActionPreference = "Stop"

# === Konfiguracja ===

$PROJECT_ROOT = Split-Path -Parent $PSScriptRoot
$MOBILE_DIR = Join-Path $PROJECT_ROOT "apps\mobile"
$RELEASES_DIR = Join-Path $PROJECT_ROOT "releases"

function Print-Info($msg) { Write-Host $msg -ForegroundColor Cyan }
function Print-Success($msg) { Write-Host $msg -ForegroundColor Green }
function Print-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }
function Print-Error($msg) { Write-Host $msg -ForegroundColor Red }

function Load-Env {
    $envFile = Join-Path $PROJECT_ROOT ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match "^\s*([^#=]+)=(.*)$") {
                $key = $matches[1].Trim()
                $val = $matches[2].Trim()
                if (-not (Test-Path "env:$key")) {
                    [Environment]::SetEnvironmentVariable($key, $val, "Process")
                }
            }
        }
        Print-Success "Zaladowano konfiguracje z .env"
    }
}

function Get-WinSCP {
    if ($env:WINSCP_PATH -and (Test-Path $env:WINSCP_PATH)) { return $env:WINSCP_PATH }
    if (Get-Command "winscp.com" -ErrorAction SilentlyContinue) { return "winscp.com" }
    
    $paths = @(
        "$env:ProgramFiles(x86)\WinSCP\WinSCP.com",
        "$env:ProgramFiles\WinSCP\WinSCP.com",
        "$env:LocalAppData\Programs\WinSCP\WinSCP.com"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

# === Start Skryptu ===

Print-Info "=== Deploy APK Script v11 (ASCII) ==="
Load-Env

$DEPLOY_HOST = if ($env:DEPLOY_HOST) { $env:DEPLOY_HOST } else { "" }
$DEPLOY_USER = if ($env:DEPLOY_USER) { $env:DEPLOY_USER } else { "" }
$DEPLOY_PASS = if ($env:DEPLOY_PASS) { $env:DEPLOY_PASS } else { "" }
$DEPLOY_PROTOCOL = if ($env:DEPLOY_PROTOCOL) { $env:DEPLOY_PROTOCOL } else { "sftp" }
$DEPLOY_REMOTE_PATH = if ($env:DEPLOY_REMOTE_PATH) { $env:DEPLOY_REMOTE_PATH } else { "/public_html/releases/" }
$DEPLOY_PUBLIC_URL = if ($env:DEPLOY_PUBLIC_URL) { $env:DEPLOY_PUBLIC_URL } else { "http://michalrapala.app/releases" }

$VERSION = Get-Date -Format "yyyyMMdd_HHmm"
# Format YYMMDDHHmm (np. 2512310800) przekracza limit Androida (2.1 mld).
# Stosujemy offset od roku 2024: (Rok-2024)MMDDHHmm.
# 2025 -> 1MMDDHHmm (np. 112310805). Bezpieczne do 2045 roku.
$Date = Get-Date
$YearOffset = $Date.Year - 2024
$BUILD_NUMBER = "{0}{1:MMddHHmm}" -f $YearOffset, $Date
$APK_NAME = "Pudelko_na_leki_$VERSION.apk"

Print-Info "Wersja pliku: $VERSION"
Print-Info "Build Number: $BUILD_NUMBER (Offset Date)"
Print-Info "APK: $APK_NAME"
Write-Host ""

# 1. Budowanie
if (-not $SkipBuild) {
    Print-Warn "[1/4] Budowanie APK..."
    Push-Location $MOBILE_DIR
    
    try {
        flutter build apk --release --build-number=$BUILD_NUMBER
        
        if ($LASTEXITCODE -ne 0) {
            Pop-Location
            Print-Error "Blad budowania Flutter"
            Write-Host "Nacisnij Enter aby zamknac..."
            $null = Read-Host
            exit 1
        }
    }
    catch {
        Pop-Location
        Print-Error "BLAD KRYTYCZNY: $_"
        Write-Host "Nacisnij Enter aby zamknac..."
        $null = Read-Host
        exit 1
    }
    
    Pop-Location
    Print-Success "[1/4] Zbudowano pomyslnie!"
}
else {
    Print-Warn "[1/4] Pominieto budowanie (--SkipBuild)"
}

# 2. Kopiowanie
Print-Warn "[2/4] Kopiowanie do releases..."
$SOURCE_APK = Join-Path $MOBILE_DIR "build\app\outputs\flutter-apk\app-release.apk"
$DEST_APK = Join-Path $RELEASES_DIR $APK_NAME

if (-not (Test-Path $RELEASES_DIR)) { New-Item -ItemType Directory -Path $RELEASES_DIR | Out-Null }
Copy-Item $SOURCE_APK $DEST_APK -Force
Print-Success "[2/4] APK skopiowane: $APK_NAME"

# 3. Generowanie version.json
Print-Warn "[3/4] Generowanie version.json..."
$VERSION_JSON = @{
    version     = $VERSION
    buildNumber = [int]$BUILD_NUMBER
    apkUrl      = "$DEPLOY_PUBLIC_URL/$APK_NAME"
    releaseDate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 2

$VERSION_JSON_PATH = Join-Path $RELEASES_DIR "version.json"
Set-Content -Path $VERSION_JSON_PATH -Value $VERSION_JSON -Encoding UTF8
Print-Success "[3/4] version.json zaktualizowany!"

# 4. Upload
if (-not $SkipUpload) {
    Print-Warn "[4/4] Upload na serwer..."
    
    if (-not $DEPLOY_HOST -or -not $DEPLOY_USER -or -not $DEPLOY_PASS) {
        Print-Error "BLAD: Brak konfiguracji deploymentu w .env!"
        Print-Info "Ustaw DEPLOY_HOST, DEPLOY_USER, DEPLOY_PASS w pliku .env"
        Write-Host "Nacisnij Enter aby zamknac..."
        $null = Read-Host
        exit 1
    }

    $winScp = Get-WinSCP
    if (-not $winScp) {
        Print-Error "BLAD: Nie znaleziono WinSCP!"
        Print-Info "Zainstaluj WinSCP lub dodaj sciezke do WINSCP_PATH w .env"
        Write-Host "Nacisnij Enter aby zamknac..."
        $null = Read-Host
        exit 1
    }

    Print-Info "Uzywam WinSCP: $winScp"
    Print-Info ("Laczenie z {0}://{1}@{2}..." -f $DEPLOY_PROTOCOL, $DEPLOY_USER, $DEPLOY_HOST)
    
    $tempScript = Join-Path $env:TEMP "winscp_deploy_$VERSION.txt"
    
    # Generowanie skryptu WinSCP linia po linii (ASCII)
    "option batch on" | Out-File $tempScript -Encoding UTF8
    "option confirm off" | Out-File $tempScript -Append -Encoding UTF8
    
    $openCmd = "open {0}://{1}:{2}@{3}/ -hostkey=*" -f $DEPLOY_PROTOCOL, $DEPLOY_USER, $DEPLOY_PASS, $DEPLOY_HOST
    $openCmd | Out-File $tempScript -Append -Encoding UTF8
    
    "put ""$DEST_APK"" ""$DEPLOY_REMOTE_PATH""" | Out-File $tempScript -Append -Encoding UTF8
    "put ""$VERSION_JSON_PATH"" ""$DEPLOY_REMOTE_PATH""" | Out-File $tempScript -Append -Encoding UTF8
    "exit" | Out-File $tempScript -Append -Encoding UTF8

    try {
        & $winScp /script="$tempScript" /log="$RELEASES_DIR\winscp_log.xml" /loglevel=0
        if ($LASTEXITCODE -eq 0) {
            Print-Success "[4/4] Upload zakonczony sukcesem!"
        }
        else {
            Print-Error "[4/4] Blad uploadu (ExitCode: $LASTEXITCODE). Sprawdz logi w releases/winscp_log.xml"
            Write-Host "Nacisnij Enter aby zamknac..."
            $null = Read-Host
            exit $LASTEXITCODE
        }
    }
    finally {
        if (Test-Path $tempScript) { Remove-Item $tempScript }
    }

}
else {
    Print-Warn "[4/4] Pominieto upload (--SkipUpload)"
}

Print-Success "=== Deployment Zakonczony (Wersja $VERSION) ==="

Write-Host ""
Write-Host "Nacisnij Enter aby zamknac..."
$null = Read-Host
exit 0
