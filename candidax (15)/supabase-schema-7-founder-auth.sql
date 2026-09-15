-- =========================================================================
-- CANDIDAX — Migration additive : vraie authentification fondateur
-- =========================================================================
-- À exécuter APRÈS les 6 scripts précédents, de la même façon :
-- SQL Editor → New query → coller → Run.
--
-- Remplace le mot de passe fondateur local (facilement contournable
-- côté navigateur) par un vrai compte CANDIDAX marqué comme fondateur.
-- Corrige aussi la policy trop permissive posée dans le script 6, qui
-- autorisait n'importe qui à modifier le profil de n'importe qui.
-- =========================================================================

alter table profiles add column if not exists is_founder boolean not null default false;

-- Supprime la policy trop permissive du script 6
drop policy if exists "Mise a jour large (revue fondateur, MVP)" on profiles;

-- Remplacée par une policy correcte : un utilisateur peut toujours
-- modifier son propre profil (déjà couvert par la policy existante
-- "Un utilisateur modifie son propre profil"), et un compte marqué
-- is_founder peut modifier N'IMPORTE QUEL profil (nécessaire pour
-- approuver les vérifications, gérer les comptes, etc.)
create policy "Le fondateur peut modifier n'importe quel profil"
  on profiles for update
  using (
    exists (select 1 from profiles p where p.id = auth.uid() and p.is_founder = true)
  );

-- =========================================================================
-- ÉTAPE MANUELLE OBLIGATOIRE APRÈS CE SCRIPT :
-- Remplace l'email ci-dessous par le TIEN (celui avec lequel tu vas te
-- connecter à l'espace fondateur), puis exécute cette ligne seul(e) :
--
--   update profiles set is_founder = true where email = 'ton-email@exemple.com';
--
-- Si ce compte n'existe pas encore, inscris-toi d'abord normalement sur
-- CANDIDAX (rôle "Entreprise" par exemple) avec cet email, PUIS exécute
-- la ligne ci-dessus.
-- =========================================================================
