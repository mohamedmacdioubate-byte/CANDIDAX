-- =========================================================================
-- CANDIDAX — Migration additive : Candidate Passport (profil public)
-- =========================================================================
-- À exécuter APRÈS les 4 scripts précédents, de la même façon :
-- SQL Editor → New query → coller → Run.
--
-- Permet à un candidat de rendre son profil consultable via une URL
-- publique (candidax.vercel.app/app.html?passport=<id>), sans compte
-- CANDIDAX requis pour le consulter. Désactivé par défaut (opt-in) :
-- rien n'est rendu public sans action explicite du candidat.
-- =========================================================================

alter table profiles add column if not exists headline text;
alter table profiles add column if not exists bio text;
alter table profiles add column if not exists skills text;
alter table profiles add column if not exists is_public boolean not null default false;

-- La policy de lecture publique existe déjà ("Lecture publique des
-- profils"), donc aucune policy RLS supplémentaire n'est nécessaire ici :
-- c'est le champ is_public, filtré côté application, qui décide de ce
-- qui est effectivement affiché sur une page passeport.
