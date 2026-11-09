{{flutter_js}}
{{flutter_build_config}}

// Chargement SANS `serviceWorkerSettings` : avec, Flutter enregistre son propre
// service worker (déprécié) à la place de sw.js, sur la même adresse, et
// l'application ne s'ouvre plus hors ligne. sw.js est enregistré par index.html.
_flutter.loader.load();
