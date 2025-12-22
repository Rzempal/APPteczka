# Apteczka AI – Prompty i Schemy

## Zawartość
- Prompty importu: Markdown / JSON / YAML
- Schemy walidacji (JSON Schema + YAML)
- Schemy statusu niepewności

## Zalecany przepływ
1. System Prompt → ustaw reguły
2. User Prompt → analiza zdjęcia
3. Walidacja wyniku:
   - sukces → schema importu
   - niepewność → schema statusu

## Wskazówki
- Używaj schemy z enum tagów, aby zachować spójność filtrów.
- Rozszerzaj wersjonowanie przez `schema_version`.
