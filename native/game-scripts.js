// Odin-managed game script bootstrap.
(function () {
  'use strict';
  window.OdinGameBridge = window.OdinGameBridge || {};
  window.OdinGameBridge.version = '7';
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
    window.GM_info = window.GM_info || { script: { name: 'GodBot', version: 'Odin' }, isIncognito: false };
    window.GM_getValue = window.GM_getValue || function (key, fallback) { try { var raw = localStorage.getItem('__odin_gm_' + key); return raw === null ? fallback : JSON.parse(raw); } catch (_) { return fallback; } };
    window.GM_setValue = window.GM_setValue || function (key, value) { try { localStorage.setItem('__odin_gm_' + key, JSON.stringify(value)); } catch (_) {} };
    window.GM_deleteValue = window.GM_deleteValue || function (key) { try { localStorage.removeItem('__odin_gm_' + key); } catch (_) {} };
    window.GM_listValues = window.GM_listValues || function () { try { return Object.keys(localStorage).filter(function (k) { return k.indexOf('__odin_gm_') === 0; }).map(function (k) { return k.slice(11); }); } catch (_) { return []; } };
    window.GM_addStyle = window.GM_addStyle || function (css) { var style = document.createElement('style'); style.textContent = String(css || ''); (document.head || document.documentElement).appendChild(style); return style; };
    window.GM_registerMenuCommand = window.GM_registerMenuCommand || function () { return null; };
    window.GM_notification = window.GM_notification || function (d) { try { console.info('[Odin/GodBot]', typeof d === 'string' ? d : (d && (d.text || d.body) || '')); } catch (_) {} };
    window.GM_openInTab = window.GM_openInTab || function (url) { try { window.open(String(url || ''), '_blank'); } catch (_) {} return { close:function(){}, closed:false }; };
    window.GM_setClipboard = window.GM_setClipboard || function (text) { try { if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(String(text || '')); } catch (_) {} };
    window.GM_xmlhttpRequest = window.GM_xmlhttpRequest || function (d) { d=d||{}; var x=new XMLHttpRequest(); try { x.open(String(d.method||'GET').toUpperCase(),String(d.url||''),true); if(d.headers)Object.keys(d.headers).forEach(function(k){try{x.setRequestHeader(k,d.headers[k]);}catch(_){}}); x.onreadystatechange=function(){if(x.readyState!==4)return;var r={readyState:4,status:x.status,statusText:x.statusText,responseText:x.responseText,response:x.response,finalUrl:x.responseURL,responseHeaders:''};try{r.responseHeaders=x.getAllResponseHeaders();}catch(_){} if(x.status>=200&&x.status<400){if(typeof d.onload==='function')d.onload(r);}else if(typeof d.onerror==='function')d.onerror(r);if(typeof d.onloadend==='function')d.onloadend(r);}; x.send(d.data||null); } catch(e){if(typeof d.onerror==='function')d.onerror({error:e});} return {abort:function(){try{x.abort();}catch(_){}}}; };
  } catch (_) {}

  // GodBot is a fixed Odin component. It is loaded automatically on every game-world page,
  // independently of the user script library / Supabase enabled flag.
  function loadGodBot() {
    if (!window.OdinGameBridge.isInWorld() || window.__odinGodBotLoaded || window.__odinGodBotLoading) return;
    window.__odinGodBotLoading = true;
    var s = document.createElement('script');
    s.src = 'https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js?odin=' + Date.now();
    s.async = false;
    s.onload = function () { window.__odinGodBotLoaded = true; window.__odinGodBotLoading = false; console.info('[Odin] GodBot loaded as built-in component'); };
    s.onerror = function () { window.__odinGodBotLoading = false; console.error('[Odin] GodBot could not be loaded'); };
    (document.head || document.documentElement).appendChild(s);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', loadGodBot, { once:true }); else loadGodBot();
  setTimeout(loadGodBot, 1500);
})();
