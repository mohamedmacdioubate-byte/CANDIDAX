const CACHE_NAME = 'candidax-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icon-192.png',
  '/icon-512.png',
  'https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,400;9..144,600;9..144,700&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap'
];

// Installation — mise en cache des assets
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(ASSETS).catch(function(err) {
        console.log('Cache partiel:', err);
      });
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

// Fetch — stratégie Cache First pour les assets, Network First pour les API
self.addEventListener('fetch', function(e) {
  var url = e.request.url;

  // API IA (fonction Vercel) et polices — toujours réseau (pas de cache)
  if (url.includes('/api/') || url.includes('api.anthropic.com') || url.includes('api.openai.com') || url.includes('fonts.gstatic.com')) {
    e.respondWith(fetch(e.request).catch(function() {
      return new Response('{"error":"offline"}', { headers: {'Content-Type':'application/json'} });
    }));
    return;
  }

  // Assets locaux — Cache First
  e.respondWith(
    caches.match(e.request).then(function(cached) {
      if (cached) return cached;
      return fetch(e.request).then(function(response) {
        if (!response || response.status !== 200 || response.type === 'opaque') return response;
        var clone = response.clone();
        caches.open(CACHE_NAME).then(function(cache) { cache.put(e.request, clone); });
        return response;
      }).catch(function() {
        // Hors ligne — renvoyer la page principale
        return caches.match('/index.html');
      });
    })
  );
});

// Message de mise à jour
self.addEventListener('message', function(e) {
  if (e.data && e.data.type === 'SKIP_WAITING') self.skipWaiting();
});
