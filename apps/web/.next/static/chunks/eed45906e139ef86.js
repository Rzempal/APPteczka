(globalThis.TURBOPACK||(globalThis.TURBOPACK=[])).push(["object"==typeof document?document.currentScript:void 0,91417,14677,a=>{"use strict";let e,n="undefined"!=typeof crypto&&crypto.randomUUID&&crypto.randomUUID.bind(crypto),o=new Uint8Array(16),i=[];for(let a=0;a<256;++a)i.push((a+256).toString(16).slice(1));let t=function(a,t,r){if(n&&!t&&!a)return n();var c=a,y=r;let l=(c=c||{}).random??c.rng?.()??function(){if(!e){if("undefined"==typeof crypto||!crypto.getRandomValues)throw Error("crypto.getRandomValues() not supported. See https://github.com/uuidjs/uuid#getrandomvalues-not-supported");e=crypto.getRandomValues.bind(crypto)}return e(o)}();if(l.length<16)throw Error("Random bytes length must be >= 16");if(l[6]=15&l[6]|64,l[8]=63&l[8]|128,t){if((y=y||0)<0||y+16>t.length)throw RangeError(`UUID byte range ${y}:${y+15} is out of buffer bounds`);for(let a=0;a<16;++a)t[y+a]=l[a];return t}return function(a,e=0){return(i[a[e+0]]+i[a[e+1]]+i[a[e+2]]+i[a[e+3]]+"-"+i[a[e+4]]+i[a[e+5]]+"-"+i[a[e+6]]+i[a[e+7]]+"-"+i[a[e+8]]+i[a[e+9]]+"-"+i[a[e+10]]+i[a[e+11]]+i[a[e+12]]+i[a[e+13]]+i[a[e+14]]+i[a[e+15]]).toLowerCase()}(l)};a.s(["v4",0,t],14677);let r="appteczka_medicines";function c(){try{let a=localStorage.getItem(r);if(!a)return[];let e=JSON.parse(a);return Array.isArray(e)?e:[]}catch{return console.error("Błąd odczytu danych z localStorage"),[]}}function y(a){try{localStorage.setItem(r,JSON.stringify(a))}catch{console.error("Błąd zapisu danych do localStorage")}}function l(a){let e=c(),n=[];for(let o of a){if(!o.nazwa)continue;let a=e.find(a=>a.nazwa?.toLowerCase().trim()===o.nazwa?.toLowerCase().trim());a&&n.push({nazwa:o.nazwa,existingId:a.id})}return n}function z(a,e){let n=c(),o=[];for(let i of a.leki){if(!i.nazwa){let a={id:t(),nazwa:i.nazwa,opis:i.opis,wskazania:i.wskazania,tagi:i.tagi,labels:i.labels,notatka:i.notatka,dataDodania:new Date().toISOString()};o.push(a);continue}let a=e.get(i.nazwa)||"add",r=n.findIndex(a=>a.nazwa?.toLowerCase().trim()===i.nazwa?.toLowerCase().trim());if(-1!==r&&"replace"===a)n[r]={...n[r],opis:i.opis,wskazania:i.wskazania,tagi:i.tagi,labels:i.labels,notatka:i.notatka};else{if("skip"===a)continue;let e={id:t(),nazwa:i.nazwa,opis:i.opis,wskazania:i.wskazania,tagi:i.tagi,labels:i.labels,notatka:i.notatka,dataDodania:new Date().toISOString()};o.push(e)}}return y([...n,...o]),o}function w(a,e){let n=c(),o=[];for(let i of a.leki){if(!i.nazwa){let a={...i,id:t(),dataDodania:i.dataDodania||new Date().toISOString()};o.push(a);continue}let a=e.get(i.nazwa)||"add",r=n.findIndex(a=>a.nazwa?.toLowerCase().trim()===i.nazwa?.toLowerCase().trim());if(-1!==r&&"replace"===a)n[r]={...i,id:n[r].id};else{if("skip"===a)continue;let e={...i,id:t(),dataDodania:i.dataDodania||new Date().toISOString()};o.push(e)}}return y([...n,...o]),o}function s(a){let e=c(),n=e.filter(e=>e.id!==a);return n.length!==e.length&&(y(n),!0)}function d(a,e){let n=c(),o=n.findIndex(e=>e.id===a);return -1===o?null:(n[o]={...n[o],...e},y(n),n[o])}function k(){localStorage.removeItem(r)}function u(){return JSON.stringify({leki:c()},null,2)}function p(a){if(!a||"object"!=typeof a||!Array.isArray(a.leki)||0===a.leki.length)return!1;let e=a.leki[0];return"string"==typeof e.id&&"string"==typeof e.dataDodania}a.s(["clearMedicines",()=>k,"deleteMedicine",()=>s,"exportMedicines",()=>u,"findDuplicates",()=>l,"getMedicines",()=>c,"importBackup",()=>w,"importMedicinesWithDuplicateHandling",()=>z,"isBackupFormat",()=>p,"updateMedicine",()=>d],91417)},75276,40559,a=>{"use strict";function e(){return`# Prompt – Rozpoznawanie lek\xf3w ze zdjęcia (Import JSON)

## Rola
Jesteś asystentem farmacji pomagającym użytkownikowi prowadzić prywatną bazę lek\xf3w (domową apteczkę). Użytkownik nie ma wiedzy farmaceutycznej.

## Wejście
Użytkownik przesyła zdjęcie opakowania lub opakowań lek\xf3w.
Na jednym zdjęciu może znajdować się jeden lub kilka r\xf3żnych lek\xf3w.

## Zadanie

1. Przeanalizuj obraz i rozpoznaj **nazwy lek\xf3w widoczne na opakowaniach**.
2. Jeśli na zdjęciu jest więcej niż jeden lek, zwr\xf3ć **osobny obiekt dla każdego**.
3. **Zgadywanie jest zabronione.**

Jeżeli:
- nazwa leku jest nieczytelna,
- opakowanie jest częściowo zasłonięte,
- nie masz 100% pewności,

**zatrzymaj generowanie danych** i zwr\xf3ć obiekt decyzyjny:

\`\`\`json
{
  "status": "niepewne_rozpoznanie",
  "opcje": {
    "A": "Poproś o lepsze zdjęcie",
    "B": "Poproś użytkownika o podanie nazwy leku",
    "C": "Zostaw nazwę pustą"
  }
}
\`\`\`

Nie zgaduj. Nie proponuj nazw.

## Format wyjścia (OBOWIĄZKOWY)

Zwr\xf3ć **wyłącznie poprawny JSON**, bez dodatkowego tekstu.

\`\`\`json
{
  "leki": [
    {
      "nazwa": "string | null",
      "opis": "string",
      "wskazania": ["string", "string"],
      "tagi": ["tag1", "tag2"]
    }
  ]
}
\`\`\`

## Zasady treści

- Język prosty, niemedyczny (np. „lek przeciwb\xf3lowy").
- Nie podawaj dawkowania ani ostrzeżeń.
- Na końcu opisu zawsze dodaj: **„Stosować zgodnie z ulotką."**
- Leki złożone traktuj jako jedną pozycję.

## Dozwolone tagi (kontrolowana lista)

### Objawy
b\xf3l, b\xf3l głowy, b\xf3l gardła, b\xf3l mięśni, b\xf3l menstruacyjny, b\xf3l ucha,
nudności, wymioty, biegunka, zaparcia, wzdęcia, zgaga, kolka,
gorączka, kaszel, katar, duszność,
świąd, wysypka, oparzenie, ukąszenie, rana, sucha sk\xf3ra,
suche oczy, alergia, bezsenność, stres, choroba lokomocyjna, afty, ząbkowanie

### Typ infekcji
infekcja wirusowa, infekcja bakteryjna, infekcja grzybicza, przeziębienie, grypa

### Działanie leku
przeciwb\xf3lowy, przeciwgorączkowy, przeciwzapalny, przeciwhistaminowy,
przeciwkaszlowy, wykrztuśny, przeciwwymiotny, przeciwbiegunkowy,
przeczyszczający, probiotyk, nawilżający, odkażający, uspokajający,
rozkurczowy, przeciwświądowy

### Obszar ciała
układ pokarmowy, układ oddechowy, układ krążenia, oczy, uszy, sk\xf3ra,
jama ustna, nos, mięśnie i stawy, układ nerwowy, układ moczowy

### Rodzaj produktu
lek OTC, lek Rx, suplement, probiotyk, wyr\xf3b medyczny, test diagnostyczny, kosmetyk leczniczy

### Grupa docelowa
dla dorosłych, dla dzieci, dla niemowląt, dla kobiet w ciąży, dla senior\xf3w

## Ograniczenia

- Brak porad medycznych.
- Brak sugerowania zamiennik\xf3w.
- Brak ocen skuteczności.

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy lek\xf3w użytkownika**.`}function n(a){return a.map(a=>a.nazwa||"Nieznany lek").join(", ")}async function o(a){try{return await navigator.clipboard.writeText(a),!0}catch{return!1}}a.s(["copyToClipboard",()=>o,"generateImportPrompt",()=>e,"generateMedicineList",()=>n],75276);let i=["ból","ból głowy","ból gardła","ból mięśni","ból menstruacyjny","ból ucha","nudności","wymioty","biegunka","zaparcia","wzdęcia","zgaga","kolka","gorączka","kaszel","katar","duszność","świąd","wysypka","oparzenie","ukąszenie","rana","sucha skóra","suche oczy","alergia","bezsenność","stres","choroba lokomocyjna","afty","ząbkowanie"],t=["infekcja wirusowa","infekcja bakteryjna","infekcja grzybicza","przeziębienie","grypa"],r=["przeciwbólowy","przeciwgorączkowy","przeciwzapalny","przeciwhistaminowy","przeciwkaszlowy","wykrztuśny","przeciwwymiotny","przeciwbiegunkowy","przeczyszczający","probiotyk","nawilżający","odkażający","uspokajający","rozkurczowy","przeciwświądowy"],c=["układ pokarmowy","układ oddechowy","układ krążenia","oczy","uszy","skóra","jama ustna","nos","mięśnie i stawy","układ nerwowy","układ moczowy"],y=["lek OTC","lek Rx","suplement","probiotyk","wyrób medyczny","test diagnostyczny","kosmetyk leczniczy"],l=["dla dorosłych","dla dzieci","dla niemowląt","dla kobiet w ciąży","dla seniorów"];[...i,...t,...r,...c,...y,...l],a.s(["LABEL_COLORS",0,{red:{name:"Czerwony",hex:"#ef4444"},orange:{name:"Pomarańczowy",hex:"#f97316"},yellow:{name:"Żółty",hex:"#eab308"},green:{name:"Zielony",hex:"#22c55e"},blue:{name:"Niebieski",hex:"#3b82f6"},purple:{name:"Fioletowy",hex:"#a855f7"},pink:{name:"Różowy",hex:"#ec4899"},gray:{name:"Szary",hex:"#6b7280"}},"MAX_LABELS_GLOBAL",0,15,"MAX_LABELS_PER_MEDICINE",0,5,"TAG_CATEGORIES",0,[{key:"objawy",label:"Objawy",tags:i},{key:"typInfekcji",label:"Typ infekcji",tags:t},{key:"dzialanie",label:"Działanie leku",tags:r},{key:"obszar",label:"Obszar ciała",tags:c},{key:"rodzaj",label:"Rodzaj produktu",tags:y},{key:"grupa",label:"Grupa docelowa",tags:l}]],40559)}]);