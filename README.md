# Redactiehulp

Hulpmiddel voor redacteuren bij NederlandWereldwijd om webteksten te controleren op schrijfwijzerregels en (deels) automatisch te verbeteren. Zie `strategy.md` voor de achtergrond en `bouwplan.md` (of de sessiegeschiedenis) voor het bouwplan.

## Wat dit is

Eén statische pagina (`index.html`), 100% client-side: geen backend, geen login, geen opslag buiten je eigen browser. De pagina werkt in drie stappen:

1. **Controleer** — regelgebaseerde feedback, geen AI nodig. Zegt bij elk punt of de app het zelf kan oplossen of dat het een redacteur vraagt.
2. **Verbeteren** — past alleen mechanische correcties toe (leestekens, aanhalingstekens, afgeraden woorden, afkortingen) waar geen taalgevoel voor nodig is. Ook dit blijft volledig in de browser, zonder AI. Je ziet steeds voor en na, en kiest zelf welke verbeteringen worden overgenomen.
3. **Herschrijven** — nog niet gebouwd. Bedoeld om Claude de tekst te laten herschrijven op stijl en opbouw, met een eigen API-sleutel die alleen in de browser van de gebruiker blijft. Tot die tijd is er een alternatief: een prompt kopiëren naar Claude.ai en het resultaat terugplakken om te vergelijken — dat blijft een bewuste, handmatige stap door de redacteur zelf.

## Belangrijk: regelset in dit bestand is een placeholder

`index.html` bevat op dit moment een **fictieve voorbeeldregelset** (duidelijk gelabeld in de code, blok `RULES`), **niet** de officiële NWW-schrijfwijzer. De echte schrijfwijzer is intern (niet geheim, maar niet bedoeld voor een publieke repo) en wordt daarom niet in deze git-geschiedenis opgeslagen.

Voor het echte gebruik is er een losse HTML-versie met de echte regelset, die niet via GitHub wordt gedeeld maar rechtstreeks (bijv. via Teams/e-mail/SharePoint) rondgestuurd wordt. Wil je die versie bijwerken? Lever het brondocument (Word/PDF/tekst) opnieuw aan een sessie aan; de regels worden er dan handmatig in verwerkt en je krijgt een nieuw bestand terug.

## Gebruiken

Open `index.html` gewoon in een browser (dubbelklikken, of via een GitHub Pages-link als die voor de demo is ingeschakeld). Geen installatie nodig.

1. Vul titel, introductie en/of hoofdtekst in.
2. Klik op "Controleer" voor directe, regelgebaseerde feedback.
3. Klik op "Verbeter", bekijk de voorstellen, vink af wat je wilt overnemen en klik op "Neem geselecteerde verbeteringen over".
4. Optioneel (zolang "Herschrijf" nog niet gebouwd is): klap "Alternatief: prompt kopiëren en resultaat terugplakken" open, genereer een prompt, plak die in Claude.ai en plak het antwoord terug om vóór/na te vergelijken.

## Regelset aanpassen

Pas het `RULES`-blok bovenaan het `<script>`-gedeelte van `index.html` aan. Elke regel is een object met `id`, `titel`, `categorie`, `bron`, `scope` (`titel`, `intro` of `tekst`), `autoFixable` (kan de app dit zelf oplossen in stap 2?) en een `check(waarde)`-functie die een lijst gevonden aandachtspunten teruggeeft.

Voor automatische verbeteringen (stap 2) zijn er twee configureerbare lijsten naast `RULES`: `WOORDVERVANGINGEN` (afgeraden woorden/uitdrukkingen met een alternatief) en `AFKORTINGEN` (afkortingen die de eerste keer voluit moeten). Ook `TOEGESTANE_KOP_LABELS` is aan te passen: dat bepaalt welke kop-labels met dubbele punt zijn toegestaan (bijvoorbeeld "Stap 3: ..."). De rest van de pagina (UI, fix-engine, promptgenerator, vergelijking) hoeft niet aangepast te worden.
