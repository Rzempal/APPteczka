Komunikacja z tymi bazami danych przez API jest możliwa, jednak każdy z systemów stosuje inne standardy techniczne i wymogi formalne.

### 1. EUDAMED (Wyroby medyczne)

EUDAMED nie oferuje klasycznego, otwartego interfejsu REST API dla każdego użytkownika. System opiera się na architekturze **Machine-to-Machine (M2M)**.

- **Standard techniczny:** Wykorzystuje protokół **AS4 (Access Point)** oraz format danych **XML**. Wymagane jest zainstalowanie i skonfigurowanie punktu dostępowego (np. oprogramowania _Domibus_).
    
- **Dla kogo:** Usługa jest przeznaczona dla zarejestrowanych podmiotów gospodarczych (producentów, importerów) oraz organów nadzorczych.
    
- **Dostęp do danych publicznych:** Komisja Europejska nie udostępniła dotychczas oficjalnego, publicznego REST API do przeszukiwania bazy. Programiści często korzystają z nieoficjalnych dokumentacji (np. OpenRegulatory) lub analizy zapytań sieciowych (web scraping) publicznego portalu, co jednak nie jest rozwiązaniem wspieranym.
    
- **Dokumentacja:** [M2M Data Exchange Services](https://webgate.ec.europa.eu/eudamed-help/en/data-exchange/machine-to-machine/m2m-data-exchange-architecture.html)
    

### 2. GIS (Suplementy diety) i URPL (Wyroby w Polsce)

Rejestry krajowe rzadko oferują bezpośrednie API produkcyjne dla systemów zewnętrznych. Najskuteczniejszą metodą jest skorzystanie z portalu **dane.gov.pl**.

- **Portal Otwarte Dane:** Większość baz GIS i URPL (w tym Rejestr Produktów Leczniczych oraz Rejestr Suplementów GIS) jest tam publikowana w formie zbiorów danych.
    
- **REST API:** Portal `dane.gov.pl` udostępnia ujednolicony interfejs API, który pozwala na:
    
    - Wyszukiwanie konkretnych zbiorów danych (datasetów).
        
    - Pobieranie zasobów w formatach JSON, CSV lub XML.
        
    - Filtrowanie rekordów bezpośrednio w zapytaniu API.
        
- **Przykład:** Możesz odpytać API o dataset o ID `344` (Rejestr produktów zgłoszonych do GIS).
    
- **Dokumentacja:** [API dane.gov.pl](https://www.google.com/search?q=https://dane.gov.pl/pl/api/docs)
    

### Podsumowanie techniczne

|**System**|**Typ połączenia**|**Format danych**|**Wymagania**|
|---|---|---|---|
|**EUDAMED**|M2M / AS4|XML|Punkt dostępowy AS4, SRN (Actor ID)|
|**GIS / URPL**|REST API (przez dane.gov.pl)|JSON / CSV|Klucz API (opcjonalnie dla wyższych limitów)|

---

> [Inference] Bezpośrednia integracja z EUDAMED jest procesem kosztownym i technicznie złożonym, wymagającym certyfikacji punktu dostępowego, dlatego dla celów analitycznych (tylko odczyt) bardziej opłacalne jest korzystanie z gotowych agregatorów danych lub API portalu `dane.gov.pl`.

**Źródła:**

- Komisja Europejska: EUDAMED M2M User Guide.
    
- Portal dane.gov.pl: Dokumentacja interfejsu programistycznego.
    
- URPL: Instrukcja korzystania z systemów teleinformatycznych.
    

Czy potrzebujesz przykładowego zapytania (np. w Pythonie lub cURL), aby pobrać dane z rejestru GIS przez portal Otwarte Dane?