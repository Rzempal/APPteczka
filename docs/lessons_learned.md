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

## 2. Ucinanie cieni neumorficznych przez brak paddingu

**Data:** 2025-12-24  
**Kontekst:** Karty leków - przyciski przy prawej krawędzi kontenera

### ❌ Błąd

Przyciski z `box-shadow` neumorficznym (`.neu-tag`) umieszczone przy prawej krawędzi kontenera mają obcięty cień, gdy kontener ma `overflow: hidden` lub brak odpowiedniego paddingu.

### ✅ Poprawne rozwiązanie

Dodaj prawy padding do kontenerów z elementami neumorficznymi:

```css
pr-1  /* Tailwind: 0.25rem / 4px */
```

### Przykład

```jsx
/* ❌ Błędnie - cień ucięty */
<div className="flex justify-between">
    <button className="neu-tag">Edytuj</button>
</div>

/* ✅ Poprawnie - cień widoczny */
<div className="flex justify-between pr-1">
    <button className="neu-tag">Edytuj</button>
</div>
```

### Zasada ogólna

Elementy z cieniami zewnętrznymi (box-shadow) wymagają odpowiedniego paddingu w kontenerze nadrzędnym, aby cień nie był obcinany.

---

> 📅 **Ostatnia aktualizacja:** 2025-12-24
