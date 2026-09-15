-- =============================================================================
-- Eén account toegang geven (of weer intrekken)
-- =============================================================================
-- Draai dit in de SQL Editor NADAT je de gebruiker in het dashboard hebt
-- aangemaakt (Authentication → Users → Add user → Auto Confirm User aan).
--
-- Pas alleen het e-mailadres aan. Zet hier geen wachtwoorden in.
-- =============================================================================

-- --- Toegang geven -----------------------------------------------------------
insert into public.toegestane_gebruiker (user_id, email, rol)
select u.id, u.email, 'redacteur'
from auth.users u
where u.email = 'toegestaan.redacteur@example.com'
on conflict (user_id) do update set actief = true;

-- --- Toegang intrekken zonder het account te verwijderen ----------------------
-- update public.toegestane_gebruiker
--    set actief = false
--  where email = 'toegestaan.redacteur@example.com';

-- --- Controle: wie staat er op de lijst? -------------------------------------
select t.email, t.rol, t.actief, t.aangemaakt_op
from public.toegestane_gebruiker t
order by t.aangemaakt_op;

-- --- Controle: welke accounts bestaan er, en staan ze op de lijst? -----------
select u.email                                    as account,
       (t.user_id is not null and t.actief)       as heeft_toegang
from auth.users u
left join public.toegestane_gebruiker t on t.user_id = u.id
order by u.created_at;
