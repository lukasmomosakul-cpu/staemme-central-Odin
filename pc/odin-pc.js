// ==UserScript==
// @name         Odin PC
// @namespace    teamzentrale-odin
// @version      __PCVERSION__
// @description  GodBot im PC-Browser, verbunden mit Odin: Einstellungsabgleich, Befehle aus der Web-App, Geräte-Sperre, Protokoll.
// @author       lukasmomosakul-cpu
// @match        *://*.die-staemme.de/game.php*
// @grant        none
// @run-at       document-idle
// @updateURL    https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/OdinPC.user.js
// @downloadURL  https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/OdinPC.user.js
// ==/UserScript==

// Odin PC - GodBot im Browser als vollwertiges Odin-Geraet.
//
// Aufbau (erzeugt von pc/build_odin_pc.py):
//   1. diese Schicht: Anmeldung bei Odin (Supabase), Konto-Zuordnung,
//      Geraete-Sperre (account_leases, 017), Tab-Abstimmung, Protokoll
//   2. der Loader der App (native/patch-godbot-loader.sh) UNVERAENDERT -
//      Einstellungsabgleich, Befehle, Meldungen. Er spricht mit OdinNative;
//      das ist hier ein JS-Nachbau der 13 Methoden der App.
//   3. GodBot selbst, in eine Funktion eingepackt. Er startet erst, wenn
//      die Sperre gehalten wird - kein eval, kein nachgeladenes Skript,
//      damit keine Content-Security-Policy dazwischenfunken kann.
//
// window.Odin bekommt hier KEIN stand(): GodBot behaelt im Browser sein
// schwebendes Fenster (odinEingebettet() = false).
(function () {
if (window.top !== window.self) return;
if (window.__odinPC) return;
// In der App-WebView gibt es Tampermonkey nicht - trotzdem sicher sein.
if (window.Odin && window.Odin.istApp) return;
window.__odinPC = 1;

var PCV = '__PCVERSION__';
var SUPA = 'https://sjrcoomhuuahayztzdgc.supabase.co';
var ANON = '__ANONKEY__';

// Originale sichern, bevor der Loader fetch und Storage umlenkt.
var F = window.fetch.bind(window);
var LS = window.localStorage;
var RAW_SET = Storage.prototype.setItem, RAW_GET = Storage.prototype.getItem, RAW_DEL = Storage.prototype.removeItem;
function lget(k) { try { return RAW_GET.call(LS, k); } catch (e) { return null; } }
function lset(k, v) { try { RAW_SET.call(LS, k, String(v)); } catch (e) { } }
function ldel(k) { try { RAW_DEL.call(LS, k); } catch (e) { } }
function sget(k) { try { return sessionStorage.getItem(k); } catch (e) { return null; } }
function sset(k, v) { try { sessionStorage.setItem(k, String(v)); } catch (e) { } }
function sdel(k) { try { sessionStorage.removeItem(k); } catch (e) { } }
function jparse(t, d) { try { var x = JSON.parse(t); return x == null ? d : x; } catch (e) { return d; } }
function sleep(ms) { return new Promise(function (r) { setTimeout(r, ms); }); }

var K = {
    sitzung: 'odinpc_sitzung', lock: 'odinpc_refresh_lock', team: 'odinpc_team',
    konto: 'odinpc_konto', geraet: 'odinpc_geraet', fremd: 'odinpc_lease_fremd'
};
var SK = { instanz: 'odinpc_instanz', pause: 'odinpc_pause', lease: 'odinpc_lease' };

var instanz = sget(SK.instanz);
if (!instanz) { instanz = Math.random().toString(16).slice(2, 6); sset(SK.instanz, instanz); }
var geraetId = lget(K.geraet);
if (!geraetId) {
    geraetId = 'pc-' + ((window.crypto && crypto.randomUUID) ? crypto.randomUUID() : (Date.now().toString(36) + Math.random().toString(36).slice(2)));
    lset(K.geraet, geraetId);
}
var geraetName = (function () {
    var ua = navigator.userAgent || '';
    var b = /Edg\//.test(ua) ? 'Edge' : /OPR\//.test(ua) ? 'Opera' : /Firefox\//.test(ua) ? 'Firefox' : /Chrome\//.test(ua) ? 'Chrome' : 'Browser';
    var o = /Windows/.test(ua) ? 'Windows' : /Mac OS X/.test(ua) ? 'macOS' : /Linux/.test(ua) ? 'Linux' : '';
    return ('PC · ' + b + (o ? ' · ' + o : '')).trim();
})();

var Z = {                 // Zustand
    team: null, konto: null, serverStand: null, godbot: 'aus',
    hinweis: '', fehler: '', letzte: '', hochladenErzwingen: false
};

// ===================================================================
// Protokoll: Konsole, Feld unten links und app_events (gebuendelt wie
// in der App: alle 30 s oder ab 25 Eintraegen).
// ===================================================================
var Q = [], qLetzt = 0;
function qSenden() {
    if (!Q.length || !Z.team) return;
    qLetzt = Date.now();
    var rows = Q.splice(0, Q.length);
    rest('POST', 'app_events', rows, 'return=minimal').catch(function () { });
}
function ereignis(stufe, bereich, text) {
    if (!Z.team) return;
    var r = { team_id: Z.team, level: stufe, bereich: bereich + '/pc-' + instanz,
        message: text.length > 500 ? text.slice(0, 500) + ' …' : text,
        device: geraetName, app_version: 'pc-' + PCV };
    if (Z.konto) r.account_id = Z.konto.id;
    Q.push(r);
    if (Q.length >= 25 || Date.now() - qLetzt > 30000) qSenden();
}
setInterval(qSenden, 30000);
window.addEventListener('pagehide', qSenden);

function stufeVon(m) {
    if ((m.indexOf('Fehler') >= 0 && m.indexOf('kein Fehler') < 0) || m.indexOf('fehlgeschlagen') >= 0 || m.indexOf('Achtung') >= 0) return 'FEHLER';
    if (m.indexOf('Zugangssperre') >= 0 || m.indexOf('Geräte-Sperre') >= 0 || m.indexOf('übernommen') >= 0) return 'WICHTIG';
    return 'info';
}
function bereichVon(m) {
    if (m.indexOf('Anmeldung') >= 0) return 'anmeldung';
    if (m.indexOf('Abgleich') >= 0 || m.indexOf('Einstellungen') >= 0 || m.indexOf('gesichert') >= 0) return 'abgleich';
    if (m.indexOf('Sperre') >= 0) return 'sperre';
    return 'app';
}
function status(m, stufe) {
    m = String(m == null ? '' : m);
    stufe = stufe || stufeVon(m);
    try { console.log('[Odin PC]', m); } catch (e) { }
    Z.letzte = new Date().toLocaleTimeString('de-DE') + ' ' + m;
    if (stufe === 'FEHLER') Z.fehler = Z.letzte;
    ereignis(stufe, bereichVon(m), m);
    ui();
}

// ===================================================================
// Supabase: Anmeldung und REST
// ===================================================================
function netzFehler(e) {
    // fetch() wirft TypeError, wenn die Seite (CSP) oder das Netz die
    // Anfrage verhindert - nicht mit einer Serverantwort verwechseln.
    return (e && e.name === 'TypeError') ? new Error('Verbindung zu Odin blockiert (Netz/CSP): ' + e.message) : e;
}
function authPost(pfad, body) {
    return F(SUPA + '/auth/v1/' + pfad, {
        method: 'POST', headers: { apikey: ANON, 'Content-Type': 'application/json' }, body: JSON.stringify(body)
    }).catch(function (e) { throw netzFehler(e); }).then(function (r) {
        return r.text().then(function (t) {
            var j = jparse(t, {});
            if (!r.ok) throw new Error(j.error_description || j.msg || j.message || j.error || ('HTTP ' + r.status));
            return j;
        });
    });
}
function sitzung() { return jparse(lget(K.sitzung), null); }
function sitzungSpeichern(j) {
    var alt = sitzung() || {};
    var s = {
        access_token: j.access_token, refresh_token: j.refresh_token,
        expires_at: j.expires_at || (Math.floor(Date.now() / 1000) + (j.expires_in || 3600)),
        user_id: (j.user && j.user.id) || alt.user_id, email: (j.user && j.user.email) || alt.email
    };
    lset(K.sitzung, JSON.stringify(s));
    return s;
}
function frisch(s) { return s && s.access_token && s.expires_at * 1000 - Date.now() > 120000; }
var erneuerung = null;
// Mehrere Tabs derselben Welt teilen sich die Sitzung (gleiche Origin).
// Supabase verbraucht ein Erneuerungstoken beim Einloesen - gleichzeitige
// Erneuerung aus zwei Tabs endete sonst in refresh_token_already_used.
function token() {
    var s = sitzung();
    if (!s) return Promise.resolve(null);
    if (frisch(s)) return Promise.resolve(s.access_token);
    if (erneuerung) return erneuerung;
    erneuerung = (async function () {
        try {
            var sperre = Number(lget(K.lock) || 0);
            if (Date.now() - sperre < 15000) {
                await sleep(4000);
                var s2 = sitzung(); if (frisch(s2)) return s2.access_token;
            }
            lset(K.lock, Date.now());
            var s3 = sitzung(); if (!s3) return null;
            if (frisch(s3)) return s3.access_token;
            try {
                var j = await authPost('token?grant_type=refresh_token', { refresh_token: s3.refresh_token });
                return sitzungSpeichern(j).access_token;
            } catch (e) {
                var s4 = sitzung();
                if (s4 && s4.refresh_token !== s3.refresh_token && frisch(s4)) return s4.access_token;
                if (/already used|invalid|not found|revoked|expired/i.test(String(e.message))) {
                    ldel(K.sitzung);
                    status('Anmeldung abgelaufen - bitte neu anmelden (' + e.message + ')', 'WICHTIG');
                } else {
                    status('Anmeldung erneuern fehlgeschlagen: ' + e.message);
                }
                return null;
            }
        } finally {
            ldel(K.lock);
            erneuerung = null;
        }
    })();
    return erneuerung;
}
async function rest(method, pfad, body, prefer) {
    for (var v = 0; v < 2; v++) {
        var t = await token();
        if (!t) throw new Error('keine Odin-Sitzung');
        var h = { apikey: ANON, Authorization: 'Bearer ' + t, 'Content-Type': 'application/json', Accept: 'application/json' };
        if (prefer) h.Prefer = prefer;
        var b = body == null ? undefined : (typeof body === 'string' ? body : JSON.stringify(body));
        var opt = { method: method, headers: h, body: b };
        // Beim Verlassen der Seite soll die letzte Buendelung noch ankommen.
        if (b && b.length < 60000) opt.keepalive = true;
        var r;
        try { r = await F(SUPA + '/rest/v1/' + pfad, opt); } catch (e) { throw netzFehler(e); }
        if ((r.status === 401 || r.status === 403) && v === 0) {
            var s = sitzung(); if (s) { s.expires_at = 0; lset(K.sitzung, JSON.stringify(s)); }
            continue;
        }
        var txt = await r.text();
        if (!r.ok) throw new Error('HTTP ' + r.status + ' ' + txt.slice(0, 200));
        return txt ? jparse(txt, null) : null;
    }
    throw new Error('HTTP 401 nach Erneuerung');
}
function rpc(fn, body) { return rest('POST', 'rpc/' + fn, body); }

// ===================================================================
// Konto: Welt + Spielername -> game_accounts
// ===================================================================
function weltNorm(w) {
    var x = String(w || '').trim().toLowerCase().replace(/\s|welt/g, '');
    return /^[0-9]+$/.test(x) ? 'de' + x : x;
}
async function teamLaden() {
    var s = sitzung();
    var c = jparse(lget(K.team), null);
    if (c && c.user_id === s.user_id && c.team) return c.team;
    var r = await rest('GET', 'team_members?select=team_id&user_id=eq.' + encodeURIComponent(s.user_id) + '&limit=1');
    if (!r || !r.length) throw new Error('Dieses Odin-Konto gehört zu keinem Team');
    lset(K.team, JSON.stringify({ user_id: s.user_id, team: r[0].team_id }));
    return r[0].team_id;
}
// Liefert das Konto oder eine Liste zur Auswahl ({wahl:[...]}) oder {fehlt:true}.
async function kontoFinden(gd) {
    var welt = weltNorm(gd.world), pname = String(gd.player.name || ''), pid = String(gd.player.id || '');
    var c = jparse(lget(K.konto), null);
    if (c && c.pid === pid && c.world === welt && Date.now() - (c.geprueft || 0) < 6 * 3600 * 1000) return c;
    var rows = await rest('GET', 'game_accounts?select=id,name,world,player_name&team_id=eq.' + encodeURIComponent(Z.team));
    var inWelt = (rows || []).filter(function (a) { return weltNorm(a.world) === welt; });
    var lc = pname.toLowerCase();
    var treffer = inWelt.filter(function (a) { return a.player_name === pname; });
    if (!treffer.length) treffer = inWelt.filter(function (a) { return String(a.name || '').toLowerCase() === lc; });
    if (!treffer.length && inWelt.length === 1) treffer = inWelt;
    if (c && c.pid === pid && c.world === welt && inWelt.some(function (a) { return a.id === c.id; }))
        treffer = inWelt.filter(function (a) { return a.id === c.id; });
    if (treffer.length === 1) return kontoMerken(treffer[0], welt, pid, pname);
    if (inWelt.length) return { wahl: inWelt };
    return { fehlt: true, welt: welt, pname: pname };
}
function kontoMerken(a, welt, pid, pname) {
    var k = { id: a.id, name: a.name, world: welt, pid: pid, geprueft: Date.now() };
    lset(K.konto, JSON.stringify(k));
    if (!a.player_name && pname)
        rest('PATCH', 'game_accounts?id=eq.' + encodeURIComponent(a.id), { player_name: pname }, 'return=minimal').catch(function () { });
    return k;
}

// ===================================================================
// Geraete-Sperre (account_leases, Migration 017) - wie OdinService in
// der App: gehalten, solange sich das Geraet mindestens alle 3 Min meldet.
// ===================================================================
async function leaseHolen(erzwingen) {
    var r = await rpc('lease_holen', { p_account: Z.konto.id, p_geraet: geraetId, p_name: geraetName, p_erzwingen: !!erzwingen });
    var o = r && r[0];
    if (!o) return null;
    var e = { erhalten: !!o.erhalten, halter: o.geraet_name || 'anderes Gerät', at: Date.now() };
    var alt = jparse(sget(SK.lease), null);
    sset(SK.lease, JSON.stringify(e));
    if (e.erhalten) ldel(K.fremd); else lset(K.fremd, JSON.stringify({ halter: e.halter, at: Date.now() }));
    if (!alt || alt.erhalten !== e.erhalten)
        status(e.erhalten ? (erzwingen ? 'Geräte-Sperre: Konto auf diesen PC geholt' : 'Geräte-Sperre: Konto diesem PC zugewiesen')
            : 'Geräte-Sperre: Konto ist ' + e.halter + ' zugewiesen - GodBot pausiert hier', e.erhalten ? 'info' : 'WICHTIG');
    return e;
}
async function darfLaufen() {
    var c = jparse(sget(SK.lease), null);
    if (c && c.erhalten && Date.now() - c.at < 60000) return c;
    try {
        var e = await leaseHolen(false);
        if (e) return e;
    } catch (err) {
        status('Geräte-Sperre nicht erreichbar: ' + err.message, 'WICHTIG');
    }
    // Offline: ein fremder Halter, der sich vor < 3 Min gemeldet hat,
    // sperrt weiter; sonst darf dieser PC laufen.
    var f = jparse(lget(K.fremd), null);
    if (f && Date.now() - f.at < 180000) return { erhalten: false, halter: f.halter };
    return { erhalten: true, offline: true };
}
function leaseFreigeben() {
    sdel(SK.lease);
    return rpc('lease_freigeben', { p_account: Z.konto.id, p_geraet: geraetId }).catch(function () { });
}

// ===================================================================
// Tab-Abstimmung: je Welt fuehrt nur EIN Tab GodBot. Alle Tabs einer Welt
// teilen localStorage und Geraete-Kennung - die Sperre allein trennt sie
// nicht. BroadcastChannel erreicht auch Hintergrund-Tabs.
// ===================================================================
var bc = null, aktivSeit = 0;
try { bc = new BroadcastChannel('odinpc'); } catch (e) { }
function tabPruefen() {
    return new Promise(function (res) {
        if (!bc) return res(null);
        var gefunden = null;
        var h = function (ev) { var d = ev.data || {}; if (d.t === 'aktiv' && !gefunden) gefunden = d; };
        bc.addEventListener('message', h);
        bc.postMessage({ t: 'hallo' });
        setTimeout(function () { bc.removeEventListener('message', h); res(gefunden); }, 800);
    });
}
function tabAktivMelden(uebernahme) {
    aktivSeit = Date.now();
    if (bc) bc.postMessage({ t: 'aktiv', seit: aktivSeit, uebernahme: !!uebernahme });
}
if (bc) bc.addEventListener('message', function (ev) {
    var d = ev.data || {};
    if (!aktivSeit) return;
    if (d.t === 'hallo') bc.postMessage({ t: 'aktiv', seit: aktivSeit });
    else if (d.t === 'abgeben' || (d.t === 'aktiv' && d.uebernahme)) {
        aktivSeit = 0;
        status('GodBot an anderen Tab abgegeben');
        setTimeout(function () { location.reload(); }, 300);
    } else if (d.t === 'aktiv' && d.seit && d.seit < aktivSeit) {
        // Zwei Tabs gleichzeitig gestartet: der spaetere gibt nach.
        aktivSeit = 0;
        status('Zweiter Tab mit GodBot erkannt - dieser Tab gibt ab');
        setTimeout(function () { location.reload(); }, 300);
    }
});

// ===================================================================
// OdinNative - JS-Nachbau der Schnittstelle, die der Loader erwartet.
// Die App antwortet synchron; hier laufen Netzzugriffe im Hintergrund.
// ===================================================================
function settingsSchreiben(batch, versuch) {
    var weg = [], rows = [];
    Object.keys(batch).forEach(function (k) {
        if (batch[k] === '') weg.push(k);
        else rows.push({ team_id: Z.team, account_id: Z.konto.id, skey: k, value: batch[k] });
    });
    var p = Promise.resolve();
    if (weg.length) p = p.then(function () {
        var liste = '(' + weg.map(function (k) { return '"' + k.replace(/"/g, '') + '"'; }).join(',') + ')';
        return rest('DELETE', 'godbot_settings?account_id=eq.' + encodeURIComponent(Z.konto.id) + '&skey=in.' + encodeURIComponent(liste));
    });
    if (rows.length) p = p.then(function () {
        return rest('POST', 'godbot_settings?on_conflict=account_id,skey', rows, 'resolution=merge-duplicates,return=minimal');
    });
    p.catch(function (e) {
        if (versuch < 3) {
            setTimeout(function () { settingsSchreiben(batch, versuch + 1); }, 30000 * (versuch + 1));
            return;
        }
        // Aufgegeben: den Merker "so hochgeladen" entfernen, damit die
        // naechste Aenderung den Wert erneut schickt.
        Object.keys(batch).forEach(function (k) { ldel('odin_lh_' + k); });
        status('Abgleich schreiben fehlgeschlagen: ' + e.message);
    });
}
// Meldungen, die der Loader bei JEDEM Seitenaufruf schreibt, nur einmal je
// Tab ins Protokoll (541.3).
var EINMAL_JE_TAB = /^Abgleich: bereits eingerichtet/;
var OdinNative = {
    status: function (m) {
        m = String(m == null ? '' : m);
        if (EINMAL_JE_TAB.test(m)) { if (sget('odinpc_einmal_' + m)) return; sset('odinpc_einmal_' + m, '1'); }
        status(m);
    },
    puls: function () { }, lebt: function () { }, termin: function () { }, steuerstand: function () { },
    syncReady: function () { return !!(Z.konto && Z.team && sitzung()); },
    settingsLoad: function () {
        var s = Z.serverStand || {};
        status('Einstellungen geladen (' + Object.keys(s).length + ')');
        return JSON.stringify(s);
    },
    // Die App meldet den Erfolg synchron; hier optimistisch true. Scheitert
    // das Schreiben endgueltig, faellt der Merker weg (settingsSchreiben).
    settingsSave: function (json) {
        if (!OdinNative.syncReady()) return false;
        try { settingsSchreiben(JSON.parse(json), 0); return true; } catch (e) { return false; }
    },
    befehleAbrufen: function () {
        if (!OdinNative.syncReady()) return;
        rest('GET', 'godbot_befehle?select=id,pfad,wert,erstellt_at&erledigt_at=is.null&order=id.asc&limit=20&account_id=eq.' + encodeURIComponent(Z.konto.id))
            .then(function (a) { if (a && a.length && window.__odinBefehle) window.__odinBefehle(a); })
            .catch(function () { });
    },
    befehlErledigt: function (id, ok, erg) {
        rpc('godbot_befehl_erledigt', { p_id: Number(id), p_ok: !!ok, p_ergebnis: erg == null ? '' : String(erg) })
            .then(function () { status('App-Befehl ' + (ok ? 'übernommen' : 'nicht übernommen') + ': ' + (erg || ''), ok ? 'info' : 'WICHTIG'); })
            .catch(function (e) { status('Befehl bestätigen fehlgeschlagen: ' + e.message); });
    },
    notify: function (title, body, level) {
        try {
            if (level === 'warn' && window.Notification && Notification.permission === 'granted')
                new Notification(String(title || 'Odin'), { body: String(body || '') });
        } catch (e) { }
        if (!OdinNative.syncReady()) return false;
        rest('POST', 'notifications', [{ team_id: Z.team, account_id: Z.konto.id, title: title || 'Odin', body: body || '', level: level || 'info', source: geraetId }], 'return=minimal')
            .catch(function (e) { status('Meldung fehlgeschlagen: ' + e.message); });
        return true;
    },
    // Rueckfall fuer GM_xmlhttpRequest (GodBot nutzt ihn derzeit nicht).
    httpGet: function (u) {
        var x = new XMLHttpRequest(); x.open('GET', String(u), false); x.send(null);
        if (x.status < 200 || x.status >= 400) throw new Error('HTTP ' + x.status);
        return x.responseText;
    },
    // Der Loader faengt <a download>-Klicks ab (in der WebView kommen die
    // nicht an). Im Browser geht der normale Weg - ueber ein Element
    // ausserhalb des Dokuments, damit der Abfang es nicht erneut sieht.
    saveText: function (name, text) {
        try {
            var url = URL.createObjectURL(new Blob([String(text)], { type: 'text/plain;charset=utf-8' }));
            var a = document.createElement('a'); a.href = url; a.download = String(name || 'odin.txt');
            a.click();
            setTimeout(function () { URL.revokeObjectURL(url); }, 30000);
        } catch (e) { status('Download fehlgeschlagen: ' + e.message); }
    }
};

// ===================================================================
// Oberflaeche: kleines Feld unten links
// ===================================================================
var UI = { box: null, pill: null, karte: null, offen: false, modus: '', warte: null };
function el(tag, css, text) { var e = document.createElement(tag); if (css) e.style.cssText = css; if (text != null) e.textContent = text; return e; }
function knopf(text, fn, haupt) {
    var b = el('button', 'margin:4px 6px 0 0;padding:5px 10px;border-radius:4px;cursor:pointer;font:bold 11px sans-serif;border:1px solid ' +
        (haupt ? '#2f6b3f;background:#1d3324;color:#8fd4a0' : '#2d4a6b;background:#182234;color:#7fb2ff'), text);
    b.type = 'button'; b.addEventListener('click', fn); return b;
}
function uiBauen() {
    if (UI.box || !document.body) return;
    UI.box = el('div', 'position:fixed;left:8px;bottom:8px;z-index:1000001;font:12px sans-serif;color:#dfe6ee;max-width:min(92vw,340px)');
    UI.karte = el('div', 'display:none;background:#0d1117;border:1px solid #2d4a6b;border-radius:6px;padding:10px;margin-bottom:6px;box-shadow:0 4px 16px rgba(0,0,0,.5)');
    UI.pill = el('div', 'display:inline-flex;align-items:center;gap:6px;background:#0d1117;border:1px solid #2d4a6b;border-radius:12px;padding:3px 10px;cursor:pointer;user-select:none');
    UI.pill.addEventListener('click', function () { UI.offen = !UI.offen; ui(); });
    UI.box.appendChild(UI.karte); UI.box.appendChild(UI.pill);
    document.body.appendChild(UI.box);
}
function ui() {
    uiBauen();
    if (!UI.box) return;
    // Anmeldefeld nicht bei jeder Statuszeile neu bauen - sonst ist das
    // halb getippte Passwort weg.
    var sig = Z.modus === 'login' ? 'login|' + Z.fehler : '';
    var nurPill = sig && UI.sig === sig;
    UI.sig = sig;
    var farbe = { laeuft: '#4caf50', start: '#4f8cff', aus: '#8a8f98' }[Z.godbot] || '#e0a030';
    if (Z.modus === 'login' || Z.modus === 'doppelt') farbe = '#e05555';
    UI.pill.innerHTML = '';
    UI.pill.appendChild(el('span', 'width:8px;height:8px;border-radius:50%;background:' + farbe));
    UI.pill.appendChild(el('span', 'font-weight:bold', 'Odin PC'));
    UI.pill.appendChild(el('span', 'color:#8fa8c7', Z.hinweis || ''));
    if (nurPill) return;
    var k = UI.karte;
    k.style.display = (UI.offen || Z.modus === 'login' || Z.modus === 'wahl' || Z.modus === 'neu' || Z.modus === 'abgleich') ? 'block' : 'none';
    k.innerHTML = '';
    k.appendChild(el('div', 'font-weight:bold;color:#c9bda9;margin-bottom:6px', 'Odin PC ' + PCV));
    var s = sitzung();
    function zeile(a, b) { var d = el('div', 'margin:2px 0'); d.appendChild(el('span', 'color:#8fa8c7', a + ': ')); d.appendChild(el('span', '', b)); k.appendChild(d); }
    if (s) zeile('Odin', s.email || 'angemeldet');
    if (Z.konto) zeile('Konto', Z.konto.name + ' · ' + Z.konto.world);
    zeile('Gerät', geraetName);
    zeile('GodBot', ({ laeuft: 'läuft', start: 'startet…', aus: 'nicht gestartet' })[Z.godbot] || Z.godbot);
    if (Z.letzte) k.appendChild(el('div', 'margin-top:6px;color:#8fa8c7;font-size:11px;word-break:break-word', Z.letzte));
    if (Z.fehler && Z.fehler !== Z.letzte) k.appendChild(el('div', 'margin-top:4px;color:#e08a8a;font-size:11px;word-break:break-word', Z.fehler));
    var aktionen = el('div', 'margin-top:8px');
    if (Z.modus === 'login') {
        k.appendChild(el('div', 'margin-top:8px;color:#dfe6ee', 'Mit deinem Odin-Konto anmelden (wie in der Web-App). Das Spielpasswort wird nicht gebraucht.'));
        var em = el('input', 'display:block;width:100%;box-sizing:border-box;margin-top:6px;padding:5px;background:#141a26;color:#fff;border:1px solid #2d4a6b;border-radius:4px');
        em.type = 'email'; em.placeholder = 'E-Mail'; em.autocomplete = 'username'; if (s && s.email) em.value = s.email;
        var pw = el('input', em.style.cssText); pw.type = 'password'; pw.placeholder = 'Passwort'; pw.autocomplete = 'current-password';
        k.appendChild(em); k.appendChild(pw);
        var los = function () {
            if (!UI.warte) return;
            var f = UI.warte; UI.warte = null;
            f({ email: em.value.trim(), pw: pw.value });
        };
        pw.addEventListener('keydown', function (e) { if (e.key === 'Enter') los(); });
        aktionen.appendChild(knopf('Anmelden', los, true));
    } else if (Z.modus === 'wahl') {
        k.appendChild(el('div', 'margin-top:8px', 'Welches Odin-Konto gehört zu diesem Spieler?'));
        (Z.wahl || []).forEach(function (a) {
            aktionen.appendChild(knopf(a.name + ' · ' + a.world, function () { var f = UI.warte; UI.warte = null; if (f) f(a); }));
        });
    } else if (Z.modus === 'neu') {
        k.appendChild(el('div', 'margin-top:8px', 'Für ' + Z.neu.pname + ' auf ' + Z.neu.welt + ' gibt es in Odin noch kein Konto.'));
        aktionen.appendChild(knopf('In Odin anlegen', function () { var f = UI.warte; UI.warte = null; if (f) f(true); }, true));
    } else if (Z.modus === 'abgleich') {
        k.appendChild(el('div', 'margin-top:8px', 'Dieser Browser hat eigene GodBot-Einstellungen für diese Welt, Odin ebenfalls. Welcher Stand soll gelten? Der andere wird dabei ersetzt.'));
        aktionen.appendChild(knopf('Odin-Stand übernehmen (empfohlen)', function () { var f = UI.warte; UI.warte = null; if (f) f('server'); }, true));
        aktionen.appendChild(knopf('PC-Stand nach Odin hochladen', function () { var f = UI.warte; UI.warte = null; if (f) f('pc'); }));
    } else if (Z.modus === 'fremd' || Z.modus === 'tab' || Z.modus === 'pause') {
        aktionen.appendChild(knopf('Hier übernehmen', function () { uebernehmen(); }, true));
    } else if (Z.modus === 'laeuft') {
        aktionen.appendChild(knopf('Pausieren & freigeben', function () { pausieren(); }));
    }
    if (window.Notification && Notification.permission === 'default')
        aktionen.appendChild(knopf('Desktop-Warnungen', function () { Notification.requestPermission().then(ui); }));
    if (s && Z.modus !== 'login') aktionen.appendChild(knopf('Abmelden', function () {
        ldel(K.sitzung); ldel(K.team); ldel(K.konto);
        if (Z.modus === 'laeuft' && Z.konto) leaseFreigeben();
        location.reload();
    }));
    k.appendChild(aktionen);
}
function warteAuf(modus, extra) {
    Z.modus = modus; if (extra) Object.keys(extra).forEach(function (x) { Z[x] = extra[x]; });
    return new Promise(function (res) { UI.warte = res; ui(); });
}

// ===================================================================
// Ablauf
// ===================================================================
async function anmeldungSicherstellen() {
    while (true) {
        if (sitzung() && await token()) return;
        Z.hinweis = 'nicht angemeldet';
        var d = await warteAuf('login');
        Z.modus = ''; Z.hinweis = 'melde an…'; ui();
        try {
            sitzungSpeichern(await authPost('token?grant_type=password', { email: d.email, password: d.pw }));
            ldel(K.team); ldel(K.konto);
            Z.fehler = '';
        } catch (e) {
            Z.fehler = 'Anmeldung fehlgeschlagen: ' + e.message;
        }
    }
}
async function uebernehmen() {
    sdel(SK.pause);
    if (!Z.konto) return location.reload();
    try { await leaseHolen(true); } catch (e) { status('Übernehmen fehlgeschlagen: ' + e.message); return; }
    if (bc) bc.postMessage({ t: 'abgeben' });
    if (Z.godbot === 'aus') starten(true);
}
async function pausieren() {
    sset(SK.pause, '1');
    try { if (window.__odinSyncFlush) window.__odinSyncFlush(); } catch (e) { }
    await leaseFreigeben();
    status('GodBot auf diesem PC pausiert, Konto freigegeben', 'WICHTIG');
    setTimeout(function () { location.reload(); }, 800);
}

// Wartend (fremdes Geraet): jede Minute nachfragen; wird die Sperre frei,
// startet GodBot hier. Laufend: jede Minute verlaengern; geht sie an ein
// anderes Geraet verloren, hoert GodBot hier auf (Seite neu laden).
var pflegeTimer = null;
function pflegeStarten() {
    if (pflegeTimer) return;
    pflegeTimer = setInterval(async function () {
        if (!Z.konto || Z.modus === 'pause' || Z.modus === 'tab') return;
        var e;
        try { e = await leaseHolen(false); } catch (err) { return; }
        if (!e) return;
        if (Z.godbot !== 'aus' && !e.erhalten) {
            status('Geräte-Sperre verloren - ' + e.halter + ' hat übernommen. GodBot stoppt hier.', 'WICHTIG');
            try { if (window.__odinSyncFlush) window.__odinSyncFlush(); } catch (x) { }
            setTimeout(function () { location.reload(); }, 1500);
        } else if (Z.godbot === 'aus' && e.erhalten && Z.modus === 'fremd') {
            starten(false);
        }
    }, 60000);
}

async function main() {
    var gd = window.game_data;
    if (!gd || !gd.player || !gd.player.id || !gd.world) return;   // nicht im Spiel
    ui();
    await anmeldungSicherstellen();
    try {
        Z.team = await teamLaden();
        var k = await kontoFinden(gd);
        if (k.wahl) k = kontoMerken(await warteAuf('wahl', { wahl: k.wahl }), weltNorm(gd.world), String(gd.player.id), gd.player.name);
        else if (k.fehlt) {
            await warteAuf('neu', { neu: k });
            var r = await rest('POST', 'game_accounts', [{ team_id: Z.team, name: k.pname, world: k.welt, player_name: k.pname }], 'return=representation');
            k = kontoMerken(r[0], k.welt, String(gd.player.id), k.pname);
            status('Konto in Odin angelegt: ' + k.name + ' · ' + k.world);
        }
        Z.konto = k; Z.modus = '';
        Z.hinweis = k.name + ' · ' + k.world;
    } catch (e) {
        Z.hinweis = 'Fehler';
        status('Anmeldung/Konto fehlgeschlagen: ' + e.message);
        return;
    }
    // Einmal je Tab - jeder Seitenaufruf im Spiel laedt das Skript neu.
    if (!sget('odinpc_verbunden')) { sset('odinpc_verbunden', '1'); status('Odin PC ' + PCV + ' verbunden (' + geraetName + ')'); }
    pflegeStarten();
    if (sget(SK.pause)) { Z.modus = 'pause'; Z.hinweis = 'pausiert'; ui(); return; }
    starten(false);
}

var startLaeuft = false;
async function starten(uebernahme) {
    if (startLaeuft || Z.godbot !== 'aus') return;
    startLaeuft = true;
    try {
        if (!uebernahme) {
            var t = await tabPruefen();
            if (t) { Z.modus = 'tab'; Z.hinweis = 'läuft in anderem Tab'; ui(); return; }
            var e = await darfLaufen();
            if (!e.erhalten) { Z.modus = 'fremd'; Z.hinweis = 'läuft auf ' + e.halter; ui(); return; }
        }
        // Altes GodBot-Skript in Tampermonkey noch aktiv? Dann liefe GodBot
        // doppelt - einmal mit, einmal ohne Odin.
        if (typeof window.godbotCommands === 'function') { doppelt(); return; }
        if (!lget('odin_hydriert')) {
            var roh = await rest('GET', 'godbot_settings?select=skey,value,updated_at&account_id=eq.' + encodeURIComponent(Z.konto.id));
            var stand = {};
            (roh || []).forEach(function (o) { stand[o.skey] = { v: o.value, u: o.updated_at || '' }; });
            Z.serverStand = stand;
            var eigene = [];
            for (var i = 0; i < LS.length; i++) { var kk = LS.key(i); if (kk && /^(tw_|godbot_|gb_)/.test(kk)) eigene.push(kk); }
            if (eigene.length && Object.keys(stand).length) {
                var wahl = await warteAuf('abgleich');
                Z.modus = '';
                if (wahl === 'server') {
                    // Lokale Werte, die Odin auch hat, entfernen; der Loader
                    // fuellt sie danach aus dem Serverstand (nur fuellen).
                    // Botschutz-Zustand bleibt oertlich (NIE_RUNTER im Loader).
                    var n = 0;
                    eigene.forEach(function (x) { if (stand[x] && !/^(tw_bot_|tw_botschutz_|tw_captcha)/.test(x)) { ldel(x); n++; } });
                    status('Abgleich: Odin-Stand gewählt, ' + n + ' örtliche Werte ersetzt');
                } else {
                    Z.hochladenErzwingen = true;
                    status('Abgleich: PC-Stand gewählt, wird nach Odin hochgeladen', 'WICHTIG');
                }
            }
        }
        Z.godbot = 'start'; Z.modus = 'laeuft'; Z.hinweis = Z.konto.name + ' · ' + Z.konto.world;
        tabAktivMelden(uebernahme);
        ui();
        loaderAusfuehren();
        var eigenerMarker = null;
        setTimeout(function () {
            if (typeof window.godbotCommands === 'function') { Z.godbot = 'laeuft'; eigenerMarker = window.godbotCommands; ui(); }
        }, 3000);
        setTimeout(function () {
            if (eigenerMarker && window.godbotCommands !== eigenerMarker) doppelt();
            else if (typeof window.godbotCommands === 'function') { Z.godbot = 'laeuft'; ui(); }
        }, 15000);
    } catch (e) {
        status('Start fehlgeschlagen: ' + e.message);
    } finally {
        startLaeuft = false;
    }
}
function doppelt() {
    Z.modus = 'doppelt'; Z.hinweis = 'altes GodBot-Skript aktiv!'; UI.offen = true;
    status('Achtung: zweites GodBot-Skript in Tampermonkey aktiv - dort „GodBot“ deaktivieren, sonst arbeitet GodBot doppelt');
}

// Loader der App + GodBot. Wird von pc/build_odin_pc.py eingesetzt.
function loaderAusfuehren() {
/*__LOADER__*/
}

function odinPcHochladenErzwingen() {
    if (!Z.hochladenErzwingen) return;
    Z.hochladenErzwingen = false;
    var n = 0;
    for (var i = 0; i < LS.length; i++) {
        var k = LS.key(i);
        if (k && /^(tw_|godbot_|gb_)/.test(k)) { try { LS.setItem(k, RAW_GET.call(LS, k)); n++; } catch (e) { } }
    }
    status('Abgleich: ' + n + ' PC-Werte zum Hochladen vorgemerkt');
}

function odinPcGodBotStarten() {
/*__GODBOT__*/
}

main().catch(function (e) { status('Odin PC Fehler: ' + (e && e.message)); });
})();
