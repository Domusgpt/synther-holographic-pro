'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "772bb1f72907228f68ec2494cd07039d",
"assets/AssetManifest.bin.json": "c1e5fc90cd836dc96b86ab4000d1a9c9",
"assets/AssetManifest.json": "c951c0e166478e7df38bcd9ccc1a9660",
"assets/assets/visualizer/core/GeometryManager.js": "4ed1ab215cdda51699cf49f3444de965",
"assets/assets/visualizer/core/HypercubeCore.js": "b145fe52cddc8ca2dcf4d66956eb8d0f",
"assets/assets/visualizer/core/ProjectionManager.js": "4eb140e35f4f9cca914c62bf997ed2ee",
"assets/assets/visualizer/core/ShaderManager.js": "cd92f25f8312dfbc296c9860ff294c5d",
"assets/assets/visualizer/css/enhanced-styles.css": "f23f760188262ed1721a09f984f6fd9e",
"assets/assets/visualizer/css/neumorphic-style.css": "718092ef0990c4eec2dacebd1e41d793",
"assets/assets/visualizer/css/neumorphic-vars.css": "c747dd59f0ac4dcf4630f72f3ab5b5bf",
"assets/assets/visualizer/flutter-integration.html": "3c0de817894a973dd7488ec416d32fac",
"assets/assets/visualizer/GeometryManager.js": "4ed1ab215cdda51699cf49f3444de965",
"assets/assets/visualizer/HypercubeCore.js": "b145fe52cddc8ca2dcf4d66956eb8d0f",
"assets/assets/visualizer/index-flutter.html": "38055a43fa5d8b9b931e03b42f34aa4f",
"assets/assets/visualizer/index-hyperav.html": "e23d43bc3d528b56f3310ebb317fb629",
"assets/assets/visualizer/index.html": "fdc078dfbe67b36d38b3746741e0e6ed",
"assets/assets/visualizer/js/flutter-bridge.js": "323976bd0dc5a7cb957d5ebb9f27bca6",
"assets/assets/visualizer/js/visualizer-globals.js": "9d8627f6f7c758d8541942ee04f39434",
"assets/assets/visualizer/js/visualizer-main-hyperav.js": "b53a58a8cd34a17a8513467c2e666941",
"assets/assets/visualizer/js/visualizer-main.js": "69f79990ac621781e2936fa197b50a36",
"assets/assets/visualizer/ProjectionManager.js": "4eb140e35f4f9cca914c62bf997ed2ee",
"assets/assets/visualizer/README.md": "f38f81f6f1ee88a6b14dff1293c347e4",
"assets/assets/visualizer/ShaderManager.js": "cd92f25f8312dfbc296c9860ff294c5d",
"assets/assets/visualizer/sound/modules/AnalysisModule.js": "7b630ba69e5ea036f3bcf21119770abe",
"assets/assets/visualizer/sound/modules/EffectsModule.js": "5fcbce4be9e228e30c190135bf24bdf4",
"assets/assets/visualizer/sound/SoundInterface.js": "d4d240eb41fa1154bd1dffb05a541114",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "040dc9ca160f4b93e7a788e5522e5a68",
"assets/NOTICES": "a481d9478bcfc940486a39aa9e78d76e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "f3cfcc301b655384d0421742a698f016",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "dda7652b8cccfedde09d9f0bce593208",
"/": "dda7652b8cccfedde09d9f0bce593208",
"main.dart.js": "2e75305570388832799b6c9ba09d1cba",
"manifest.json": "d43b113fc91ba97353bd92481def9a61",
"version.json": "902d9eaa765a119630dd3a8bb679597d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
