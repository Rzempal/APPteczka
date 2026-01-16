# merge_pr.ps1
# Automatyczne tworzenie PR i merge do main z poprawna numeracja commitow
# Wymaga: GitHub CLI (gh) - instalacja: winget install GitHub.cli

param(
    [switch]$DryRun = $false  # Tryb testowy - pokazuje co zrobi, ale nie wykonuje
)

Write-Host "=== Merge PR Script ===" -ForegroundColor Cyan

# 1. Sprawdz czy gh jest zainstalowane
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "BLAD: GitHub CLI (gh) nie jest zainstalowane!" -ForegroundColor Red
    Write-Host "Instalacja: winget install GitHub.cli" -ForegroundColor Yellow
    Write-Host "Potem: gh auth login" -ForegroundColor Yellow
    exit 1
}

# 2. Sprawdz czy jestesmy zalogowani
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: Nie jestes zalogowany do GitHub CLI!" -ForegroundColor Red
    Write-Host "Wykonaj: gh auth login" -ForegroundColor Yellow
    exit 1
}

# 3. Pobierz aktualny branch
$currentBranch = git branch --show-current
if ($currentBranch -eq "main") {
    Write-Host "BLAD: Jestes na branchu 'main'. Przejdz na feature branch!" -ForegroundColor Red
    exit 1
}
Write-Host "Branch: $currentBranch" -ForegroundColor Green

# 4. Sprawdz czy sa niezacommitowane zmiany
$status = git status --porcelain
if ($status) {
    Write-Host "BLAD: Masz niezacommitowane zmiany!" -ForegroundColor Red
    Write-Host "Wykonaj najpierw: /end workflow" -ForegroundColor Yellow
    exit 1
}

# 5. Fetch i pobierz ostatni numer z main
git fetch origin main --quiet
$lastCommit = git log origin/main --oneline -1
Write-Host "Ostatni commit na main: $lastCommit" -ForegroundColor Gray

# Wyciagnij numer #XXX z ostatniego commita
if ($lastCommit -match '#(\d+)') {
    $lastNum = [int]$matches[1]
} else {
    # Fallback - policz commity
    $lastNum = [int](git rev-list --count origin/main)
}
$nextNum = $lastNum + 1
Write-Host "Nowy numer: #$nextNum" -ForegroundColor Green

# 6. Pobierz opis z ostatniego commita na tym branchu (bez numeru)
$commitMsg = git log -1 --format=%s
$description = $commitMsg -replace '^#\d+\s*', ''
Write-Host "Opis: $description" -ForegroundColor Green

# 7. Utworz tytul
$title = "#$nextNum $description"
Write-Host ""
Write-Host "=== Tytul PR i Merge Commit ===" -ForegroundColor Cyan
Write-Host $title -ForegroundColor Yellow
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] Komendy do wykonania:" -ForegroundColor Magenta
    Write-Host "gh pr create --base main --head $currentBranch --title `"$title`" --body `"`"" -ForegroundColor Gray
    Write-Host "gh pr merge --merge --subject `"$title`" --delete-branch" -ForegroundColor Gray
    exit 0
}

# 8. Potwierdz
$confirm = Read-Host "Kontynuowac? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Anulowano." -ForegroundColor Yellow
    exit 0
}

# 9. Utworz PR
Write-Host "Tworzenie PR..." -ForegroundColor Cyan
gh pr create --base main --head $currentBranch --title $title --body ""
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: Nie udalo sie utworzyc PR!" -ForegroundColor Red
    exit 1
}

# 10. Merge PR
Write-Host "Mergowanie PR..." -ForegroundColor Cyan
gh pr merge --merge --subject $title --delete-branch
if ($LASTEXITCODE -ne 0) {
    Write-Host "BLAD: Nie udalo sie zmergowac PR!" -ForegroundColor Red
    Write-Host "Moze PR wymaga review? Sprawdz na GitHub." -ForegroundColor Yellow
    exit 1
}

# 11. Wroc do main i pobierz zmiany
Write-Host "Synchronizacja z main..." -ForegroundColor Cyan
git checkout main
git pull origin main

Write-Host ""
Write-Host "=== SUKCES ===" -ForegroundColor Green
Write-Host "PR zmergowany: $title" -ForegroundColor Green
Write-Host "Branch $currentBranch usuniety" -ForegroundColor Green
