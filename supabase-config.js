/* =============================================================================
   Publieke Supabase-projectconfiguratie
   =============================================================================
   Hier horen ALLEEN deze twee waarden te staan. Beide zijn bedoeld om publiek
   te zijn: ze staan in elke browser die de app opent. Hun bescherming zijn de
   RLS-policies in de database, niet geheimhouding van deze sleutel.

   Hier hoort NOOIT in: je databasewachtwoord, een service-role key, een secret
   key of een access token. Die horen niet in de frontend en niet in GitHub.

   De sleutel hieronder is de publishable key van het project. Werkt er iets
   niet, dan kun je hem vervangen door de legacy anon key uit
   Supabase → Project Settings → API Keys. Beide zijn publiek en werken.
   ============================================================================= */

window.SUPABASE_CONFIG = {
  url:     "https://wmqketplyfscvcxxpnmb.supabase.co",
  anonKey: "sb_publishable_pCH-CbkAUydS3lw_u4eH7g_KUx_L3Gz"
};
