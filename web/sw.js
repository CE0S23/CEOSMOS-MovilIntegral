/* CEOSMOS · Service Worker de la PWA.
 *
 * Flutter 3.41 ya no trae un service worker útil (el suyo se desregistra solo), así
 * que CEOSMOS usa este. Estrategias:
 *   - Instalación: precarga el «app shell» (HTML, JS, CanvasKit, fuentes, audios,
 *     iconos). La lista la escribe scripts/pwa_precache.py al compilar; si no se
 *     procesó (compilación de desarrollo), se usa una lista mínima y lo demás se
 *     guarda al vuelo.
 *   - Navegación: red primero y, sin red, el index.html guardado (abre sin conexión).
 *   - Archivos propios: caché primero y actualización en segundo plano.
 *   - API de CEOSMOS, Firebase y cualquier petición que no sea GET: NUNCA se guardan
 *     (datos personales y tokens); la app maneja la falta de red con su modo sin
 *     conexión y la cola de sesiones pendientes.
 *   - Imágenes externas de la biblioteca: caché propia limitada a 60 entradas
 *     (se descartan las más antiguas), equivalente web de la caché LRU del móvil.
 */
'use strict';

const VERSION = 'dev';
const PRECARGA = ['./', 'index.html', 'manifest.json', 'flutter_bootstrap.js', 'main.dart.js', 'favicon.png'];

const CACHE_APP = `ceosmos-app-${VERSION}`;
const CACHE_MEDIOS = 'ceosmos-medios';
const MAX_MEDIOS = 60;

// Hosts cuyas respuestas jamás se guardan (datos de usuario o autenticación).
const SIN_CACHE = [/\/api\//, /firestore\.googleapis\.com/, /identitytoolkit\.googleapis\.com/,
  /securetoken\.googleapis\.com/, /firebasestorage\.googleapis\.com/, /googleapis\.com\/upload/];
// Recursos estáticos de terceros que sí conviene guardar (fuentes de respaldo de Flutter).
const ESTATICOS_EXTERNOS = [/fonts\.gstatic\.com/, /www\.gstatic\.com\/flutter-canvaskit/];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_APP);
    // Uno por uno: un archivo que falte no impide instalar el resto.
    await Promise.all(PRECARGA.map(async (url) => {
      try {
        const res = await fetch(new Request(url, { cache: 'reload' }));
        if (res.ok) await cache.put(url, res);
      } catch (e) { /* sin red durante la instalación: se reintenta al vuelo */ }
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const nombres = await caches.keys();
    await Promise.all(nombres
      .filter((n) => n.startsWith('ceosmos-app-') && n !== CACHE_APP)
      .map((n) => caches.delete(n)));
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'version') event.source?.postMessage({ tipo: 'version', version: VERSION });
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (SIN_CACHE.some((r) => r.test(req.url))) return;

  if (req.mode === 'navigate') {
    event.respondWith(redPrimeroNavegacion(req));
    return;
  }
  if (url.origin === self.location.origin) {
    event.respondWith(cachePrimero(req, CACHE_APP));
    return;
  }
  if (ESTATICOS_EXTERNOS.some((r) => r.test(req.url))) {
    event.respondWith(cachePrimero(req, CACHE_APP));
    return;
  }
  if (req.destination === 'image' || /\.(png|jpe?g|webp|gif)(\?|$)/i.test(url.pathname)) {
    event.respondWith(medio(req));
  }
});

async function redPrimeroNavegacion(req) {
  const cache = await caches.open(CACHE_APP);
  try {
    const res = await fetch(req);
    if (res.ok) cache.put('index.html', res.clone());
    return res;
  } catch (e) {
    return (await cache.match('index.html')) || (await cache.match('./')) || Response.error();
  }
}

async function cachePrimero(req, nombre) {
  const cache = await caches.open(nombre);
  const guardada = await cache.match(req, { ignoreSearch: true });
  const red = fetch(req).then((res) => {
    if (res.ok && (res.type === 'basic' || res.type === 'cors')) cache.put(req, res.clone());
    return res;
  }).catch(() => null);
  // Con copia guardada se responde al instante; la descarga sigue y la actualiza.
  if (guardada) return guardada;
  return (await red) || Response.error();
}

async function medio(req) {
  const cache = await caches.open(CACHE_MEDIOS);
  const guardada = await cache.match(req);
  if (guardada) return guardada;
  try {
    const res = await fetch(req);
    // Las respuestas opacas (sin CORS) no se guardan: el navegador les asigna ~7 MB de cuota.
    if (res.ok && res.type !== 'opaque') {
      await cache.put(req, res.clone());
      const claves = await cache.keys();
      for (let i = 0; i < claves.length - MAX_MEDIOS; i++) await cache.delete(claves[i]);
    }
    return res;
  } catch (e) {
    return Response.error();
  }
}
