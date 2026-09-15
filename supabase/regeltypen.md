# Regeltypen in `schrijfwijzer_regel`

De inhoud van de regelset staat **niet in deze repo** — die is intern en staat alleen in de
database. Dit bestand beschrijft alleen de *structuur*, zodat je een regel kunt toevoegen of
aanpassen zonder de code te hoeven lezen.

Elke regel heeft een `soort`:

| soort | betekenis |
|---|---|
| `controle` | de regelcheck toetst dit automatisch en meldt aandachtspunten |
| `richtlijn` | niet machinaal te toetsen; gaat mee in de prompt naar Claude.ai |

Een `richtlijn` krijgt altijd `type = 'geen'` en `scope = 'alles'`. De tekst in `uitleg` is
wat er in de prompt terechtkomt, dus schrijf die als instructie aan de schrijver.

## Controletypen

| type | scope | parameters | wat het doet |
|---|---|---|---|
| `max_tekens` | titel | `{"max": 70}` | telt tekens inclusief spaties |
| `max_woorden` | intro | `{"max": 50}` | telt woorden in het hele veld |
| `max_woorden_per_zin` | tekst | `{"max": 15}` | meldt elke te lange zin apart |
| `max_woorden_per_alinea` | tekst | `{"max": 80}` | alinea's worden gesplitst op lege regels |
| `max_woorden_kop` | kop | `{"max": 5}` | draait per tussenkop (regel die met `##` begint) |
| `geen_leestekens` | titel, kop | `{"toegestaan_slot": "?"}` | leesteken aan het eind is toegestaan |
| `kop_lidwoord` | kop | `{"lidwoorden": ["de","het","een"]}` | kijkt alleen naar het eerste woord |
| `verboden_woorden` | tekst, alles | `{"woorden": [...], "alternatief": "..."}` | hele woorden, hoofdletterongevoelig; punten in de term mogen (`bijv.`) |
| `regex_verboden` | tekst, alles | `{"patroon": "...", "hoofdlettergevoelig": true, "alternatief": "..."}` | rauw patroon; zonder de vlag draait het hoofdletterongevoelig |
| `lijdende_vorm` | tekst | `{}` | heuristiek op vormen van *worden* plus voltooid deelwoord |
| `vraag_reeks` | tekst | `{"max": 2}` | meldt reeksen van meer dan `max` vraagzinnen achter elkaar |
| `intro_start_vraag` | intro | `{}` | alleen actief als de titel zelf een vraag is |
| `intro_start_ja_nee` | intro | `{}` | kijkt of de eerste zin met ja of nee begint |

## Scopes

| scope | wat de check binnenkrijgt |
|---|---|
| `titel` | het titelveld |
| `intro` | het introveld |
| `kop` | elke tussenkop apart |
| `tekst` | titel + intro + hoofdtekst, zonder de tussenkoppen |
| `alles` | idem, mét de tussenkoppen |

## Een regel toevoegen

```sql
insert into public.schrijfwijzer_regel
  (id, titel, categorie, hoofdstuk, soort, bron, scope, type, parameters, uitleg, volgorde, regelset_versie)
values
  ('mijn-regel', 'Korte naam van de bevinding', 'Categorie', 'Begrijpelijkheid', 'controle',
   'Schrijfwijzer NWW - hoofdstuk > paragraaf', 'tekst', 'verboden_woorden',
   '{"woorden": ["voorbeeld"], "alternatief": "beter woord"}',
   'Uitleg die de redacteur te zien krijgt.', 500, 'NWW-2026-09');
```

Een regel tijdelijk uitzetten: `update public.schrijfwijzer_regel set actief = false where id = '...';`

## Let op bij nieuwe controleregels

Een controle die te vaak onterecht afgaat, is schadelijker dan een controle die ontbreekt:
redacteuren gaan meldingen dan wegklikken. Twee voorbeelden waar daarom bewust van de letter
van de schrijfwijzer is afgeweken:

- **negatieve taal** — de schrijfwijzer noemt ook het woord *niet*. Dat is niet als controle
  opgenomen, omdat het te vaak legitiem is. Het staat wel in de uitleg en in de prompt.
- **getallen als cijfer** — *vijf* in plaats van *5* is niet als controle opgenomen, omdat
  vaste begrippen (*een van de*, *tweedehands*) dan onterecht zouden afgaan. Dit is een richtlijn.
