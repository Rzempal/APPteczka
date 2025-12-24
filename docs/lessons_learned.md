# Lessons Learned

Dokument zawiera wnioski z popełnionych błędów, aby nie powtarzać ich w przyszłości.

---

## 1. Efekt wciśnięcia w neumorfizmie

**Data:** 2025-12-24  
**Kontekst:** Karty leków - przycisk chevron w stanie zwiniętym

### ❌ Błąd

Użyłem klasy `neu-concave` dla efektu "wciśnięcia" przycisku, co dało ciemny, wklęsły wygląd - nieprawidłowy w kontekście UI.

### ✅ Poprawne rozwiązanie

Dla interaktywnych elementów (hamburger menu, tagi, przyciski toggle) używaj:

```css
neu-tag active
```

### Różnica

| Klasa           | Wygląd                        | Zastosowanie                   |
|-----------------|-------------------------------|--------------------------------|
| `neu-concave`   | Ciemny, wklęsły (jak input)   | Pola tekstowe, obszary wgłębione |
| `neu-tag.active`| Zielony akcent, wciśnięty     | Aktywne przyciski, toggle, tagi  |

### Lokalizacja w CSS

`globals.css` linie 277-283:

```css
.neu-tag.active {
  background: linear-gradient(145deg, var(--color-accent-light), var(--color-accent));
  color: white;
  box-shadow:
    inset 2px 2px 4px rgba(0, 0, 0, 0.1),
    inset -2px -2px 4px rgba(255, 255, 255, 0.1);
}
```

---

> 📅 **Ostatnia aktualizacja:** 2025-12-24
