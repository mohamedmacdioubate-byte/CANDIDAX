# CANDIDAX

Plateforme intelligente de recrutement : dépôt et tri de CV par points, pipeline de recrutement (Kanban), tests candidats, IA (matching, chatbot, extraction de CV), vivier de talents, profils publics partageables, et espace fondateur pour piloter les forfaits, l'IA et les vérifications.

Application statique (HTML/CSS/JS, un seul fichier par page), pensée pour être déployée sur **Vercel**, avec **Supabase** comme base de données et système d'authentification.

---

## 1. Structure du projet

| Fichier | Rôle |
|---|---|
| `index.html` | Page d'accueil publique (présentation, tarifs) |
| `app.html` | L'application entière (connexion, espace candidat, espace entreprise, espace fondateur) |
| `api/ai.js` | Fonction serverless Vercel — relaie les appels vers Anthropic/OpenAI sans exposer la clé API au navigateur |
| `sw.js` | Service Worker — permet l'installation en PWA et l'usage hors ligne |
| `manifest.json` | Métadonnées de l'application installable |
| `vercel.json` | Configuration des en-têtes HTTP |
| `supabase-schema*.sql` | Scripts de création/mise à jour de la base de données (voir §3) |
| `GUIDE-IA.md` | Notes détaillées sur la configuration de l'IA |

---

## 2. Déploiement sur Vercel

1. Dépose l'ensemble des fichiers de ce dossier à la racine de ton projet Vercel (pas de sous-dossier autour — `index.html` et `app.html` doivent être directement à la racine).
2. Déploie (import GitHub ou glisser-déposer).
3. Vérifie que `https://ton-domaine.vercel.app/` et `.../app.html` s'ouvrent correctement.

---

## 3. Base de données Supabase

Crée un projet sur [supabase.com](https://supabase.com), puis dans **SQL Editor → New query**, exécute **les 7 scripts ci-dessous, dans cet ordre exact** (un script à la fois, `Run`, attendre "Success" avant de passer au suivant) :

1. `supabase-schema.sql` — tables de base (profils, offres, candidatures, paiements)
2. `supabase-schema-2-contact.sql` — moyen de contact du candidat
3. `supabase-schema-3-location.sql` — pays / ville / téléphone
4. `supabase-schema-4-orgs.sql` — organisations multi-utilisateurs (équipe, codes d'invitation)
5. `supabase-schema-5-passport.sql` — Candidate Passport (profil public partageable)
6. `supabase-schema-6-verified-photos.sql` — photos de profil (Storage) + Candidax Verified
7. `supabase-schema-7-founder-auth.sql` — authentification fondateur sécurisée

### Connecter l'app à ce projet

Dans `app.html`, repère les lignes (recherche `SUPABASE_URL`) :

```js
var SUPABASE_URL = 'https://xxxxxxxxxxxx.supabase.co';
var SUPABASE_ANON_KEY = 'eyJ...';
```

Remplace-les par les valeurs de **Project Settings → API** de ton projet Supabase (**Project URL** et clé **anon public**).

### Authentification

Dans **Authentication → URL Configuration**, mets ton vrai domaine (pas `localhost`) :

- **Site URL** : `https://ton-domaine.vercel.app`
- **Redirect URLs** : `https://ton-domaine.vercel.app/**`

Sinon les liens de confirmation d'inscription par email pointeront vers `localhost` et ne fonctionneront pas.

---

## 4. Créer le compte fondateur

Le mot de passe fondateur n'est plus un simple mot de passe local : c'est un vrai compte CANDIDAX, marqué comme fondateur en base.

1. Inscris-toi normalement sur le site (rôle Entreprise ou Candidat, peu importe) avec l'email que tu veux utiliser comme fondateur.
2. Dans Supabase → SQL Editor, exécute (en remplaçant l'email) :
   ```sql
   update profiles set is_founder = true where email = 'ton-email@exemple.com';
   ```
3. Sur le site, clique le point discret en bas à droite de la page de connexion, entre cet email et son mot de passe.

---

## 5. Activer l'IA (optionnel)

Dans l'espace fondateur → **⚙️ Paramètres → Configuration IA** :

1. Choisis un fournisseur (Anthropic ou OpenAI).
2. Colle ta clé API (`console.anthropic.com` ou `platform.openai.com/api-keys`).
3. Clique **🧪 Tester la connexion**, puis **💾 Enregistrer**.
4. Dans **🧩 Forfaits & Fonctionnalités**, coche les fonctionnalités IA (Suggestions, Analyse CV, Chatbot, Ask Candidax) pour les forfaits qui doivent en bénéficier.

Sans clé API valide et sans crédit sur le compte Anthropic/OpenAI, les fonctionnalités IA restent invisibles pour les entreprises (pas d'erreur affichée, juste masquées).

Voir `GUIDE-IA.md` pour plus de détails.

---

## 6. Configurer le paiement

Dans l'espace fondateur → **💰 Paiement (Stripe/PayPal)** :

- Choisis Stripe ou PayPal comme moyen actif.
- Colle les liens de paiement pour chaque forfait (Starter, Pro, Premium).
- Règle la durée de l'essai gratuit et la durée des abonnements.

---

## 7. Mode hors ligne / installation

Le site est installable comme une application (bouton "Installer" visible sur la page d'accueil et dans l'application) et reste consultable hors ligne une fois visité en ligne au moins une fois. La connexion (authentification) nécessite toujours une connexion internet.

---

## 8. Limites connues de cette version

- **Emails automatiques et calendrier** (confirmation de candidature, relances, Google Calendar/Zoom) ne sont pas branchés : ça demande un service externe (SMTP/Resend, OAuth Google/Microsoft) que tu n'as pas encore configuré.
- **Retirer un membre d'une équipe** n'est pas encore possible (seulement inviter/lister).
- Le modèle de confiance de l'espace fondateur reste volontairement simple à ce stade (voir les commentaires dans `supabase-schema-7-founder-auth.sql`).
