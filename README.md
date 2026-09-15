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

1. Plak de hele tekst (titel + introductie + hoofdtekst) in 1 keer in het tekstveld — er is bewust maar 1 invoerveld, geen aparte velden voor titel/introductie.
2. Klik op "Controleer" voor directe, regelgebaseerde feedback.
3. Klik op "Verbeter", bekijk de voorstellen, vink af wat je wilt overnemen en klik op "Neem over".
4. Optioneel (zolang "Herschrijf" nog niet gebouwd is): klap "Alternatief: prompt kopiëren en resultaat terugplakken" open, genereer een prompt, plak die in Claude.ai en plak het antwoord terug om vóór/na te vergelijken.

### Hoe titel/introductie/hoofdtekst worden herkend

`herkenTitelIntroUitTekst()` splitst het ene tekstveld: met labels ("Titel"/"Introductie"/"Hoofdtekst" of "Tekst", elk op een eigen regel) is de indeling expliciet; zonder labels geldt de vuistregel "1e regel = titel, 2e regel = introductie, de rest is hoofdtekst". Die vuistregel hoeft niet perfect te zijn — Controleer wijst vanzelf op een titel die te lang is als de indeling een keer misgaat.

## Beveiligde versie (app.html)

Naast de open demo `index.html` staat er een afgeschermde versie: `app.html`. Daar staat de
regelset niet in het bestand maar in Supabase, achter RLS-policies, en komt hij pas binnen na
inloggen met een vooraf toegestaan account. De bijbehorende SQL staat in `supabase/`; de
stap-voor-stap-instructies voor Supabase en Cloudflare, plus het testscript, staan in
[`TOEGANG.md`](TOEGANG.md).

De regelset in `app.html` komt uit de database, niet uit het bestand: de echte schrijfwijzer
staat in Supabase achter RLS en is daarom bewust niet in deze openbare repo te vinden.
`supabase/regeltypen.md` beschrijft alleen de structuur.

Twee dingen om niet te verwarren: `app.html` en de JavaScript erin zijn gewoon publieke
frontendbestanden — de bescherming zit in Cloudflare Access (vóór de bestanden) en in de
RLS-policies (vóór de gegevens). In `supabase-config.js` hoort alleen de project-URL en de
anon/publishable key; nooit een service-role key, secret key of databasewachtwoord.

## Regelset aanpassen

Pas het `RULES`-blok bovenaan het `<script>`-gedeelte van `index.html` aan. Elke regel is een object met `id`, `titel`, `categorie`, `bron`, `scope` (`titel`, `intro` of `tekst`), `autoFixable` (kan de app dit zelf oplossen in stap 2?) en een `check(waarde)`-functie die een lijst gevonden aandachtspunten teruggeeft.

Voor automatische verbeteringen (stap 2) zijn er twee configureerbare lijsten naast `RULES`: `WOORDVERVANGINGEN` (afgeraden woorden/uitdrukkingen met een alternatief) en `AFKORTINGEN` (afkortingen die de eerste keer voluit moeten). Ook `TOEGESTANE_KOP_LABELS` is aan te passen: dat bepaalt welke kop-labels met dubbele punt zijn toegestaan (bijvoorbeeld "Stap 3: ..."). De rest van de pagina (UI, fix-engine, promptgenerator, vergelijking) hoeft niet aangepast te worden.
