-- =========================================================================
-- CANDIDAX — Migration additive : organisations multi-utilisateurs
-- =========================================================================
-- À exécuter APRÈS les 3 scripts précédents, de la même façon :
-- SQL Editor → New query → coller → Run.
--
-- Permet à une entreprise d'avoir plusieurs recruteurs (Owner + membres
-- invités) qui partagent les mêmes offres, candidatures et abonnement.
-- =========================================================================

alter table profiles add column if not exists org_id text;
alter table profiles add column if not exists org_role text default 'owner' check (org_role in ('owner','recruteur'));

-- Met à jour le trigger de création de profil pour inclure org_id / org_role
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role, country, city, phone, org_id, org_role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'candidat'),
    new.raw_user_meta_data->>'country',
    new.raw_user_meta_data->>'city',
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'org_id', new.email),
    coalesce(new.raw_user_meta_data->>'org_role', 'owner')
  );
  return new;
end;
$$ language plpgsql security definer;

-- Codes d'invitation permettant à un membre de rejoindre une organisation.
create table if not exists org_invites (
  id bigint generated always as identity primary key,
  org_id text not null,
  code text not null unique,
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table org_invites enable row level security;

create policy "Un code est lisible par tous (nécessaire pour rejoindre)"
  on org_invites for select
  using (true);

create policy "Un membre de l'organisation peut créer un code pour SON organisation"
  on org_invites for insert
  with check (
    org_id in (select org_id from profiles where id = auth.uid())
  );

create policy "Un membre de l'organisation peut révoquer un code de SON organisation"
  on org_invites for delete
  using (
    org_id in (select org_id from profiles where id = auth.uid())
  );

-- Dénormalise l'organisation propriétaire sur chaque offre, pour que toute
-- l'équipe (pas seulement le créateur) voie les mêmes offres et candidats.
alter table offers add column if not exists org_id text;
