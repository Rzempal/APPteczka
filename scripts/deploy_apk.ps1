# deploy_apk.ps1
# Skrypt do budowania i deploymentu APK (Build + Copy + Versioning + WinSCP Upload)
# Uzycie: .\scripts\deploy_apk.ps1 [-SkipBuild] [-SkipUpload] [-Channel internal|production]

param(
    [switch]$SkipBuild,
    [bool]$SkipUpload = $true,
    [string]$Channel = "production",
    [switch]$CreateTag
)

$SCRIPT_VERSION = "v12.10"
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
function Update-DeployLog {
    param(
        [string]$Channel,
        [string]$VersionName,
        [int64]$VersionCode,
        [string]$ApkName,
        [array]$Commits,
        [string]$Status,
        [string]$Duration
    )
    
    $LOG_PATH = "C:\Users\rzemp\Documents\obsidian\ADMIN\-LOG\log-karton.mdd"
    $MAX_ENTRIES = 10
    $SEPARATOR = "`n---`n"
    
    # Build new entry
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $statusText = switch ($Status) {
        "ok" { "Upload OK" }
        "skipped" { "Skipped" }
        default { "Upload OK" }
    }
    
    $durationLine = ""
    if ($Duration) { 
        $durationLine = "- **Czas deploymentu:** $Duration" 
    }
    
    $commitLines = ""
    foreach ($c in $Commits) {
        $commitLines += "- ``$c```n"
    }

    $newEntry = @"
``````
## $timestamp | $Channel | v$VersionName
- **APK:** ``$ApkName``
- **Status:** $statusText
$durationLine
**Ostatnie zmiany:**
$commitLines``````
"@

    # Read existing entries
    $existingEntries = @()
    if (Test-Path $LOG_PATH) {
        $content = Get-Content $LOG_PATH -Raw -ErrorAction SilentlyContinue
        if ($content) {
            # Remove header if exists
            $content = $content -replace "^# .*Deploy Log.*\r?\n\r?\n", ""
            # Split by separator and filter empty
            $existingEntries = $content -split "---" | Where-Object { $_.Trim() -ne "" }
        }
    }
    
    # Keep only last (MAX_ENTRIES - 1) entries + new one = MAX_ENTRIES
    if ($existingEntries.Count -ge $MAX_ENTRIES) {
        $existingEntries = $existingEntries[0..($MAX_ENTRIES - 2)]
    }
    
    # Combine: new entry first, then existing
    $allEntries = @($newEntry) + $existingEntries
    
    # Write file
    $header = "# Deploy Log`n`n"
    $finalContent = $header + ($allEntries -join $SEPARATOR)
    
    # Ensure directory exists
    $logDir = Split-Path $LOG_PATH -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    Set-Content -Path $LOG_PATH -Value $finalContent -Encoding UTF8
    Print-Success "Log zapisany: $LOG_PATH"
    return $newEntry
}

function Create-GitTag {
    param(
        [string]$TagName,
        [string]$Channel
    )

    if ($Channel -ne "production") { return }

    try {
        Push-Location $PROJECT_ROOT
        
        # Pobierz ostatni tag
        $lastTag = git describe --tags --abbrev=0 2>$null
        
        $logRange = "HEAD"
        if ($lastTag) {
            $logRange = "$($lastTag)..HEAD"
            Print-Info "Generowanie notatek od ostatniego tagu: $lastTag"
        }
        else {
            Print-Info "Nie znaleziono poprzednich tagów. Pobieranie ostatnich 10 commitów."
            $logRange = "-n 10 HEAD"
        }

        # Pobierz listę zmian
        $oldOutputEncoding = [Console]::OutputEncoding
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $changeLog = git -c "i18n.logOutputEncoding=utf-8" log $logRange --pretty=format:"* %s (%h)"
        [Console]::OutputEncoding = $oldOutputEncoding

        if (-not $changeLog) {
            Print-Warn "Brak nowych commitów od ostatniego tagu. Pomijam tworzenie tagu."
            return
        }

        $tagMessage = "Release $TagName`n`nChanges:`n$changeLog"
        
        Print-Warn "Tworzenie tagu Git: $TagName"
        git tag -a $TagName -m "$tagMessage"
        
        Print-Warn "Wysyłanie tagów na serwer..."
        git push origin $TagName
        
        Print-Success "Tag $TagName utworzony i wysłany pomyślnie!"
    }
    catch {
        Print-Error "Błąd podczas tworzenia tagu Git: $_"
    }
    finally {
        Pop-Location
    }
}


# === Start Skryptu ===

$startTime = [System.Diagnostics.Stopwatch]::StartNew()

# Background Timer (Runspace) to update window title
$rs = [runspacefactory]::CreateRunspace()
$rs.Open()
$timerPs = [powershell]::Create().AddScript({
        param($startTime)
        while ($true) {
            $elapsed = $startTime.Elapsed
            $timeStr = "$($elapsed.Minutes.ToString('00')):$($elapsed.Seconds.ToString('00'))"
            [Console]::Title = "APPteczka Deploy | Czas: $timeStr"
            [System.Threading.Thread]::Sleep(1000)
        }
    }).AddArgument($startTime)
$timerPs.Runspace = $rs
$null = $timerPs.BeginInvoke()

Print-Info "=== Deploy APK Script $SCRIPT_VERSION ==="
Load-Env

$DEPLOY_HOST = if ($env:DEPLOY_HOST) { $env:DEPLOY_HOST } else { "" }
$DEPLOY_USER = if ($env:DEPLOY_USER) { $env:DEPLOY_USER } else { "" }
$DEPLOY_PASS = if ($env:DEPLOY_PASS) { $env:DEPLOY_PASS } else { "" }
$DEPLOY_PROTOCOL = if ($env:DEPLOY_PROTOCOL) { $env:DEPLOY_PROTOCOL } else { "sftp" }
$DEPLOY_REMOTE_PATH = if ($env:DEPLOY_REMOTE_PATH) { $env:DEPLOY_REMOTE_PATH } else { "/public_html/releases/" }
$DEPLOY_PUBLIC_URL = if ($env:DEPLOY_PUBLIC_URL) { $env:DEPLOY_PUBLIC_URL } else { "https://michalrapala.app/releases" }
$DEPLOY_KEY_PATH = if ($env:DEPLOY_KEY_PATH) { $env:DEPLOY_KEY_PATH } else { "" }
$DEPLOY_PORT = if ($env:DEPLOY_PORT) { $env:DEPLOY_PORT } else { "" }

# ========================================
# Semantic Versioning: Major.Minor.Timestamp
# ========================================
# versionName: Major.Minor.Timestamp (user-visible)
# versionCode: Timestamp only (yyDDDHHmm) - for Android
#
# Timestamp format: yy + DDD + HH + mm
#   yy  = 2-digit year (25 for 2025)
#   DDD = day of year (001-366)
#   HH  = hour (00-23)
#   mm  = minute (00-59)
#
# Example: 2025-12-31 14:52 -> 253651452
# ========================================

# Read Major.Minor from pubspec.yaml
$PUBSPEC_PATH = Join-Path $MOBILE_DIR "pubspec.yaml"
$PubspecContent = Get-Content $PUBSPEC_PATH -Raw
if ($PubspecContent -match 'version:\s*(\d+)\.(\d+)\.') {
    $MAJOR = $Matches[1]
    $MINOR = $Matches[2]
}
else {
    $MAJOR = "0"
    $MINOR = "1"
    Print-Warn "Nie znaleziono wersji w pubspec.yaml, uzywam domyslnej: $MAJOR.$MINOR"
}

# Generate timestamp: yyDDDHHmm
$Date = Get-Date
$Year2Digit = $Date.ToString("yy")
$DayOfYear = $Date.DayOfYear.ToString("000")
$HourMinute = $Date.ToString("HHmm")
$TIMESTAMP = "$Year2Digit$DayOfYear$HourMinute"

# Full version strings
$VERSION_NAME = "$MAJOR.$MINOR.$TIMESTAMP"
$VERSION_CODE = [int64]$TIMESTAMP

# Channel-specific naming
if ($Channel -eq "internal") {
    $APK_NAME = "karton-dev_$VERSION_NAME.apk"
    $VERSION_JSON_NAME = "version-internal.json"
}
else {
    $APK_NAME = "karton-z-lekami_$VERSION_NAME.apk"
    $VERSION_JSON_NAME = "version.json"
}

# Get last 4 commit messages
$LAST_COMMITS = @()
try {
    Push-Location $PROJECT_ROOT
    # Force UTF-8 for git output
    $oldOutputEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $LAST_COMMITS = git -c "i18n.logOutputEncoding=utf-8" log -4 --pretty=format:"%h %s" 2>$null
    [Console]::OutputEncoding = $oldOutputEncoding
    Pop-Location
}
catch {
    $LAST_COMMITS = @("(nie udalo sie pobrac)")
}

Print-Info "Kanal: $Channel"
Print-Info "Wersja: v$VERSION_NAME"
Print-Info "versionCode: $VERSION_CODE (yyDDDHHmm)"
Print-Info "APK: $APK_NAME"
# Print-Info "Ostatnie zmiany:"
# if ($LAST_COMMITS -is [string]) { $LAST_COMMITS = @($LAST_COMMITS) }
# foreach ($commit in $LAST_COMMITS) {
#     Print-Info "  $commit"
# }
Write-Host ""

# 1. Budowanie
if (-not $SkipBuild) {
    Print-Warn "[1/4] Budowanie APK..."
    Push-Location $MOBILE_DIR
    
    try {
        # Filtruj komunikaty tree-shaking (informacyjne, nie bledy)
        cmd /c "flutter build apk --release --flavor $Channel --build-name=$VERSION_NAME --build-number=$VERSION_CODE --dart-define=CHANNEL=$Channel 2>&1" | Where-Object { $_ -notmatch "tree-shaken|Tree-shaking|source value 8 is obsolete" }
        
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
$SOURCE_APK = Join-Path $MOBILE_DIR "build\app\outputs\flutter-apk\app-$Channel-release.apk"
$DEST_APK = Join-Path $RELEASES_DIR $APK_NAME

if (-not (Test-Path $RELEASES_DIR)) { New-Item -ItemType Directory -Path $RELEASES_DIR | Out-Null }
Copy-Item $SOURCE_APK $DEST_APK -Force
Print-Success "[2/4] APK skopiowane: $APK_NAME"

# 3. Generowanie version.json
Print-Warn "[3/4] Generowanie $VERSION_JSON_NAME..."

# Determine public URL for APK
if ($Channel -eq "internal") {
    $APK_PUBLIC_URL = "$DEPLOY_PUBLIC_URL/internal/$APK_NAME"
}
else {
    $APK_PUBLIC_URL = "$DEPLOY_PUBLIC_URL/$APK_NAME"
}

$VERSION_JSON = @{
    version     = $VERSION_NAME
    versionCode = $VERSION_CODE
    apkUrl      = $APK_PUBLIC_URL
    releaseDate = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 2

$VERSION_JSON_PATH = Join-Path $RELEASES_DIR $VERSION_JSON_NAME
Set-Content -Path $VERSION_JSON_PATH -Value $VERSION_JSON -Encoding UTF8
Print-Success "[3/4] $VERSION_JSON_NAME zaktualizowany!"

# 4. Upload
if (-not $SkipUpload) {
    Print-Warn "[4/4] Upload na serwer..."
    
    if (-not $DEPLOY_HOST -or -not $DEPLOY_USER) {
        Print-Error "BLAD: Brak Hosta lub Uzytkownika w .env!"
        exit 1
    }
    
    if (-not $DEPLOY_PASS -and -not $DEPLOY_KEY_PATH) {
        Print-Error "BLAD: Brak hasla (DEPLOY_PASS) lub klucza (DEPLOY_KEY_PATH) w .env!"
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
    
    $tempScript = Join-Path $env:TEMP "winscp_deploy_$($VERSION_NAME).txt"
    
    # Generowanie skryptu WinSCP linia po linii (ASCII)
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
        # Jeśli mamy klucz, pomijamy hasło w URL (chyba że jest wymagane do klucza - passphrase)
        # Tutaj zakładamy klucz bez hasła lub puste hasło w URL
        $openCmd = "open {0}://{1}@{2}/ {3}" -f $DEPLOY_PROTOCOL, $userEncoded, $hostString, $switchString
    }
    else {
        $passEncoded = [Uri]::EscapeDataString($DEPLOY_PASS)
        $openCmd = "open {0}://{1}:{2}@{3}/ {4}" -f $DEPLOY_PROTOCOL, $userEncoded, $passEncoded, $hostString, $switchString
    }
    $openCmd | Out-File $tempScript -Append -Encoding UTF8
    
    # Utworz katalog jesli nie istnieje (ignorujac bledy)
    # Adjust remote path for internal channel
    $UPLOAD_REMOTE_PATH = $DEPLOY_REMOTE_PATH
    if ($Channel -eq "internal") {
        $UPLOAD_REMOTE_PATH = $DEPLOY_REMOTE_PATH + "internal/"
    }
    
    "option batch continue" | Out-File $tempScript -Append -Encoding UTF8
    "mkdir ""$UPLOAD_REMOTE_PATH""" | Out-File $tempScript -Append -Encoding UTF8
    "option batch on" | Out-File $tempScript -Append -Encoding UTF8
    
    "put ""$DEST_APK"" ""$UPLOAD_REMOTE_PATH""" | Out-File $tempScript -Append -Encoding UTF8
    "put ""$VERSION_JSON_PATH"" ""$UPLOAD_REMOTE_PATH""" | Out-File $tempScript -Append -Encoding UTF8
    "exit" | Out-File $tempScript -Append -Encoding UTF8

    try {
        & $winScp /script="$tempScript" /log="$RELEASES_DIR\winscp_log.xml" /loglevel=0 /noninteractive
        if ($LASTEXITCODE -eq 0) {
            Print-Success "[4/4] Upload zakonczony sukcesem!"
            $DEPLOY_STATUS = "ok"
            
            # 5. Opcjonalne tagowanie (Tylko po sukcesie uploadu)
            if ($CreateTag) {
                Create-GitTag -TagName "v$VERSION_NAME" -Channel $Channel
            }
        }
        else {
            Print-Error "[4/4] Blad uploadu (ExitCode: $LASTEXITCODE). Sprawdz logi w releases/winscp_log.xml"
            $DEPLOY_STATUS = "error"
            
            # Stop timer and calculate final duration
            $startTime.Stop()
            $finalElapsed = $startTime.Elapsed
            $finalDurationStr = "$($finalElapsed.Minutes.ToString('00')):$($finalElapsed.Seconds.ToString('00'))"
            if ($timerPs) { $timerPs.Dispose(); $rs.Close(); $rs.Dispose() }
            
            $summary = Update-DeployLog -Channel $Channel -VersionName $VERSION_NAME -VersionCode $VERSION_CODE -ApkName $APK_NAME -Commits $LAST_COMMITS -Status $DEPLOY_STATUS -Duration $finalDurationStr
            Write-Host "`n$summary" -ForegroundColor Cyan
            Write-Host "---`n"

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
    $DEPLOY_STATUS = "skipped"
}

# Stop timer and calculate final duration
$startTime.Stop()
$finalElapsed = $startTime.Elapsed
$finalDurationStr = "$($finalElapsed.Minutes.ToString('00')):$($finalElapsed.Seconds.ToString('00'))"
if ($timerPs) { $timerPs.Dispose(); $rs.Close(); $rs.Dispose() }

Print-Success "=== Deployment Zakonczony (Wersja $VERSION_NAME) ==="
Print-Success "Calkowity czas: $finalDurationStr"

# Update deploy log
$summary = Update-DeployLog -Channel $Channel -VersionName $VERSION_NAME -VersionCode $VERSION_CODE -ApkName $APK_NAME -Commits $LAST_COMMITS -Status $DEPLOY_STATUS -Duration $finalDurationStr
Write-Host "$summary" -ForegroundColor Green
Write-Host "---"
exit 0
