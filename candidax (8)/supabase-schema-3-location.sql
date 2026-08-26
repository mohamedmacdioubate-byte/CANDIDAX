-- =========================================================================
-- CANDIDAX — Migration additive : pays, ville, téléphone
-- =========================================================================
-- À exécuter APRÈS supabase-schema.sql et supabase-schema-2-contact.sql,
-- de la même façon : SQL Editor → New query → coller → Run.
--
-- Ajoute le pays, la ville et le téléphone renseignés à l'inscription
-- (candidat comme entreprise). Utilisés pour :
--   - n'afficher à un candidat que les offres d'entreprises de son pays
--   - permettre au fondateur de voir pays/ville/téléphone de tous les comptes
--   - permettre à une entreprise de voir la ville et le téléphone d'un
--     candidat sur son profil
-- =========================================================================

alter table profiles add column if not exists country text;
alter table profiles add column if not exists city text;
alter table profiles add column if not exists phone text;

-- Met à jour le trigger de création de profil pour inclure ces 3 champs
-- (envoyés depuis le formulaire d'inscription via options.data)
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role, country, city, phone)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'candidat'),
    new.raw_user_meta_data->>'country',
    new.raw_user_meta_data->>'city',
    new.raw_user_meta_data->>'phone'
  );
  return new;
end;
$$ language plpgsql security definer;

-- Le pays de l'entreprise, dénormalisé sur chaque offre publiée, pour
-- filtrer les offres visibles par un candidat selon son propre pays.
alter table offers add column if not exists company_country text;
