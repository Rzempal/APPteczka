module.exports=[32319,(e,t,a)=>{t.exports=e.x("next/dist/server/app-render/work-unit-async-storage.external.js",()=>require("next/dist/server/app-render/work-unit-async-storage.external.js"))},24725,(e,t,a)=>{t.exports=e.x("next/dist/server/app-render/after-task-async-storage.external.js",()=>require("next/dist/server/app-render/after-task-async-storage.external.js"))},18622,(e,t,a)=>{t.exports=e.x("next/dist/compiled/next-server/app-page-turbo.runtime.prod.js",()=>require("next/dist/compiled/next-server/app-page-turbo.runtime.prod.js"))},56704,(e,t,a)=>{t.exports=e.x("next/dist/server/app-render/work-async-storage.external.js",()=>require("next/dist/server/app-render/work-async-storage.external.js"))},70406,(e,t,a)=>{t.exports=e.x("next/dist/compiled/@opentelemetry/api",()=>require("next/dist/compiled/@opentelemetry/api"))},93695,(e,t,a)=>{t.exports=e.x("next/dist/shared/lib/no-fallback-error.external.js",()=>require("next/dist/shared/lib/no-fallback-error.external.js"))},13420,e=>{"use strict";var t=e.i(47909),a=e.i(74017),r=e.i(96250),n=e.i(59756),o=e.i(61916),i=e.i(74677),s=e.i(69741),l=e.i(16795),d=e.i(87718),c=e.i(95169),p=e.i(47587),u=e.i(66012),w=e.i(70101),y=e.i(26937),z=e.i(10372),k=e.i(93695);e.i(52474);var m=e.i(220),g=e.i(89171);async function x(e,t){let a=process.env.GEMINI_API_KEY;if(!a)return{error:"Brak klucza API Gemini. Skonfiguruj GEMINI_API_KEY w .env.local",code:"API_KEY_MISSING"};let r=`# Prompt – Rozpoznawanie lek\xf3w ze zdjęcia (Import JSON)

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

Celem jest wyłącznie **porządkowanie informacji do prywatnej bazy lek\xf3w użytkownika**.`;try{let n=await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${a}`,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({contents:[{parts:[{text:r},{inline_data:{mime_type:t,data:e}}]}],generationConfig:{temperature:.1,maxOutputTokens:4096}})});if(429===n.status)return{error:"Przekroczono limit zapytań do API Gemini. Spróbuj za chwilę lub użyj ręcznego promptu.",code:"RATE_LIMIT"};if(!n.ok){let e=await n.json().catch(()=>({}));return{error:`Błąd API Gemini: ${n.status} - ${e?.error?.message||"Nieznany błąd"}`,code:"API_ERROR"}}let o=await n.json();console.log("Gemini API raw response:",JSON.stringify(o,null,2));let i=o?.candidates?.[0]?.content?.parts?.[0]?.text;if(!i)return console.log("Gemini no text found in response"),{error:"Gemini nie zwróciło odpowiedzi. Spróbuj z innym zdjęciem.",code:"API_ERROR"};console.log("Gemini text response:",i);let s=i.match(/```json\s*([\s\S]*?)\s*```/)||i.match(/\{[\s\S]*\}/),l=s?s[1]||s[0]:i;try{let e=JSON.parse(l);if("niepewne_rozpoznanie"===e.status)return{error:"Nie udało się jednoznacznie rozpoznać leków. Spróbuj z wyraźniejszym zdjęciem.",code:"PARSE_ERROR"};if(e.leki&&Array.isArray(e.leki))return{leki:e.leki};if(void 0!==e.nazwa)return{leki:[e]};return{error:"Nieoczekiwany format odpowiedzi od Gemini.",code:"PARSE_ERROR"}}catch(e){return console.error("JSON parse error:",e,"Raw text:",i),{error:`Nie udało się sparsować odpowiedzi Gemini jako JSON. Raw: ${i.substring(0,200)}`,code:"PARSE_ERROR"}}}catch(e){return{error:`Błąd połączenia z API Gemini: ${e instanceof Error?e.message:"Nieznany błąd"}`,code:"API_ERROR"}}}let f=["image/jpeg","image/png","image/webp","image/gif"];async function R(e){try{let{image:t,mimeType:a}=await e.json();if(!t||"string"!=typeof t)return g.NextResponse.json({error:"Brak obrazu w żądaniu",code:"INVALID_IMAGE"},{status:400});if(!a||!f.includes(a))return g.NextResponse.json({error:"Nieprawidłowy format obrazu. Dozwolone: JPEG, PNG, WebP, GIF",code:"INVALID_IMAGE"},{status:400});if(3*t.length/4>4194304)return g.NextResponse.json({error:"Obraz jest za duży. Maksymalny rozmiar: 4MB",code:"INVALID_IMAGE"},{status:400});let r=await x(t,a);if("error"in r){let e="API_KEY_MISSING"===r.code?500:"RATE_LIMIT"===r.code?429:400;return g.NextResponse.json(r,{status:e})}return g.NextResponse.json(r)}catch(e){return console.error("Gemini OCR API error:",e),g.NextResponse.json({error:"Wewnętrzny błąd serwera",code:"API_ERROR"},{status:500})}}e.s(["POST",()=>R],97785);var j=e.i(97785);let h=new t.AppRouteRouteModule({definition:{kind:a.RouteKind.APP_ROUTE,page:"/api/gemini-ocr/route",pathname:"/api/gemini-ocr",filename:"route",bundlePath:""},distDir:".next",relativeProjectDir:"",resolvedPagePath:"[project]/apps/web/src/app/api/gemini-ocr/route.ts",nextConfigOutput:"",userland:j}),{workAsyncStorage:b,workUnitAsyncStorage:E,serverHooks:v}=h;function A(){return(0,r.patchFetch)({workAsyncStorage:b,workUnitAsyncStorage:E})}async function N(e,t,r){h.isDev&&(0,n.addRequestMeta)(e,"devRequestTimingInternalsEnd",process.hrtime.bigint());let g="/api/gemini-ocr/route";g=g.replace(/\/index$/,"")||"/";let x=await h.prepare(e,t,{srcPage:g,multiZoneDraftMode:!1});if(!x)return t.statusCode=400,t.end("Bad Request"),null==r.waitUntil||r.waitUntil.call(r,Promise.resolve()),null;let{buildId:f,params:R,nextConfig:j,parsedUrl:b,isDraftMode:E,prerenderManifest:v,routerServerContext:A,isOnDemandRevalidate:N,revalidateOnlyGenerated:I,resolvedPathname:P,clientReferenceManifest:O,serverActionsManifest:_}=x,C=(0,s.normalizeAppPath)(g),S=!!(v.dynamicRoutes[C]||v.routes[P]),T=async()=>((null==A?void 0:A.render404)?await A.render404(e,t,b,!1):t.end("This page could not be found"),null);if(S&&!E){let e=!!v.routes[P],t=v.dynamicRoutes[C];if(t&&!1===t.fallback&&!e){if(j.experimental.adapterPath)return await T();throw new k.NoFallbackError}}let G=null;!S||h.isDev||E||(G="/index"===(G=P)?"/":G);let M=!0===h.isDev||!S,q=S&&!M;_&&O&&(0,i.setManifestsSingleton)({page:g,clientReferenceManifest:O,serverActionsManifest:_});let D=e.method||"GET",U=(0,o.getTracer)(),H=U.getActiveScopeSpan(),B={params:R,prerenderManifest:v,renderOpts:{experimental:{authInterrupts:!!j.experimental.authInterrupts},cacheComponents:!!j.cacheComponents,supportsDynamicResponse:M,incrementalCache:(0,n.getRequestMeta)(e,"incrementalCache"),cacheLifeProfiles:j.cacheLife,waitUntil:r.waitUntil,onClose:e=>{t.on("close",e)},onAfterTaskError:void 0,onInstrumentationRequestError:(t,a,r,n)=>h.onRequestError(e,t,r,n,A)},sharedContext:{buildId:f}},$=new l.NodeNextRequest(e),K=new l.NodeNextResponse(t),J=d.NextRequestAdapter.fromNodeNextRequest($,(0,d.signalFromNodeResponse)(t));try{let i=async e=>h.handle(J,B).finally(()=>{if(!e)return;e.setAttributes({"http.status_code":t.statusCode,"next.rsc":!1});let a=U.getRootSpanAttributes();if(!a)return;if(a.get("next.span_type")!==c.BaseServerSpan.handleRequest)return void console.warn(`Unexpected root span type '${a.get("next.span_type")}'. Please report this Next.js issue https://github.com/vercel/next.js`);let r=a.get("next.route");if(r){let t=`${D} ${r}`;e.setAttributes({"next.route":r,"http.route":r,"next.span_name":t}),e.updateName(t)}else e.updateName(`${D} ${g}`)}),s=!!(0,n.getRequestMeta)(e,"minimalMode"),l=async n=>{var o,l;let d=async({previousCacheEntry:a})=>{try{if(!s&&N&&I&&!a)return t.statusCode=404,t.setHeader("x-nextjs-cache","REVALIDATED"),t.end("This page could not be found"),null;let o=await i(n);e.fetchMetrics=B.renderOpts.fetchMetrics;let l=B.renderOpts.pendingWaitUntil;l&&r.waitUntil&&(r.waitUntil(l),l=void 0);let d=B.renderOpts.collectedTags;if(!S)return await (0,u.sendResponse)($,K,o,B.renderOpts.pendingWaitUntil),null;{let e=await o.blob(),t=(0,w.toNodeOutgoingHttpHeaders)(o.headers);d&&(t[z.NEXT_CACHE_TAGS_HEADER]=d),!t["content-type"]&&e.type&&(t["content-type"]=e.type);let a=void 0!==B.renderOpts.collectedRevalidate&&!(B.renderOpts.collectedRevalidate>=z.INFINITE_CACHE)&&B.renderOpts.collectedRevalidate,r=void 0===B.renderOpts.collectedExpire||B.renderOpts.collectedExpire>=z.INFINITE_CACHE?void 0:B.renderOpts.collectedExpire;return{value:{kind:m.CachedRouteKind.APP_ROUTE,status:o.status,body:Buffer.from(await e.arrayBuffer()),headers:t},cacheControl:{revalidate:a,expire:r}}}}catch(t){throw(null==a?void 0:a.isStale)&&await h.onRequestError(e,t,{routerKind:"App Router",routePath:g,routeType:"route",revalidateReason:(0,p.getRevalidateReason)({isStaticGeneration:q,isOnDemandRevalidate:N})},!1,A),t}},c=await h.handleResponse({req:e,nextConfig:j,cacheKey:G,routeKind:a.RouteKind.APP_ROUTE,isFallback:!1,prerenderManifest:v,isRoutePPREnabled:!1,isOnDemandRevalidate:N,revalidateOnlyGenerated:I,responseGenerator:d,waitUntil:r.waitUntil,isMinimalMode:s});if(!S)return null;if((null==c||null==(o=c.value)?void 0:o.kind)!==m.CachedRouteKind.APP_ROUTE)throw Object.defineProperty(Error(`Invariant: app-route received invalid cache entry ${null==c||null==(l=c.value)?void 0:l.kind}`),"__NEXT_ERROR_CODE",{value:"E701",enumerable:!1,configurable:!0});s||t.setHeader("x-nextjs-cache",N?"REVALIDATED":c.isMiss?"MISS":c.isStale?"STALE":"HIT"),E&&t.setHeader("Cache-Control","private, no-cache, no-store, max-age=0, must-revalidate");let k=(0,w.fromNodeOutgoingHttpHeaders)(c.value.headers);return s&&S||k.delete(z.NEXT_CACHE_TAGS_HEADER),!c.cacheControl||t.getHeader("Cache-Control")||k.get("Cache-Control")||k.set("Cache-Control",(0,y.getCacheControlHeader)(c.cacheControl)),await (0,u.sendResponse)($,K,new Response(c.value.body,{headers:k,status:c.value.status||200})),null};H?await l(H):await U.withPropagatedContext(e.headers,()=>U.trace(c.BaseServerSpan.handleRequest,{spanName:`${D} ${g}`,kind:o.SpanKind.SERVER,attributes:{"http.method":D,"http.target":e.url}},l))}catch(t){if(t instanceof k.NoFallbackError||await h.onRequestError(e,t,{routerKind:"App Router",routePath:C,routeType:"route",revalidateReason:(0,p.getRevalidateReason)({isStaticGeneration:q,isOnDemandRevalidate:N})},!1,A),S)throw t;return await (0,u.sendResponse)($,K,new Response(null,{status:500})),null}}e.s(["handler",()=>N,"patchFetch",()=>A,"routeModule",()=>h,"serverHooks",()=>v,"workAsyncStorage",()=>b,"workUnitAsyncStorage",()=>E],13420)}];

//# sourceMappingURL=%5Broot-of-the-server%5D__7685f441._.js.map