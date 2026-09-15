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
| GitHub Pages aanzetten (deel B) | **jij** — twee klikken |
| Testronde in de browser (deel C) | **jij** |
| Cloudflare Access ervoor zetten (deel D) | later, optioneel |


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

## Deel B — De app online zetten met GitHub Pages

We doen bewust eerst alleen deze laag, zodat je de toegangscontrole op de gegevens
los kunt testen. Let op wat dit wel en niet is:

- **Wel:** de regelset is afgeschermd. Zonder toegestaan account krijg je niets,
  langs welke weg dan ook.
- **Niet:** de pagina zelf is openbaar. Iedereen met de URL kan `app.html` openen en
  de JavaScript lezen. Daar staat geen geheim in, dus dat is geen lek — maar het is
  ook geen "hele site privé". Daarvoor is deel D nodig.

1. Open **https://github.com/NWW-team/Redactiehulp/settings/pages**
2. Bij **Source** kies je **Deploy from a branch**.
3. Bij **Branch** kies je `claude/app-datastromen-diagram-ql0vjv` en map `/ (root)` → **Save**.
   (Wil je liever vanaf `main` publiceren, merge die branch dan eerst.)
4. Wacht één tot twee minuten. Bovenaan dezelfde pagina verschijnt de URL, meestal
   `https://nww-team.github.io/Redactiehulp/`.

De beschermde app staat dan op **`https://nww-team.github.io/Redactiehulp/app.html`**.
Op `/` staat nog steeds de open demo `index.html` met de placeholderregels — die is
bewust ongewijzigd gebleven.

---

## Deel C — Testen

Doe dit in een **privévenster**, zodat er geen oude sessie meespeelt. Gebruik de twee
accounts die in het Supabase-dashboard zijn aangemaakt.

| # | Test | Verwacht |
|---|---|---|
| 1 | Open `.../app.html`, nog niet ingelogd | Inlogscherm. Geen regelset, geen invoervelden. |
| 2 | Klap "Toegang zelf testen" open en klik de knop | `status: 200` en `antwoord: []` |
| 3 | Log in met `toegestaan.redacteur@example.com` | App verschijnt, balk toont "6 regels geladen". "Controleer tekst" werkt. |
| 4 | Klik nu nogmaals op de testknop | Een lijst met de zes regels |
| 5 | Uitloggen, inloggen met `geen.toegang@example.com` | Scherm **"Geen toegang"**. Geen regels, ook niet kort zichtbaar. |
| 6 | Testknop bij dat account | Weer `[]` — ingelogd zijn is niet genoeg |
| 7 | Uitloggen, pagina verversen | Inlogscherm, invoervelden leeg |
| 8 | **Directe URL:** ga uitgelogd rechtstreeks naar `.../app.html` | Inlogscherm. Er is geen URL die de app zonder sessie toont. |

### Test 2 en 6 ook buiten de app om

Plak dit in de adresbalk van een privévenster. Zo omzeil je de pagina volledig en praat
je rechtstreeks met de database:

```
https://wmqketplyfscvcxxpnmb.supabase.co/rest/v1/schrijfwijzer_regel?select=*&apikey=sb_publishable_pCH-CbkAUydS3lw_u4eH7g_KUx_L3Gz
```

Verwacht: `[]`. Zie je wél regels zonder ingelogd te zijn, stop dan — dan klopt er iets
niet aan de policies.

### Wat je ook nog kunt proberen

- Maak in het Supabase-dashboard een gebruiker aan met een willekeurig ander adres.
  Dat hoort te mislukken met een databasefout: de trigger
  `beperk_registratie_tot_allowlist` weigert het.
- Zet `actief` van `geen.toegang@example.com` op `true` in de Table Editor en log opnieuw
  in. Dat account krijgt dan wél de regelset. Zet hem daarna weer op `false`.

---

## Deel D — Later: de site zelf afsluiten (optioneel)

Pas zinvol als je ook de HTML zelf privé wilt. GitHub Pages kan dat niet; er moet iets
vóór de bestanden staan. De route:

1. Cloudflare-account → **Workers & Pages → Create → Pages → Connect to Git** →
   `NWW-team/Redactiehulp`, build command leeg, output directory `/`.
2. **Zero Trust → Access → Applications → Add an application → Self-hosted**, domein =
   je `pages.dev`-adres, identity provider **One-time PIN**.
3. Policy: **Allow**, Include → **Emails** → echte mailadressen van je testers.
4. Zet dezelfde bescherming op preview deployments.
5. Wil je ook de broncode privé, zet de repo dan op **Private**
   (GitHub → Settings → General → onderaan → Change visibility). Cloudflare Pages werkt
   met een private repo; GitHub Pages op een gratis plan niet.

Dat levert twee inlogmomenten op: eerst Cloudflare, dan de app. Dat is geen dubbelop —
Cloudflare bepaalt wie de bestanden krijgt, Supabase bepaalt wie de gegevens krijgt.

---

## Wat hierna nog open staat

- De **échte schrijfwijzer** zit nog niet in de database. Laad die pas als de tests
  hierboven slagen, via **Table Editor** of een `insert`-query in de SQL Editor.
- `index.html` blijft de onbeschermde demo met de placeholderregels.
- De Supabase-bibliotheek komt van een CDN (`@supabase/supabase-js@2`, niet vastgepind).
  Voor een strengere opzet zet je een eigen kopie in de repo of pin je een versie met
  een integriteitshash.
