/* =============================================================================
   Publieke Supabase-projectconfiguratie
   =============================================================================
   Hier horen ALLEEN deze twee waarden te staan. Beide zijn bedoeld om publiek
   te zijn: ze staan in elke browser die de app opent. Hun bescherming zijn de
   RLS-policies in de database, niet geheimhouding van deze sleutel.

   Hier hoort NOOIT in: je databasewachtwoord, een service-role key, een secret
   key of een access token. Die horen niet in de frontend en niet in GitHub.

   Waar vind je deze waarden?
     Supabase → jouw project → Project Settings → API Keys
       - Project URL          → hieronder bij url
       - anon / publishable   → hieronder bij anonKey
   ============================================================================= */

window.SUPABASE_CONFIG = {
  url:     "VUL_IN__https://<projectref>.supabase.co",
  anonKey: "VUL_IN__anon_of_publishable_key"
};
