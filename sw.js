// Offline cache for the home-screen app. The version changes on every build, so a new build replaces the old cache.
const VERSION = '42fe8b7b4ec5';
const CACHE = 'edu-atlas-' + VERSION;
const CORE = ['./', './index.html', './manifest.webmanifest', './icons/icon-180.png', './icons/icon-192.png', './icons/icon-512.png', './icons/maskable-512.png'];
self.addEventListener('install', e => { e.waitUntil(caches.open(CACHE).then(c => c.addAll(CORE)).then(() => self.skipWaiting())); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k.startsWith('edu-atlas-') && k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', e => {
  const req = e.request; if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Pages: network first so updates arrive, cached copy when offline.
  if (req.mode === 'navigate') { e.respondWith(fetch(req).then(r => { const copy = r.clone(); caches.open(CACHE).then(c => c.put('./index.html', copy)); return r; }).catch(() => caches.match('./index.html'))); return; }
  // App files and fonts: cached copy first, refreshed in the background.
  if (url.origin === location.origin || /fonts\.(googleapis|gstatic)\.com|fontshare\.com/.test(url.host)) {
    e.respondWith(caches.open(CACHE).then(c => c.match(req).then(hit => { const net = fetch(req).then(r => { if (r && (r.ok || r.type === 'opaque')) c.put(req, r.clone()); return r; }).catch(() => hit); return hit || net; })));
  }
});
