# cloc Cheatsheet (Ściąga)

Narzędzie `cloc` (Count Lines of Code) pozwala na precyzyjne zliczanie linii kodu, komentarzy i pustych linii w projekcie.

## Podstawowe użycie (wewnątrz projektu)

```powershell
# Zliczanie wszystkich plików w bieżącym katalogu
cloc .
```

```powershell
# Zliczanie z wykluczeniem typowych folderów generowanych/zależności
cloc . --exclude-dir=node_modules,dist,.git,.venv
```

## Filtrowanie i formatowanie

```powershell
# Zliczanie tylko konkretnych języków (np. Python i JavaScript)
cloc . --include-lang=Python,JavaScript
```

```powershell
# Wyświetlenie statystyk tylko dla konkretnych plików (użycie regexp)
# Pamiętaj o cudzysłowach w PowerShell!
cloc . --match-f='\.dart$'
```

```powershell
# Eksport wyniku do pliku JSON
cloc . --json --out=report.json
```

## Analiza zmian (Git)

```powershell
# Porównanie bieżącego stanu z poprzednim commitem
cloc . --diff HEAD HEAD~1
```

## Pełna analiza projektu

```powershell
# Ilość commitów + suma linii kodu (z wykluczeniem śmieci i folderów build)
echo "=== COMMITS ===" && git rev-list --count HEAD && echo "=== LINIE KODU ===" && cloc . --exclude-dir=node_modules,dist,build,.dart_tool,.git,.idea,.vscode
```

## Użycie w innych projektach (globalnie)

Dzięki dodaniu folderu do zmiennej środowiskowej **PATH**, nie musisz już kopiować pliku `cloc.exe` ani podawać jego pełnej ścieżki.

W dowolnym folderze na swoim komputerze (np. w innym repozytorium) po prostu otwórz terminal i wpisz:

```powershell
cloc .
```

## Dodawanie do PATH (Zalecane)

Aby móc używać komendy `cloc` w dowolnym miejscu bez wpisywania ścieżki:

1. Przenieś `cloc.exe` do folderu: `C:\Users\rzemp\GitHub\` (jeśli jeszcze go tam nie ma).
2. Otwórz menu **Start** i wpisz **"Zmienne środowiskowe"**.
3. Wybierz **"Edytuj zmienne środowiskowe systemu"**.
4. Kliknij przycisk **Zmienne środowiskowe...** na dole.
5. W sekcji "Zmienne użytkownika" znajdź zmienną **Path** i kliknij **Edytuj**.
6. Kliknij **Nowy** i wklej ścieżkę do folderu: `C:\Users\rzemp\GitHub\`
7. Zatwierdź wszystko przyciskiem OK.
8. **Ważne:** Zrestartuj terminal (PowerShell/CMD), aby zmiany weszły w życie.
