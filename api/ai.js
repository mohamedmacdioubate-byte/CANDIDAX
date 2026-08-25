// Vercel Serverless Function — Relais sécurisé vers l'API du fournisseur IA choisi
// Emplacement : /api/ai.js → accessible automatiquement à l'URL /api/ai (zéro config Vercel)
//
// Supporte plusieurs fournisseurs : Anthropic (Claude) et OpenAI (GPT).
// Le fondateur choisit le fournisseur + la clé + le modèle depuis
// ⚙️ Paramètres → Configuration IA dans l'application.
//
// Body attendu (JSON) :
// {
//   provider: 'anthropic' | 'openai',
//   apiKey:   'sk-...'        (optionnel — sinon on utilise la variable d'env Vercel)
//   model:    'claude-sonnet-4-6' | 'gpt-4o-mini' | ... (texte libre)
//   system:   'instructions système...',
//   messages: [{role:'user', content:'...'}],
//   max_tokens: 1500
// }
//
// La réponse est toujours normalisée au format Anthropic :
// { content: [ { type:'text', text: '...' } ] }
// afin que le code front-end n'ait rien à changer selon le fournisseur.

async function callAnthropic({ apiKey, model, system, messages, max_tokens }) {
  const r = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01'
    },
    body: JSON.stringify({
      model: model || 'claude-sonnet-4-6',
      max_tokens: max_tokens || 1500,
      system: system || '',
      messages: messages || []
    })
  });
  const json = await r.json();
  if (json.error) {
    return { error: { message: json.error.message || 'Erreur Anthropic' } };
  }
  // Déjà au bon format : { content: [{type:'text', text:'...'}] }
  return json;
}

async function callOpenAI({ apiKey, model, system, messages, max_tokens }) {
  const oaMessages = [];
  if (system) oaMessages.push({ role: 'system', content: system });
  (messages || []).forEach((m) => oaMessages.push({ role: m.role, content: m.content }));

  const r = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey
    },
    body: JSON.stringify({
      model: model || 'gpt-4o-mini',
      max_tokens: max_tokens || 1500,
      messages: oaMessages
    })
  });
  const json = await r.json();
  if (json.error) {
    return { error: { message: json.error.message || 'Erreur OpenAI' } };
  }
  const text = (json.choices && json.choices[0] && json.choices[0].message)
    ? json.choices[0].message.content
    : '';
  // Normalisation au format Anthropic pour que le front-end reste identique
  return { content: [{ type: 'text', text: text }] };
}

const PROVIDERS = {
  anthropic: { call: callAnthropic, envKey: 'ANTHROPIC_API_KEY' },
  openai: { call: callOpenAI, envKey: 'OPENAI_API_KEY' }
};

export default async function handler(req, res) {
  // CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: { message: 'Méthode non autorisée' } });
  }

  // Vercel parse déjà le JSON automatiquement dans req.body, mais on sécurise
  // au cas où il arriverait encore sous forme de texte brut.
  let body = req.body;
  if (typeof body === 'string') {
    try { body = JSON.parse(body); }
    catch (e) { return res.status(400).json({ error: { message: 'Corps de requête invalide' } }); }
  }
  body = body || {};

  const providerKey = (body.provider || 'anthropic').toLowerCase();
  const provider = PROVIDERS[providerKey];

  if (!provider) {
    return res.status(400).json({ error: { message: 'Fournisseur IA inconnu : ' + providerKey } });
  }

  // Priorité à la clé envoyée par le front-end (configurée dans l'app),
  // sinon on retombe sur la variable d'environnement Vercel (méthode alternative).
  const apiKey = body.apiKey || process.env[provider.envKey];

  if (!apiKey) {
    return res.status(500).json({
      error: {
        message: 'Clé API ' + providerKey + ' non configurée. Ajoutez-la dans ⚙️ Paramètres → Configuration IA, ou dans les variables d\'environnement Vercel (' + provider.envKey + ').'
      }
    });
  }

  try {
    const result = await provider.call({
      apiKey,
      model: body.model,
      system: body.system,
      messages: body.messages,
      max_tokens: body.max_tokens
    });
    return res.status(200).json(result);
  } catch (err) {
    return res.status(500).json({ error: { message: 'Erreur réseau : ' + err.message } });
  }
}
