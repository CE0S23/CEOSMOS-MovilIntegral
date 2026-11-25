{{flutter_js}}
{{flutter_build_config}}

// CEOSMOS: se carga Flutter SIN su service worker (en Flutter 3.41 solo se
// desregistra) y se registra el propio (sw.js), que sí da funcionamiento offline.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    const carga = document.getElementById('carga');
    if (carga) carga.remove();
    await appRunner.runApp();
  },
});

if ('serviceWorker' in navigator) {
  window.addEventListener('load', async function () {
    try {
      // Quita el service worker antiguo de Flutter si quedó de una versión previa.
      for (const r of await navigator.serviceWorker.getRegistrations()) {
        const url = (r.active || r.waiting || r.installing || {}).scriptURL || '';
        if (url.includes('flutter_service_worker.js')) await r.unregister();
      }
      await navigator.serviceWorker.register('sw.js', { scope: './' });
    } catch (e) {
      console.warn('CEOSMOS: no se registró el service worker', e);
    }
  });
}
