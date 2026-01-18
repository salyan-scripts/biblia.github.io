const CACHE_NAME = 'biblia-pro-v2-cache';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './manifest.json',
  './acf.json',
  './nvi.json',
  './icon.png'
];

// Instalação do Service Worker
self.addEventListener('install', event => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => {
      console.log('Caching assets for offline use');
      return cache.addAll(ASSETS_TO_CACHE);
    })
  );
});

// Ativação e Limpeza de caches antigos
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => {
      return Promise.all(
        keys.filter(key => key !== CACHE_NAME)
            .map(key => caches.delete(key))
      );
    })
  );
});

// Interceptação de Requisições (Modo Offline Total)
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(cachedResponse => {
      // Retorna o arquivo do cache se existir
      if (cachedResponse) {
        return cachedResponse;
      }

      // Se não estiver no cache, tenta buscar na rede
      return fetch(event.request).then(networkResponse => {
        // Opcional: Adiciona novos arquivos buscados ao cache dinamicamente
        if (networkResponse && networkResponse.status === 200) {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then(cache => {
            cache.put(event.request, responseToCache);
          });
        }
        return networkResponse;
      }).catch(() => {
        // Fallback caso não haja rede e não esteja no cache
        if (event.request.mode === 'navigate') {
          return caches.match('./index.html');
        }
      });
    })
  );
});