-- =========================================================================
-- CANDIDAX — Migration additive : photos de profil & Candidax Verified
-- =========================================================================
-- À exécuter APRÈS les 5 scripts précédents, de la même façon :
-- SQL Editor → New query → coller → Run.
-- =========================================================================

-- Photo de profil (candidat) ou logo (entreprise)
alter table profiles add column if not exists avatar_url text;

-- Statut de vérification Candidax Verified + note décrivant ce qui est
-- demandé (diplôme, certification, etc.). "none" = jamais demandé,
-- "pending" = demande envoyée par l'utilisateur, "verified" = approuvé
-- par l'équipe CANDIDAX après revue humaine.
alter table profiles add column if not exists verified_status text not null default 'none'
  check (verified_status in ('verified','pending','none'));
alter table profiles add column if not exists verification_note text;

-- Un utilisateur peut demander une vérification pour lui-même (passer à
-- "pending"), c'est le comportement normal. La policy générale existante
-- ("Un utilisateur modifie son propre profil") couvre déjà ce cas.
--
-- NOTE IMPORTANTE — modèle de confiance de cette version :
-- L'espace fondateur de CANDIDAX utilise un mot de passe local (stocké
-- dans le navigateur), pas un vrai compte Supabase authentifié. La
-- policy ci-dessous autorise donc la mise à jour du profil de
-- N'IMPORTE QUI, pour que le bouton Approuver/Refuser du fondateur
-- fonctionne. C'est une simplification assumée pour cette étape du
-- produit (comme le mot de passe fondateur lui-même) : elle devra être
-- remplacée par une vraie authentification d'administrateur avant une
-- mise en production à plus grande échelle.
create policy "Mise a jour large (revue fondateur, MVP)"
  on profiles for update
  using (true)
  with check (true);

-- -------------------------------------------------------------------------
-- STOCKAGE DES PHOTOS (Supabase Storage)
-- -------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "Photos de profil lisibles par tous"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Un utilisateur depose sa propre photo (dossier = son id)"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Un utilisateur remplace sa propre photo"
  on storage.objects for update
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Un utilisateur supprime sa propre photo"
  on storage.objects for delete
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
