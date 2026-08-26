-- =========================================================================
-- HIRE RECRUT-AI — Migration additive : colonne "contact"
-- =========================================================================
-- À exécuter APRÈS supabase-schema.sql, de la même façon :
-- SQL Editor → New query → coller → Run.
--
-- Ajoute le moyen de contact (WhatsApp ou email) que le candidat renseigne
-- dans son profil, visible par les entreprises qui étudient sa candidature.
-- =========================================================================

alter table profiles add column if not exists contact jsonb;
