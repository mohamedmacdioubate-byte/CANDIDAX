-- =========================================================================
-- CANDIDAX — Migration additive : langue préférée
-- =========================================================================
-- À exécuter APRÈS les 7 scripts précédents.
--
-- Stocke la langue de l'interface pour chaque utilisateur. Choisie
-- automatiquement selon le pays à l'inscription, modifiable ensuite
-- dans les paramètres du compte.
-- =========================================================================

alter table profiles add column if not exists language text not null default 'fr'
  check (language in ('fr','en','zh','it','de','ja','ko'));

-- Met à jour le trigger de création de profil pour inclure la langue
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role, country, city, phone, org_id, org_role, language)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'candidat'),
    new.raw_user_meta_data->>'country',
    new.raw_user_meta_data->>'city',
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'org_id', new.email),
    coalesce(new.raw_user_meta_data->>'org_role', 'owner'),
    coalesce(new.raw_user_meta_data->>'language', 'fr')
  );
  return new;
end;
$$ language plpgsql security definer;
