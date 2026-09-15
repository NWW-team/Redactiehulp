-- =============================================================================
-- Redactiehulp — toegangsregels in Supabase
-- =============================================================================
-- Deze staat is op 15 sep 2026 toegepast op project wmqketplyfscvcxxpnmb via
-- de Supabase-koppeling (migraties: toegangsregels_redactiehulp en
-- registratie_beperken_en_allowlist_koppelen). Dit bestand is de leesbare versie
-- ervan; opnieuw draaien mag, het is idempotent.
--
-- Opzet:
--   * De allowlist staat op e-mailadres, zodat toegang vooraf geregeld kan worden.
--   * Een rij in de allowlist bepaalt of een account mag BESTAAN (registratie).
--   * actief = true bepaalt of dat account bij de GEGEVENS mag.
--   * Autorisatie gaat op user_id, niet op e-mail: een e-mailwijziging geeft
--     dus nooit toegang tot andermans rij.
--   * Regels zijn 'controle' (automatisch getoetst) of 'richtlijn' (gaat mee
--     in de prompt). Zie supabase/regeltypen.md.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Allowlist
-- -----------------------------------------------------------------------------
create table if not exists public.toegestane_gebruiker (
  email         text primary key,
  user_id       uuid unique references auth.users (id) on delete set null,
  rol           text        not null default 'redacteur',
  actief        boolean     not null default true,
  aangemaakt_op timestamptz not null default now()
);

alter table public.toegestane_gebruiker enable row level security;

drop policy if exists "eigen allowlist-rij lezen" on public.toegestane_gebruiker;
create policy "eigen allowlist-rij lezen"
  on public.toegestane_gebruiker
  for select
  to authenticated
  using (user_id = (select auth.uid()));

revoke insert, update, delete on public.toegestane_gebruiker from anon, authenticated;


-- -----------------------------------------------------------------------------
-- 2. Autorisatiecheck
-- -----------------------------------------------------------------------------
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

revoke execute on function public.heeft_toegang() from public, anon;
grant   execute on function public.heeft_toegang() to authenticated;


-- -----------------------------------------------------------------------------
-- 3. Registratie beperken — in de database, niet in de interface
-- -----------------------------------------------------------------------------
-- Werkt ook als "Allow new users to sign up" in het dashboard aan zou staan,
-- en ook voor accounts die via het dashboard worden aangemaakt.

create or replace function public.registratie_beperken()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.toegestane_gebruiker t
    where lower(t.email) = lower(new.email)
  ) then
    raise exception 'Registratie geweigerd: % staat niet op de toegangslijst.', new.email
      using errcode = 'check_violation';
  end if;
  return new;
end;
$$;

drop trigger if exists beperk_registratie_tot_allowlist on auth.users;
create trigger beperk_registratie_tot_allowlist
  before insert on auth.users
  for each row execute function public.registratie_beperken();

-- Koppelt de allowlist-rij automatisch aan het account zodra het bestaat.
create or replace function public.allowlist_koppelen()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.toegestane_gebruiker
     set user_id = new.id
   where lower(email) = lower(new.email)
     and user_id is distinct from new.id;
  return new;
end;
$$;

drop trigger if exists koppel_allowlist_aan_account on auth.users;
create trigger koppel_allowlist_aan_account
  after insert on auth.users
  for each row execute function public.allowlist_koppelen();

revoke execute on function public.registratie_beperken() from public, anon, authenticated;
revoke execute on function public.allowlist_koppelen()  from public, anon, authenticated;


-- -----------------------------------------------------------------------------
-- 4. De afgeschermde inhoud: de regelset
-- -----------------------------------------------------------------------------
create table if not exists public.schrijfwijzer_regel (
  id              text    primary key,
  titel           text    not null,
  categorie       text    not null,
  hoofdstuk       text    not null default 'Overig',
  soort           text    not null default 'controle'
                    check (soort in ('controle', 'richtlijn')),
  bron            text    not null,
  scope           text    not null check (scope in ('titel', 'intro', 'tekst', 'kop', 'alles')),
  type            text    not null check (type in (
                    'geen',
                    'max_tekens', 'geen_leestekens', 'max_woorden',
                    'max_woorden_per_zin', 'max_woorden_per_alinea', 'max_woorden_kop',
                    'verboden_woorden', 'kop_lidwoord', 'lijdende_vorm',
                    'vraag_reeks', 'regex_verboden',
                    'intro_start_vraag', 'intro_start_ja_nee')),
  parameters      jsonb   not null default '{}'::jsonb,
  uitleg          text    not null default '',
  volgorde        integer not null default 0,
  actief          boolean not null default true,
  regelset_versie text    not null default 'onbekend'
);

alter table public.schrijfwijzer_regel enable row level security;

drop policy if exists "regels lezen voor toegestane gebruikers" on public.schrijfwijzer_regel;
create policy "regels lezen voor toegestane gebruikers"
  on public.schrijfwijzer_regel
  for select
  to authenticated
  using (public.heeft_toegang());

revoke insert, update, delete on public.schrijfwijzer_regel from anon, authenticated;


-- -----------------------------------------------------------------------------
-- 5. De inhoud van de regelset staat NIET in deze repo
-- -----------------------------------------------------------------------------
-- De tabel is gevuld met de echte NWW-schrijfwijzer (regelset_versie NWW-2026-09):
-- 22 controleregels en 43 richtlijnen. Die inhoud is intern en staat daarom
-- alleen in de database, niet in deze openbare repo.
--
-- Zie supabase/regeltypen.md voor de structuur en voor hoe je een regel toevoegt.
