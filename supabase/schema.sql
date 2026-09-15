-- =============================================================================
-- Redactiehulp — toegangsregels in Supabase
-- =============================================================================
-- Plak dit hele bestand in de SQL Editor van je Supabase-project en voer het uit.
-- Het script is idempotent: je mag het meerdere keren draaien.
--
-- Uitgangspunten:
--   * Registratie staat UIT in de Auth-instellingen (dat doe je in het dashboard).
--   * Toegang wordt hier afgedwongen, niet in de frontend.
--   * Alle tabellen hebben RLS aan met expliciete policies.
--   * Alleen lezen is toegestaan via de publieke (anon) sleutel; schrijven doe
--     je in het dashboard, dus niet vanuit de app.
--   * Alle inhoud hieronder is FICTIEF. Geen echte NWW-schrijfwijzer, geen
--     echte persoonsgegevens.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Allowlist: wie mag er binnen?
-- -----------------------------------------------------------------------------
-- Een account in auth.users is niet genoeg. Pas als er hier een actieve rij
-- staat, geven de policies hieronder gegevens vrij. Zo is "niet-toegestaan"
-- een echte toestand in de database en niet een verborgen knop.

create table if not exists public.toegestane_gebruiker (
  user_id       uuid primary key references auth.users (id) on delete cascade,
  email         text        not null,
  rol           text        not null default 'redacteur',
  actief        boolean     not null default true,
  aangemaakt_op timestamptz not null default now()
);

comment on table public.toegestane_gebruiker is
  'Allowlist. Alleen accounts met een actieve rij hier krijgen toegang tot afgeschermde gegevens.';

alter table public.toegestane_gebruiker enable row level security;

-- Een ingelogde gebruiker mag uitsluitend zijn eigen rij zien.
-- Niemand kan via de app de allowlist lezen, aanvullen of wijzigen.
drop policy if exists "eigen allowlist-rij lezen" on public.toegestane_gebruiker;
create policy "eigen allowlist-rij lezen"
  on public.toegestane_gebruiker
  for select
  to authenticated
  using (user_id = (select auth.uid()));

-- Geen insert-, update- of delete-policy: die acties zijn dus geweigerd.
revoke insert, update, delete on public.toegestane_gebruiker from anon, authenticated;


-- -----------------------------------------------------------------------------
-- 2. Helperfunctie: staat de huidige gebruiker op de allowlist?
-- -----------------------------------------------------------------------------
-- security definer omdat de policy op toegestane_gebruiker anders in de weg
-- zit; search_path = '' dwingt af dat alles hieronder volledig gekwalificeerd is.

create or replace function public.heeft_toegang()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.toegestane_gebruiker t
    where t.user_id = (select auth.uid())
      and t.actief
  );
$$;

comment on function public.heeft_toegang() is
  'True als de ingelogde gebruiker een actieve rij heeft in public.toegestane_gebruiker.';

revoke execute on function public.heeft_toegang() from public, anon;
grant   execute on function public.heeft_toegang() to authenticated;


-- -----------------------------------------------------------------------------
-- 3. De afgeschermde inhoud: de regelset
-- -----------------------------------------------------------------------------
-- Dit is spoor Regelkennis. Zonder toegang tot deze tabel heeft de app geen
-- regels en kan hij niets controleren. Dat is het punt: de login beschermt
-- inhoud, geen schermpje.

create table if not exists public.schrijfwijzer_regel (
  id              text    primary key,
  titel           text    not null,
  categorie       text    not null,
  bron            text    not null,
  scope           text    not null check (scope in ('titel', 'intro', 'tekst', 'kop')),
  type            text    not null check (type in (
                    'max_tekens', 'geen_leestekens', 'max_woorden',
                    'max_woorden_per_zin', 'verboden_woord', 'max_woorden_kop')),
  parameters      jsonb   not null default '{}'::jsonb,
  uitleg          text    not null default '',
  volgorde        integer not null default 0,
  actief          boolean not null default true,
  regelset_versie text    not null default 'fictief-v1'
);

comment on table public.schrijfwijzer_regel is
  'Regelset voor de regelcheck. Nu gevuld met FICTIEVE voorbeeldregels, niet met de NWW-schrijfwijzer.';

alter table public.schrijfwijzer_regel enable row level security;

-- Lezen mag alleen als je bent ingelogd EN op de allowlist staat.
drop policy if exists "regels lezen voor toegestane gebruikers" on public.schrijfwijzer_regel;
create policy "regels lezen voor toegestane gebruikers"
  on public.schrijfwijzer_regel
  for select
  to authenticated
  using (public.heeft_toegang());

-- Geen enkele schrijf-policy: aanmaken, wijzigen en verwijderen gebeurt in het
-- dashboard, niet vanuit de browser.
revoke insert, update, delete on public.schrijfwijzer_regel from anon, authenticated;


-- -----------------------------------------------------------------------------
-- 4. Fictieve regelset als testinhoud
-- -----------------------------------------------------------------------------
-- Dezelfde voorbeeldregels als in index.html. Uitdrukkelijk NIET de echte
-- schrijfwijzer: die laad je later zelf, als de toegang bewezen werkt.

insert into public.schrijfwijzer_regel
  (id, titel, categorie, bron, scope, type, parameters, uitleg, volgorde) values
  ('titel-lengte',    'Titel te lang',                        'Vindbaarheid (voorbeeld)', 'Voorbeeldregel — geen echte schrijfwijzer', 'titel', 'max_tekens',          '{"max": 60}'::jsonb,                                       'Richtlijn: maximaal 60 tekens.',                    10),
  ('titel-leesteken', 'Titel bevat een leesteken',            'Vindbaarheid (voorbeeld)', 'Voorbeeldregel — geen echte schrijfwijzer', 'titel', 'geen_leestekens',     '{"toegestaan_slot": "?"}'::jsonb,                          'Geen leestekens in de titel, behalve een vraagteken aan het eind.', 20),
  ('intro-lengte',    'Introductie te lang',                  'Structuur (voorbeeld)',    'Voorbeeldregel — geen echte schrijfwijzer', 'intro', 'max_woorden',         '{"max": 40}'::jsonb,                                       'Richtlijn: maximaal 40 woorden.',                   30),
  ('zin-lengte',      'Zin te lang',                          'Leesbaarheid (voorbeeld)', 'Voorbeeldregel — geen echte schrijfwijzer', 'tekst', 'max_woorden_per_zin', '{"max": 18}'::jsonb,                                       'Richtlijn: maximaal 18 woorden per zin.',           40),
  ('voorbeeldwoord',  'Vermijd het voorbeeldwoord "uiteraard"','Stijl (voorbeeld)',       'Voorbeeldregel — geen echte schrijfwijzer', 'tekst', 'verboden_woord',      '{"woord": "uiteraard", "alternatief": "natuurlijk"}'::jsonb, 'Gebruik in deze demo liever "natuurlijk".',        50),
  ('kop-lengte',      'Tussenkop te lang',                    'Structuur (voorbeeld)',    'Voorbeeldregel — geen echte schrijfwijzer', 'kop',   'max_woorden_kop',     '{"max": 6}'::jsonb,                                        'Richtlijn: maximaal 6 woorden per tussenkop.',      60)
on conflict (id) do update set
  titel      = excluded.titel,
  categorie  = excluded.categorie,
  bron       = excluded.bron,
  scope      = excluded.scope,
  type       = excluded.type,
  parameters = excluded.parameters,
  uitleg     = excluded.uitleg,
  volgorde   = excluded.volgorde;


-- -----------------------------------------------------------------------------
-- 5. Controle: staat alles aan?
-- -----------------------------------------------------------------------------
-- Draai dit als laatste. Verwacht: beide tabellen rls_aan = true, en per tabel
-- het aantal policies dat hierboven is aangemaakt.

select
  c.relname                                as tabel,
  c.relrowsecurity                         as rls_aan,
  (select count(*) from pg_policies p
    where p.schemaname = 'public' and p.tablename = c.relname) as aantal_policies
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('toegestane_gebruiker', 'schrijfwijzer_regel')
order by c.relname;
