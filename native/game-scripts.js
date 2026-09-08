// Odin-managed game script bootstrap.
// This file is injected into the native Die-Stämme WebView after each page load.
// The script manager can later replace/extend this payload with enabled user scripts.
(function () {
  window.OdinGameBridge = window.OdinGameBridge || {};
  window.OdinGameBridge.version = '1';

  // Keep a native minimize hook available to future Odin UI controls.
  window.OdinGameBridge.minimize = function () {
    if (window.OdinNative && typeof window.OdinNative.minimize === 'function') {
      window.OdinNative.minimize();
    }
  };
})();
