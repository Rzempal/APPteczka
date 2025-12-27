module.exports=[66680,(a,b,c)=>{b.exports=a.x("node:crypto",()=>require("node:crypto"))},73603,49666,a=>{"use strict";var b=a.i(66680);let c={randomUUID:b.randomUUID},d=new Uint8Array(256),e=d.length,f=[];for(let a=0;a<256;++a)f.push((a+256).toString(16).slice(1));let g=function(a,g,h){if(c.randomUUID&&!g&&!a)return c.randomUUID();var i=a,j=h;let k=(i=i||{}).random??i.rng?.()??(e>d.length-16&&((0,b.randomFillSync)(d),e=0),d.slice(e,e+=16));if(k.length<16)throw Error("Random bytes length must be >= 16");if(k[6]=15&k[6]|64,k[8]=63&k[8]|128,g){if((j=j||0)<0||j+16>g.length)throw RangeError(`UUID byte range ${j}:${j+15} is out of buffer bounds`);for(let a=0;a<16;++a)g[j+a]=k[a];return g}return function(a,b=0){return(f[a[b+0]]+f[a[b+1]]+f[a[b+2]]+f[a[b+3]]+"-"+f[a[b+4]]+f[a[b+5]]+"-"+f[a[b+6]]+f[a[b+7]]+"-"+f[a[b+8]]+f[a[b+9]]+"-"+f[a[b+10]]+f[a[b+11]]+f[a[b+12]]+f[a[b+13]]+f[a[b+14]]+f[a[b+15]]).toLowerCase()}(k)};function h(){return[]}function i(a){}function j(a){let b=[],c=[];for(let d of a){if(!d.nazwa)continue;let a=b.find(a=>a.nazwa?.toLowerCase().trim()===d.nazwa?.toLowerCase().trim());a&&c.push({nazwa:d.nazwa,existingId:a.id})}return c}function k(a,b){let c=[],d=[];for(let e of a.leki){if(!e.nazwa){let a={id:g(),nazwa:e.nazwa,opis:e.opis,wskazania:e.wskazania,tagi:e.tagi,labels:e.labels,notatka:e.notatka,dataDodania:new Date().toISOString()};d.push(a);continue}let a=b.get(e.nazwa)||"add",f=c.findIndex(a=>a.nazwa?.toLowerCase().trim()===e.nazwa?.toLowerCase().trim());if(-1!==f&&"replace"===a)c[f]={...c[f],opis:e.opis,wskazania:e.wskazania,tagi:e.tagi,labels:e.labels,notatka:e.notatka};else{if("skip"===a)continue;let b={id:g(),nazwa:e.nazwa,opis:e.opis,wskazania:e.wskazania,tagi:e.tagi,labels:e.labels,notatka:e.notatka,dataDodania:new Date().toISOString()};d.push(b)}}return i([...c,...d]),d}function l(a,b){let c=[],d=[];for(let e of a.leki){if(!e.nazwa){let a={...e,id:g(),dataDodania:e.dataDodania||new Date().toISOString()};d.push(a);continue}let a=b.get(e.nazwa)||"add",f=c.findIndex(a=>a.nazwa?.toLowerCase().trim()===e.nazwa?.toLowerCase().trim());if(-1!==f&&"replace"===a)c[f]={...e,id:c[f].id};else{if("skip"===a)continue;let b={...e,id:g(),dataDodania:e.dataDodania||new Date().toISOString()};d.push(b)}}return i([...c,...d]),d}function m(a){let b=[],c=b.filter(b=>b.id!==a);return c.length!==b.length&&(i(c),!0)}function n(a,b){let c=[],d=c.findIndex(b=>b.id===a);return -1===d?null:(c[d]={...c[d],...b},i(c),c[d])}function o(){}function p(){return JSON.stringify({leki:[]},null,2)}function q(a){if(!a||"object"!=typeof a||!Array.isArray(a.leki)||0===a.leki.length)return!1;let b=a.leki[0];return"string"==typeof b.id&&"string"==typeof b.dataDodania}a.s(["v4",0,g],49666),a.s(["clearMedicines",()=>o,"deleteMedicine",()=>m,"exportMedicines",()=>p,"findDuplicates",()=>j,"getMedicines",()=>h,"importBackup",()=>l,"importMedicinesWithDuplicateHandling",()=>k,"isBackupFormat",()=>q,"updateMedicine",()=>n],73603)},36847,80726,a=>{"use strict";function b(){return`# Prompt – Rozpoznawanie lek\xf3w ze zdjęcia (Import JSON)

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

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy lek\xf3w użytkownika**.`}function c(a){return a.map(a=>a.nazwa||"Nieznany lek").join(", ")}async function d(a){try{return await navigator.clipboard.writeText(a),!0}catch{return!1}}a.s(["copyToClipboard",()=>d,"generateImportPrompt",()=>b,"generateMedicineList",()=>c],36847);let e=["ból","ból głowy","ból gardła","ból mięśni","ból menstruacyjny","ból ucha","nudności","wymioty","biegunka","zaparcia","wzdęcia","zgaga","kolka","gorączka","kaszel","katar","duszność","świąd","wysypka","oparzenie","ukąszenie","rana","sucha skóra","suche oczy","alergia","bezsenność","stres","choroba lokomocyjna","afty","ząbkowanie"],f=["infekcja wirusowa","infekcja bakteryjna","infekcja grzybicza","przeziębienie","grypa"],g=["przeciwbólowy","przeciwgorączkowy","przeciwzapalny","przeciwhistaminowy","przeciwkaszlowy","wykrztuśny","przeciwwymiotny","przeciwbiegunkowy","przeczyszczający","probiotyk","nawilżający","odkażający","uspokajający","rozkurczowy","przeciwświądowy"],h=["układ pokarmowy","układ oddechowy","układ krążenia","oczy","uszy","skóra","jama ustna","nos","mięśnie i stawy","układ nerwowy","układ moczowy"],i=["lek OTC","lek Rx","suplement","probiotyk","wyrób medyczny","test diagnostyczny","kosmetyk leczniczy"],j=["dla dorosłych","dla dzieci","dla niemowląt","dla kobiet w ciąży","dla seniorów"];[...e,...f,...g,...h,...i,...j],a.s(["LABEL_COLORS",0,{red:{name:"Czerwony",hex:"#ef4444"},orange:{name:"Pomarańczowy",hex:"#f97316"},yellow:{name:"Żółty",hex:"#eab308"},green:{name:"Zielony",hex:"#22c55e"},blue:{name:"Niebieski",hex:"#3b82f6"},purple:{name:"Fioletowy",hex:"#a855f7"},pink:{name:"Różowy",hex:"#ec4899"},gray:{name:"Szary",hex:"#6b7280"}},"MAX_LABELS_GLOBAL",0,15,"MAX_LABELS_PER_MEDICINE",0,5,"TAG_CATEGORIES",0,[{key:"objawy",label:"Objawy",tags:e},{key:"typInfekcji",label:"Typ infekcji",tags:f},{key:"dzialanie",label:"Działanie leku",tags:g},{key:"obszar",label:"Obszar ciała",tags:h},{key:"rodzaj",label:"Rodzaj produktu",tags:i},{key:"grupa",label:"Grupa docelowa",tags:j}]],80726)}];

//# sourceMappingURL=%5Broot-of-the-server%5D__2501298f._.js.map