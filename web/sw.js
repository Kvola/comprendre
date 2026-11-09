// Service worker de la version web (PWA).
//
// Fichier identique dans chaque application (Quiz biblique, Comprendre,
// Kavola, Kavola Pro). `scripts/build_web.sh` remplace __BUILD_VERSION__ :
// un octet change, le navigateur installe la nouvelle version.
//
// RÈGLE : LE RÉSEAU D'ABORD, LE CACHE SEULEMENT HORS LIGNE
//
// En ligne, l'application est exactement celle du serveur (le serveur répond
// « 304 inchangé » à bas coût). Hors ligne, elle s'ouvre depuis le cache.
// Jamais de délai d'attente qui basculerait sur le cache : sur une connexion
// lente on servirait un index.html neuf avec un main.dart.js ancien, et
// l'application ne démarrerait plus.
//
// LE CŒUR EST MIS EN CACHE D'UN BLOC, PAR VERSION
//
// À l'installation, les fichiers sans lesquels rien ne démarre sont copiés
// ensemble dans un cache propre à la version. Si un seul manque, l'installation
// échoue et l'ancienne version reste en place, entière. Le reste (moteur
// graphique, polices, images) est gardé au fil de l'usage.
//
// Seules les adresses de l'application sont concernées : les appels au serveur
// (/api/…) passent sans jamais être mis en cache.

const VERSION = '__BUILD_VERSION__';
const CORE_CACHE = 'core-' + VERSION;
const RUNTIME_CACHE = 'runtime';
const SCOPE = self.registration.scope;
const CORE = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'sqlite3.wasm',
  'drift_worker.js',
].map((path) => new URL(path, SCOPE).href);

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CORE_CACHE)
      // `no-cache` : revalider auprès du serveur (« 304 » si inchangé), jamais
      // figer un fichier ancien sorti du cache HTTP.
      .then((cache) => cache.addAll(CORE.map((url) => new Request(url, { cache: 'no-cache' }))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((key) => key.startsWith('core-') && key !== CORE_CACHE)
          .map((key) => caches.delete(key)),
      ))
      .then(() => self.clients.claim()),
  );
});

function inScope(request) {
  if (request.method !== 'GET' || !request.url.startsWith(SCOPE)) return false;
  // Les requêtes partielles (audio, vidéo) ne se rangent pas dans un cache.
  return !request.headers.has('range');
}

async function fromCache(request) {
  const core = await caches.open(CORE_CACHE);
  const hit = (await core.match(request, { ignoreSearch: true }))
    || (await caches.match(request, { ignoreSearch: true }));
  if (hit) return hit;
  // Navigation hors ligne vers une adresse interne : l'application route seule.
  if (request.mode === 'navigate') return core.match(new URL('index.html', SCOPE).href);
  return undefined;
}

// Fichiers chargés avant que ce service worker ne contrôle la page (voir
// index.html) : on les garde, sans retélécharger ce qui l'est déjà.
self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type !== 'keep' || !Array.isArray(data.urls)) return;
  event.waitUntil((async () => {
    const runtime = await caches.open(RUNTIME_CACHE);
    for (const url of data.urls.slice(0, 200)) {
      if (typeof url !== 'string' || !url.startsWith(SCOPE) || CORE.includes(url)) continue;
      if (await runtime.match(url)) continue;
      try {
        // Cache HTTP du navigateur d'abord : le serveur ne renvoie que « 304 ».
        const response = await fetch(url);
        if (response.ok && response.type === 'basic') await runtime.put(url, response);
      } catch (_) { /* hors ligne : ce sera pour la prochaine fois */ }
    }
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (!inScope(request)) return;
  event.respondWith((async () => {
    try {
      const response = await fetch(request);
      if (response.ok && response.type === 'basic') {
        const copy = response.clone();
        const name = CORE.includes(request.url) ? CORE_CACHE : RUNTIME_CACHE;
        event.waitUntil(caches.open(name).then((cache) => cache.put(request, copy)).catch(() => {}));
      }
      return response;
    } catch (error) {
      const cached = await fromCache(request);
      if (cached) return cached;
      throw error;
    }
  })());
});
