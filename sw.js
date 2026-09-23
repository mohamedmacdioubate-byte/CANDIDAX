const CACHE_NAME = 'candidax-v3';
const ASSETS = [
  '/',
  '/index.html',
  '/app.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
  'https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600;9..144,700&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap'
];

// Installation — mise en cache de l'app complète (marketing + application)
// pour permettre une utilisation 100% hors ligne une fois visitée.
// Chaque ressource est mise en cache indépendamment : si l'une d'elles
// échoue (ex: police externe injoignable), les autres sont quand même
// conservées au lieu de tout annuler (comportement par défaut de addAll).
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return Promise.all(ASSETS.map(function(url) {
        return cache.add(url).catch(function(err) {
          console.log('Ressource non mise en cache :', url, err);
        });
      }));
    })
  );
  self.skipWaiting();
});

// Activation — suppression des anciens caches
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(key) { return key !== CACHE_NAME; })
            .map(function(key) { return caches.delete(key); })
      );
    })
  );
  self.clients.claim();
});

// Fetch
// - Requêtes vers un autre domaine (Supabase, IA, polices, etc.) : on ne les
//   intercepte PAS du tout, elles partent normalement vers le réseau. Les
//   intercepter cassait les appels d'authentification Supabase et affichait
//   à tort un message "offline" lors de la création de compte.
// - Pages HTML de notre site (navigation) : réseau en priorité pour rester
//   à jour, secours sur le cache si hors ligne (app.html reste app.html
//   hors ligne, pas de redirection vers l'accueil).
// - Reste des assets de notre site (CSS, icônes, manifest) : cache en
//   priorité, réseau en secours.
self.addEventListener('fetch', function(e) {
  var req = e.request;
  var url = new URL(req.url);

  // Requête vers un autre domaine que le nôtre : on laisse passer tel quel.
  if (url.origin !== self.location.origin) return;

  // Notre propre API serverless (/api/ai.js) : réseau uniquement.
  if (url.pathname.indexOf('/api/') === 0) {
    e.respondWith(fetch(req).catch(function() {
      return new Response('{"error":"offline"}', { headers: {'Content-Type':'application/json'}, status: 503 });
    }));
    return;
  }

  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req).then(function(response) {
        var clone = response.clone();
        caches.open(CACHE_NAME).then(function(cache) { cache.put(req, clone); });
        return response;
      }).catch(function() {
        return caches.match(req).then(function(cached) {
          if (cached) return cached;
          // Page jamais visitée en ligne : on propose l'app si dispo, sinon l'accueil
          if (url.pathname.indexOf('app.html') !== -1) return caches.match('/app.html');
          return caches.match('/index.html');
        });
      })
    );
    return;
  }

  // Assets locaux (CSS, polices, icônes, manifest) — Cache First
  e.respondWith(
    caches.match(req).then(function(cached) {
      if (cached) return cached;
      return fetch(req).then(function(response) {
        if (!response || response.status !== 200 || response.type === 'opaque') return response;
        var clone = response.clone();
        caches.open(CACHE_NAME).then(function(cache) { cache.put(req, clone); });
        return response;
      }).catch(function() {
        return caches.match('/index.html');
      });
    })
  );
});

// Message de mise à jour
self.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
});
