// Odin-managed game script bootstrap.
// Provides a Tampermonkey-compatible runtime inside the embedded WebView.
(function () {
  'use strict';
  window.OdinGameBridge = window.OdinGameBridge || {};
  window.OdinGameBridge.version = '4';

  window.OdinGameBridge.minimize = function () {
    if (window.OdinNative && typeof window.OdinNative.minimize === 'function') window.OdinNative.minimize();
  };

  window.OdinGameBridge.isInWorld = function () {
    var path = String(window.location.pathname || '');
    var search = String(window.location.search || '');
    return /\/game\.php(?:$|\/)/i.test(path) || (/(?:^|&)screen=/i.test(search) && /(?:^|&)village=/i.test(search));
  };

  try {
    window.unsafeWindow = window;
    window.GM_info = window.GM_info || { script: { name: 'Odin managed script', version: '1.0.0' }, isIncognito: false };

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
    window.GM_addValueChangeListener = window.GM_addValueChangeListener || function () { return 0; };
    window.GM_removeValueChangeListener = window.GM_removeValueChangeListener || function () {};

    window.GM_addStyle = window.GM_addStyle || function (css) {
      var style = document.createElement('style');
      style.textContent = String(css || '');
      (document.head || document.documentElement).appendChild(style);
      return style;
    };
    window.GM_registerMenuCommand = window.GM_registerMenuCommand || function () { return null; };
    window.GM_unregisterMenuCommand = window.GM_unregisterMenuCommand || function () {};
    window.GM_notification = window.GM_notification || function (details) {
      try {
        var text = typeof details === 'string' ? details : ((details && (details.text || details.body)) || '');
        if (text) console.info('[Odin] GM_notification:', text);
      } catch (_) {}
    };
    window.GM_openInTab = window.GM_openInTab || function (url) {
      try { window.open(String(url || ''), '_blank'); } catch (_) {}
      return { close: function () {}, closed: false };
    };
    window.GM_setClipboard = window.GM_setClipboard || function (text) {
      try {
        if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(String(text || ''));
        else { var t = document.createElement('textarea'); t.value = String(text || ''); document.body.appendChild(t); t.select(); document.execCommand('copy'); t.remove(); }
      } catch (_) {}
    };

    // Best-effort userscript-compatible XHR. GitHub/raw script hosts expose CORS;
    // for same-origin requests this behaves like a normal XMLHttpRequest.
    window.GM_xmlhttpRequest = window.GM_xmlhttpRequest || function (details) {
      details = details || {};
      var method = String(details.method || 'GET').toUpperCase();
      var url = String(details.url || '');
      var xhr = new XMLHttpRequest();
      try {
        xhr.open(method, url, true);
        if (details.headers) Object.keys(details.headers).forEach(function (k) { try { xhr.setRequestHeader(k, details.headers[k]); } catch (_) {} });
        xhr.onreadystatechange = function () {
          if (xhr.readyState !== 4) return;
          var response = { readyState: 4, status: xhr.status, statusText: xhr.statusText, responseText: xhr.responseText, response: xhr.response, finalUrl: xhr.responseURL, responseHeaders: '' };
          try { response.responseHeaders = xhr.getAllResponseHeaders(); } catch (_) {}
          if (xhr.status >= 200 && xhr.status < 400) { if (typeof details.onload === 'function') details.onload(response); }
          else if (typeof details.onerror === 'function') details.onerror(response);
          if (typeof details.onloadend === 'function') details.onloadend(response);
        };
        xhr.onerror = function () { if (typeof details.onerror === 'function') details.onerror({ status: xhr.status, responseText: xhr.responseText }); if (typeof details.onloadend === 'function') details.onloadend(); };
        xhr.send(details.data || null);
      } catch (e) { if (typeof details.onerror === 'function') details.onerror({ error: e }); }
      return { abort: function () { try { xhr.abort(); } catch (_) {} } };
    };
  } catch (_) {}

  // Userscripts are downloaded by the native loader. This guard prevents accidental
  // execution on the login/start page and allows execution once a real game page exists.
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
