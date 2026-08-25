# 🤖 GUIDE — Configurer l'IA sur CANDIDAX

## Pourquoi cette étape ?
L'IA (chatbot, suggestions de mots-clés) nécessite une clé API d'un fournisseur IA
pour fonctionner. Vous pouvez désormais choisir **le fournisseur que vous voulez**
(Anthropic, OpenAI, ou un autre à l'avenir) directement depuis l'application —
plus besoin de toucher au code.

---

## ÉTAPE 1 — Ouvrir la Configuration IA

1. Connectez-vous en tant que **Fondateur**
2. Allez dans **⚙️ Paramètres**
3. Dans le bloc **🤖 Configuration IA**, choisissez votre fournisseur dans le menu déroulant :
   - **Anthropic (Claude)**
   - **OpenAI (GPT)**

---

## ÉTAPE 2 — Obtenir une clé API

### Option A — Anthropic (Claude)
1. Allez sur **https://console.anthropic.com**
2. Créez un compte (gratuit)
3. **API Keys** → **Create Key**
4. Copiez la clé (format : `sk-ant-api03-xxxxx...`)

### Option B — OpenAI (GPT)
1. Allez sur **https://platform.openai.com/api-keys**
2. Créez un compte (gratuit)
3. **Create new secret key**
4. Copiez la clé (format : `sk-proj-xxxxx...` ou `sk-xxxxx...`)

⚠️ Gardez votre clé secrète — ne la partagez jamais.

> **Coût** : chaque fournisseur facture à l'usage. Le coût reste très faible
> pour l'utilisation de CANDIDAX (quelques centimes par conversation).

---

## ÉTAPE 3 — Enregistrer la clé dans l'application

1. Collez votre clé dans le champ **Clé API**
2. Vérifiez/ajustez le champ **Modèle** (un modèle par défaut est déjà proposé,
   mais vous pouvez taper n'importe quel identifiant de modèle proposé par
   votre fournisseur — par exemple `claude-sonnet-4-6` ou `gpt-4o`)
3. Cliquez **🧪 Tester la connexion** pour vérifier que tout fonctionne
4. Une fois validé, cliquez **💾 Enregistrer**

C'est tout — pas besoin de redéployer le site ni de toucher à Vercel.

---

## ✅ Tester que l'IA fonctionne

1. Créez une nouvelle offre → le bouton **"✦ Générer des suggestions IA"** doit fonctionner
2. Ouvrez le chatbot (forfait Premium) → posez une question

---

## FONCTIONNALITÉS IA disponibles

Depuis la mise à jour **Forfaits & Fonctionnalités**, ce n'est plus figé dans le
code : c'est vous, le fondateur, qui décidez quelles fonctionnalités (Suggestions IA,
Analyse CV IA, Chatbot IA, multi-pays, statistiques avancées) sont incluses dans
chaque forfait — Starter, Pro ou Premium.

1. Connectez-vous en tant que **Fondateur**
2. Allez dans **🧩 Forfaits & Fonctionnalités**
3. Cochez/décochez librement chaque fonctionnalité pour chaque forfait, et ajustez
   les prix et les limites (offres actives, CV/mois)
4. Cliquez **Enregistrer les forfaits**

Les changements s'appliquent immédiatement à la page de paiement de l'application
et à la page publique (candidax.com).

---

## Méthode alternative — variables d'environnement Vercel (avancé)

Si vous préférez ne pas stocker la clé dans l'application (par exemple pour une
équipe technique qui gère le déploiement), vous pouvez toujours définir une
variable d'environnement côté Vercel : `ANTHROPIC_API_KEY` ou `OPENAI_API_KEY`.
Si aucune clé n'est configurée dans l'application, la fonction IA utilisera
automatiquement celle définie dans Vercel.

1. Vercel → votre projet → **Settings → Environment Variables**
2. Ajoutez : Key : `ANTHROPIC_API_KEY` (ou `OPENAI_API_KEY`) → Value : votre clé → **Save**
3. Onglet **Deployments** → menu **⋯** du dernier déploiement → **Redeploy**

---

## En cas de problème

Si l'IA répond "Erreur" :
1. Vérifiez que la clé API est correcte dans ⚙️ Paramètres → Configuration IA
2. Vérifiez que vous avez des crédits chez votre fournisseur IA
3. Cliquez **🧪 Tester la connexion** pour un diagnostic précis

---

*Ce guide concerne uniquement la configuration technique. Pour toute autre aide,
utilisez le bouton Support dans l'application.*
