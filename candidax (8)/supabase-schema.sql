-- =========================================================================
-- HIRE RECRUT-AI — Schéma de base de données (Étape 1 : fondations)
-- =========================================================================
-- À exécuter dans Supabase : Project → SQL Editor → New query → coller
-- tout ce fichier → Run.
--
-- Ce script crée :
--   1. profiles       (comptes candidat / entreprise, lié à l'authentification)
--   2. offers         (offres d'emploi)
--   3. applications   (candidatures)
--   4. payments       (historique des paiements)
--   5. notifications  (prêt pour l'étape suivante, pas encore utilisé)
--
-- Chaque table a la sécurité au niveau des lignes (RLS) activée : un
-- candidat ne peut voir que ses propres candidatures, une entreprise ne
-- peut voir que les candidatures reçues sur SES offres, etc.
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. PROFILS — étend les comptes gérés par Supabase Auth (auth.users)
-- -------------------------------------------------------------------------
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  name text not null,
  role text not null check (role in ('candidat','entreprise')),
  plan text not null default 'starter' check (plan in ('starter','pro','premium')),
  plan_expires_at timestamptz,
  trial_started_at timestamptz,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "Lecture publique des profils (nom affiché sur les offres)"
  on profiles for select
  using (true);

create policy "Un utilisateur modifie son propre profil"
  on profiles for update
  using (auth.uid() = id);

-- Crée automatiquement une ligne "profiles" à chaque inscription
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, role)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'candidat')
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -------------------------------------------------------------------------
-- 2. OFFRES D'EMPLOI
-- -------------------------------------------------------------------------
create table if not exists offers (
  id bigint generated always as identity primary key,
  company_id uuid not null references profiles(id) on delete cascade,
  company_name text not null,
  title text not null,
  keywords jsonb not null default '[]',
  active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table offers enable row level security;

create policy "Offres actives visibles par tous, + les siennes pour l'entreprise"
  on offers for select
  using (active = true or company_id = auth.uid());

create policy "Une entreprise crée ses propres offres"
  on offers for insert
  with check (company_id = auth.uid());

create policy "Une entreprise modifie ses propres offres"
  on offers for update
  using (company_id = auth.uid());

create policy "Une entreprise supprime ses propres offres"
  on offers for delete
  using (company_id = auth.uid());

-- -------------------------------------------------------------------------
-- 3. CANDIDATURES
-- -------------------------------------------------------------------------
create table if not exists applications (
  id bigint generated always as identity primary key,
  offer_id bigint not null references offers(id) on delete cascade,
  candidate_id uuid not null references profiles(id) on delete cascade,
  cv_text text not null,
  submitted_at timestamptz not null default now()
);

alter table applications enable row level security;

create policy "Un candidat voit ses propres candidatures"
  on applications for select
  using (candidate_id = auth.uid());

create policy "Une entreprise voit les candidatures reçues sur ses offres"
  on applications for select
  using (offer_id in (select id from offers where company_id = auth.uid()));

create policy "Un candidat peut postuler"
  on applications for insert
  with check (candidate_id = auth.uid());

-- -------------------------------------------------------------------------
-- 4. PAIEMENTS (historique simple)
-- -------------------------------------------------------------------------
create table if not exists payments (
  id bigint generated always as identity primary key,
  account_id uuid not null references profiles(id) on delete cascade,
  plan text not null,
  amount numeric,
  paid_at timestamptz not null default now()
);

alter table payments enable row level security;

create policy "Un utilisateur voit ses propres paiements"
  on payments for select
  using (account_id = auth.uid());

-- -------------------------------------------------------------------------
-- 5. NOTIFICATIONS — table prête pour l'étape suivante (pas encore branchée)
-- -------------------------------------------------------------------------
create table if not exists notifications (
  id bigint generated always as identity primary key,
  account_id uuid not null references profiles(id) on delete cascade,
  type text not null,
  message text not null,
  link text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table notifications enable row level security;

create policy "Un utilisateur voit ses propres notifications"
  on notifications for select
  using (account_id = auth.uid());

create policy "Un utilisateur marque ses notifications comme lues"
  on notifications for update
  using (account_id = auth.uid());

-- =========================================================================
-- Fin du script. Si tout s'exécute sans erreur, les 5 tables apparaissent
-- dans Supabase → Table Editor.
-- =========================================================================
