-- =============================================================================
-- Iemand toegang geven, of toegang intrekken
-- =============================================================================
-- De allowlist staat op e-mailadres en mag vooruit worden ingevuld: het account
-- hoeft nog niet te bestaan. Sterker nog, zonder rij hier kan het account niet
-- eens worden aangemaakt — de trigger beperk_registratie_tot_allowlist weigert
-- dat, ook vanuit het dashboard.
--
-- Zet hier nooit wachtwoorden in.
-- =============================================================================

-- --- Iemand toegang geven ----------------------------------------------------
insert into public.toegestane_gebruiker (email, rol, actief)
values ('nieuwe.redacteur@example.com', 'redacteur', true)
on conflict (email) do update set actief = true, rol = excluded.rol;

-- --- Een account laten bestaan maar GEEN gegevens geven (testgeval) ----------
-- insert into public.toegestane_gebruiker (email, rol, actief)
-- values ('geen.toegang@example.com', 'tester', false)
-- on conflict (email) do update set actief = false;

-- --- Toegang intrekken zonder het account te verwijderen ---------------------
-- update public.toegestane_gebruiker set actief = false
--  where email = 'nieuwe.redacteur@example.com';

-- --- Controle ----------------------------------------------------------------
select t.email,
       t.rol,
       t.actief                                          as mag_bij_de_gegevens,
       case when t.user_id is null then 'account bestaat nog niet'
            else 'gekoppeld aan account' end             as status
from public.toegestane_gebruiker t
order by t.email;
