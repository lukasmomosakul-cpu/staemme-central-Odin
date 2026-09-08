// Odin-managed game script bootstrap.
// Injected on every page, but managed scripts must only execute once a real
// game.php world page is open. This keeps login/start pages free of GodBot gates.
(function () {
  window.OdinGameBridge = window.OdinGameBridge || {};
  window.OdinGameBridge.version = '2';

  window.OdinGameBridge.minimize = function () {
    if (window.OdinNative && typeof window.OdinNative.minimize === 'function') {
      window.OdinNative.minimize();
    }
  };

  // The native loader currently evaluates managed scripts after each page load.
  // Gate that eval on the actual in-world page without touching the user's script.
  try {
    var originalEval = window.eval;
    if (!window.OdinGameBridge._evalGuardInstalled) {
      window.OdinGameBridge._evalGuardInstalled = true;
      window.eval = function (code) {
        var path = String(window.location.pathname || '');
        var search = String(window.location.search || '');
        var inWorld = /\/game\.php(?:$|\/)/i.test(path) || /(?:^|&)screen=/i.test(search) && /(?:^|&)village=/i.test(search);
        if (!inWorld) {
          console.debug('[Odin] Managed script skipped outside game world:', window.location.href);
          return undefined;
        }
        return originalEval(code);
      };
    }
  } catch (_) {}
})();
