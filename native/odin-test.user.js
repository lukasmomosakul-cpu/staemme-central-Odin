// ==UserScript==
// @name         Odin Userscript Test
// @namespace    odin-test
// @version      1.0
// @match        *://*.die-staemme.de/game.php*
// @grant        none
// ==/UserScript==
(function () {
  'use strict';
  function show() {
    var el = document.getElementById('__odin_userscript_test');
    if (!el) {
      el = document.createElement('div');
      el.id = '__odin_userscript_test';
      el.style.cssText = 'position:fixed;top:55px;left:50%;transform:translateX(-50%);z-index:2147483647;background:#111;color:#0f0;padding:8px 14px;border:2px solid #0f0;border-radius:6px;font:bold 16px sans-serif;box-shadow:0 2px 8px #000;';
      document.body.appendChild(el);
    }
    el.textContent = 'USERSCRIPT OK';
  }
  if (document.body) show();
  else document.addEventListener('DOMContentLoaded', show, { once: true });
  console.log('ODIN_TEST_USERSCRIPT_OK');
})();
