// Odin-managed game script bootstrap.
// Provides the small userscript runtime GodBot expects inside the embedded WebView.
(function () {
  window.OdinGameBridge = window.OdinGameBridge || {};
  window.OdinGameBridge.version = '3';

  window.OdinGameBridge.minimize = function () {
    if (window.OdinNative && typeof window.OdinNative.minimize === 'function') {
      window.OdinNative.minimize();
    }
  };

  try {
    window.unsafeWindow = window;
    window.GM_info = window.GM_info || { script: { name: 'Odin managed script', version: '1.0.0' } };
    window.GM_getValue = window.GM_getValue || function (key, fallback) {
      try { var raw = localStorage.getItem('__odin_gm_' + key); return raw === null ? fallback : JSON.parse(raw); } catch (_) { return fallback; }
    };
    window.GM_setValue = window.GM_setValue || function (key, value) {
      try { localStorage.setItem('__odin_gm_' + key, JSON.stringify(value)); } catch (_) {}
    };
    window.GM_deleteValue = window.GM_deleteValue || function (key) {
      try { localStorage.removeItem('__odin_gm_' + key); } catch (_) {}
    };
    window.GM_listValues = window.GM_listValues || function () {
      try { return Object.keys(localStorage).filter(function (k) { return k.indexOf('__odin_gm_') === 0; }).map(function (k) { return k.slice(11); }); } catch (_) { return []; }
    };
    window.GM_addStyle = window.GM_addStyle || function (css) {
      var style = document.createElement('style'); style.textContent = String(css || ''); document.documentElement.appendChild(style); return style;
    };
    window.GM_registerMenuCommand = window.GM_registerMenuCommand || function () { return null; };
    window.GM_notification = window.GM_notification || function (details) { try { console.info('[Odin] GM_notification', details); } catch (_) {} };
  } catch (_) {}

  window.OdinGameBridge.isInWorld = function () {
    var path = String(window.location.pathname || '');
    var search = String(window.location.search || '');
    return /\/game\.php(?:$|\/)/i.test(path) || (/(?:^|&)screen=/i.test(search) && /(?:^|&)village=/i.test(search));
  };

  // Native loader uses eval() for downloaded managed scripts. Keep that execution
  // disabled until Die Stämme has actually opened a village/game.php page.
  try {
    var originalEval = window.eval;
    if (!window.OdinGameBridge._evalGuardInstalled) {
      window.OdinGameBridge._evalGuardInstalled = true;
      window.eval = function (code) {
        if (!window.OdinGameBridge.isInWorld()) {
          console.debug('[Odin] Managed script skipped outside game world:', window.location.href);
          return undefined;
        }
        return originalEval(code);
      };
    }
  } catch (_) {}
})();
