# Redactiehulp

Hulpmiddel voor redacteuren bij NederlandWereldwijd om webteksten te controleren op schrijfwijzerregels en om een kant-en-klare prompt te bouwen waarmee Claude.ai de tekst (her)schrijft. Zie `strategy.md` voor de achtergrond en `bouwplan.md` (of de sessiegeschiedenis) voor het bouwplan.

## Wat dit is

Eén statische pagina (`index.html`), 100% client-side: geen backend, geen login, geen opslag buiten je eigen browser. Alles draait lokaal totdat je zelf op "kopieer prompt" klikt en die prompt in Claude.ai plakt — dat is nog steeds een bewuste, handmatige stap door de redacteur zelf.

## Belangrijk: regelset in dit bestand is een placeholder

`index.html` bevat op dit moment een **fictieve voorbeeldregelset** (duidelijk gelabeld in de code, blok `RULES`), **niet** de officiële NWW-schrijfwijzer. De echte schrijfwijzer is intern (niet geheim, maar niet bedoeld voor een publieke repo) en wordt daarom niet in deze git-geschiedenis opgeslagen.

Voor het echte gebruik is er een losse HTML-versie met de echte regelset, die niet via GitHub wordt gedeeld maar rechtstreeks (bijv. via Teams/e-mail/SharePoint) rondgestuurd wordt. Wil je die versie bijwerken? Lever het brondocument (Word/PDF/tekst) opnieuw aan een sessie aan; de regels worden er dan handmatig in verwerkt en je krijgt een nieuw bestand terug.

## Gebruiken

Open `index.html` gewoon in een browser (dubbelklikken, of via een GitHub Pages-link als die voor de demo is ingeschakeld). Geen installatie nodig.

1. Vul titel, introductie en/of hoofdtekst in.
2. Klik op "Controleer tekst" voor directe, regelgebaseerde feedback (geen AI nodig).
3. Klik op "Genereer prompt" om een kant-en-klare prompt te maken; kopieer deze naar Claude.ai.
4. Plak de AI-output terug bij stap 3 op de pagina om vóór/na te vergelijken.

## Beveiligde versie (app.html)

Naast de open demo `index.html` staat er een afgeschermde versie: `app.html`. Daar staat de
regelset niet in het bestand maar in Supabase, achter RLS-policies, en komt hij pas binnen na
inloggen met een vooraf toegestaan account. De bijbehorende SQL staat in `supabase/`; de
stap-voor-stap-instructies voor Supabase en Cloudflare, plus het testscript, staan in
[`TOEGANG.md`](TOEGANG.md).

Twee dingen om niet te verwarren: `app.html` en de JavaScript erin zijn gewoon publieke
frontendbestanden — de bescherming zit in Cloudflare Access (vóór de bestanden) en in de
RLS-policies (vóór de gegevens). In `supabase-config.js` hoort alleen de project-URL en de
anon/publishable key; nooit een service-role key, secret key of databasewachtwoord.

## Regelset aanpassen

Pas het `RULES`-blok bovenaan het `<script>`-gedeelte van `index.html` aan. Elke regel is een object met `id`, `titel`, `categorie`, `bron`, `scope` (`titel`, `intro` of `tekst`) en een `check(waarde)`-functie die een lijst gevonden aandachtspunten teruggeeft. De rest van de pagina (UI, promptgenerator, vergelijking) hoeft niet aangepast te worden.
