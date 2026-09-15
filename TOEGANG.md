# Toegang instellen — Redactiehulp

Twee lagen, allebei buiten de HTML:

| Laag | Beschermt | Waar je het instelt |
|---|---|---|
| **Cloudflare Access** | de bestanden zelf (wie krijgt de pagina überhaupt) | Cloudflare, in de browser |
| **Supabase RLS-policies** | de gegevens (wie mag de regelset lezen) | Supabase, in de browser |

Het inlogformulier in `app.html` bedient laag 2. Het *is* de beveiliging niet.
Wie de pagina kan opvragen, kan de JavaScript lezen — dat hoort zo, en daarom
staat er geen enkel geheim in.

> **Belangrijk:** de repo `NWW-team/Redactiehulp` is nu **openbaar**. Cloudflare Access
> beschermt de gepubliceerde site, niet je broncode op github.com. Wil je dat "de hele
> site privé" ook voor de code geldt, zet de repo dan op **Private** (Settings →
> General → Danger Zone → Change visibility). Cloudflare Pages werkt gewoon met een
> private repo.

---

## Stand van zaken (bijgewerkt 15 sep 2026)

**De hele Supabase-kant is klaar en geverifieerd** in project `SSBNWW's Project`
(`wmqketplyfscvcxxpnmb`). Deel A hieronder is naslag geworden. Alleen deel B
(Cloudflare) moet nog.

**Wat er live staat**

- `toegestane_gebruiker` (allowlist op e-mailadres) en `schrijfwijzer_regel`, allebei
  met RLS aan, één select-policy, en geen schrijfrechten voor `anon` of `authenticated`.
- Zes fictieve regels in `schrijfwijzer_regel`.
- Trigger `beperk_registratie_tot_allowlist`: een account met een adres buiten de
  allowlist kan niet worden aangemaakt, ook niet vanuit het dashboard. De beperking
  zit in de database, niet in een schakelaar of een verborgen knop.
- Trigger `koppel_allowlist_aan_account`: koppelt de allowlist-rij automatisch aan het
  account zodra dat bestaat.
- Twee testaccounts, allebei bevestigd en gekoppeld:
  `toegestaan.redacteur@example.com` (actief) en `geen.toegang@example.com` (niet actief).
- Project-URL en publishable key staan in `supabase-config.js`.

**Getest met de echte accounts** (policies uitgevoerd onder de werkelijke user-id's)

| Scenario | Regels zichtbaar | Eigen allowlist-rij |
|---|---|---|
| A. uitgelogd (`anon`) | 0 | 0 |
| B. `toegestaan.redacteur@example.com` | 6 | 1 |
| C. `geen.toegang@example.com` | 0 | 1 (met `actief = false`) |
| D. B probeert de allowlist-rij van C te lezen | 0 | — |
| E. C probeert zichzelf actief te maken | geweigerd (`permission denied`) | — |

Eerder al getest met proefinserts in een teruggedraaide transactie: registratie buiten
de allowlist wordt geweigerd, registratie erbinnen wordt toegelaten en automatisch
gekoppeld, en een ingelogde gebruiker kan geen regels toevoegen.

Security advisor: één melding, over `heeft_toegang()`. Die is bedoeld — de policy
roept die functie aan, en hij geeft alleen een ja/nee over de aanroeper terug.

**Wat er nog moet gebeuren**

| Stap | Door wie |
|---|---|
| B1. Cloudflare Pages koppelen aan de repo | **jij** |
| Testronde in de browser (deel C) | **jij** |
| B2. Cloudflare Access ervoor zetten | **jij** |
| Repo op private zetten (optioneel, voor "hele site privé") | **jij** |


---

## Deel A — Supabase (ongeveer 10 minuten)

### A1. Registratie uitzetten
Zonder deze stap kan iedereen met de publieke sleutel een account aanmaken.

1. Open je project op [supabase.com/dashboard](https://supabase.com/dashboard).
2. **Authentication** → **Sign In / Providers** → **Email**
   (in oudere versies: *Authentication → Providers → Email*).
3. Zet **Allow new users to sign up** (soms *Enable sign ups*) **uit**. Opslaan.

Laat **Confirm email** gewoon aan staan. We omzeilen dat straks per gebruiker, zonder
de projectinstelling te verzwakken.

### A2. Twee testaccounts aanmaken
1. **Authentication** → **Users** → **Add user** → **Create new user**.
2. Account 1 — dit wordt het toegestane account:
   - E-mail: `toegestaan.redacteur@example.com`
   - Wachtwoord: kies er zelf een. **Zet het niet in de chat, niet in een bestand en niet in GitHub.**
   - Vink **Auto Confirm User** aan → *Create user*.
3. Account 2 — dit blijft bewust zónder toegang:
   - E-mail: `geen.toegang@example.com`
   - Ander wachtwoord, ook **Auto Confirm User** aan → *Create user*.

*Auto Confirm User* markeert alleen deze twee accounts als bevestigd. Er gaat geen mail
uit en de e-mailinstellingen van het project blijven ongewijzigd.

### A3. Tabellen en policies aanmaken
1. **SQL Editor** → **New query**.
2. Plak de volledige inhoud van [`supabase/schema.sql`](supabase/schema.sql) → **Run**.
3. Onderaan verschijnt een controletabel. Verwacht:

   | tabel | rls_aan | aantal_policies |
   |---|---|---|
   | schrijfwijzer_regel | true | 1 |
   | toegestane_gebruiker | true | 1 |

   Staat er ergens `false` bij `rls_aan`, ga dan niet verder.

### A4. Alleen account 1 toegang geven
1. **SQL Editor** → **New query**.
2. Plak [`supabase/allowlist-toevoegen.sql`](supabase/allowlist-toevoegen.sql) → **Run**.
3. De laatste query toont beide accounts. Verwacht:

   | account | heeft_toegang |
   |---|---|
   | toegestaan.redacteur@example.com | true |
   | geen.toegang@example.com | false |

### A5. De publieke projectgegevens ophalen
1. **Project Settings** → **API Keys**.
2. Kopieer de **Project URL** (`https://<projectref>.supabase.co`).
3. Kopieer de **anon** / **publishable** key (begint met `eyJ...` of `sb_publishable_...`).
4. Zet die twee in `supabase-config.js` — in Claude Code, of rechtstreeks op GitHub via
   het potloodje.

> Kopieer **nooit** de `service_role` key, de `secret` key of je databasewachtwoord.
> Die horen niet in de frontend, niet in de repo en niet in een chatbericht.
> De anon/publishable key hoort daar juist wél: hij is bedoeld om publiek te zijn en
> wordt afgedekt door de RLS-policies.

---

## Deel B — Cloudflare (ongeveer 15 minuten)

Dit is de laag die GitHub Pages niet kan leveren: iets dat vóór de bestanden staat.

### B1. De site publiceren op Cloudflare Pages
1. Maak een gratis account op [dash.cloudflare.com](https://dash.cloudflare.com).
2. **Workers & Pages** → **Create** → tab **Pages** → **Connect to Git**.
3. Autoriseer GitHub en kies `NWW-team/Redactiehulp`.
4. Build-instellingen:
   - Framework preset: **None**
   - Build command: **leeg laten**
   - Build output directory: `/`
5. **Save and Deploy**. Je krijgt een adres als `redactiehulp.pages.dev`.

Op dit moment is die URL nog **openbaar**. Stap B2 sluit hem af.

### B2. Access ervoor zetten
1. In hetzelfde dashboard: **Zero Trust**. De eerste keer kies je een teamnaam en het
   **Free** plan (tot 50 gebruikers).
2. **Access** → **Applications** → **Add an application** → **Self-hosted**.
3. Application name: `Redactiehulp`. Als domein kies je je Pages-project of vul je
   `redactiehulp.pages.dev` in.
4. Identity provider: laat **One-time PIN** aan staan. Dan is er geen koppeling met een
   ander inlogsysteem nodig — bezoekers krijgen een code per mail.
5. Voeg een policy toe:
   - Name: `Alleen testers`
   - Action: **Allow**
   - Include → **Emails** → de adressen die binnen mogen (jouw eigen adres en dat van je
     testers). Let op: dit zijn **echte** mailboxen, want de code moet aankomen —
     `example.com` werkt hier dus niet.
6. Opslaan. Zet dezelfde bescherming ook op **preview deployments**, anders is elke
   branch-preview publiek.

> Accepteert Cloudflare de `pages.dev`-hostnaam niet in de Access-applicatie, dan heb je
> een eigen domein in Cloudflare nodig. Dat kon ik vanaf hier niet uitproberen — laat het
> weten en ik pas de instructie aan.

### B3. Site URL in Supabase bijwerken (optioneel)
**Authentication** → **URL Configuration** → **Site URL** → je `pages.dev`-adres.
Voor inloggen met wachtwoord is dit niet nodig; het is wel nodig zodra je ooit
magic links of wachtwoordherstel gebruikt.

---

## Deel C — Testen

Doe dit in een **privévenster**, zodat er geen oude sessie meespeelt.

| # | Test | Verwacht |
|---|---|---|
| 1 | Open de `pages.dev`-URL zonder Access-sessie | Cloudflare vraagt om je e-mail + pincode. Je ziet de app niet. |
| 2 | Door Access heen, nog niet ingelogd in de app | Inlogscherm. Geen regelset, geen invoervelden. |
| 3 | Inloggen met `toegestaan.redacteur@example.com` | App verschijnt, balk toont "6 regels geladen". "Controleer tekst" werkt. |
| 4 | Uitloggen, inloggen met `geen.toegang@example.com` | Scherm "Geen toegang". Geen regels, ook niet kort. |
| 5 | **Directe URL:** ga rechtstreeks naar `.../app.html` terwijl je uitgelogd bent | Inlogscherm. Er is geen URL die de app zonder sessie toont. |
| 6 | **Direct gegevensverzoek (uitgelogd):** open het blok "Toegang zelf testen" en klik de knop | `status: 200` en `antwoord: []`. Een lege lijst is de policy die werkt — geen storing. |
| 7 | Zelfde verzoek als account 2 | Ook `[]`. Ingelogd zijn is niet genoeg; je moet op de allowlist staan. |
| 8 | Zelfde verzoek als account 1 | Een lijst met de zes regels. |
| 9 | **Na uitloggen opnieuw proberen:** log uit, klik nogmaals op de knop | Weer `[]`. Vernieuw de pagina: inlogscherm, invoervelden leeg. |

### Test 6 en 9 ook buiten de app om
Plak dit in de adresbalk van een privévenster (vul je eigen projectref en anon key in).
Zo omzeil je de pagina volledig en praat je rechtstreeks met de database:

```
https://<projectref>.supabase.co/rest/v1/schrijfwijzer_regel?select=*&apikey=<anon-key>
```

Verwacht: `[]`. Krijg je wél regels te zien zonder ingelogd te zijn, dan staat RLS niet
aan — stop en controleer stap A3.

---

## Wat hierna nog open staat

- De **échte schrijfwijzer** zit nog niet in de database. Laad die pas als de tests
  hierboven slagen, via **Table Editor** of een `insert`-query in de SQL Editor.
- `index.html` blijft de onbeschermde demo met de placeholderregels. Wil je die
  weghalen of achter Access zetten, zeg het dan.
- De Supabase-bibliotheek komt van een CDN (`@supabase/supabase-js@2`, niet vastgepind).
  Voor een strengere opzet zet je een eigen kopie in de repo of pin je een versie met
  een integriteitshash.
