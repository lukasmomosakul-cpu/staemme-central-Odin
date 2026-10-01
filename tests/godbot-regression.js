// GodBot-Regressionspruefung gegen echte Seitenquellen (seitenquellen/).
// Laeuft in GitHub Actions bei jedem Push auf godbot/ oder seitenquellen/.
// Jede Pruefung nutzt die ECHTE Funktion aus GodBot.user.js (per acorn
// herausgeschnitten) - keine nachgebauten Kopien.
'use strict';
const fs = require('fs'), path = require('path');
const acorn = require('acorn');
const { parseHTML } = require('linkedom');
const ROOT = path.resolve(__dirname, '..');
const GB = process.argv[2] || path.join(ROOT, 'godbot', 'GodBot.user.js');
const SQ = path.join(ROOT, 'seitenquellen');
const src = fs.readFileSync(GB, 'utf8');
const ast = acorn.parse(src, { ecmaVersion: 'latest', allowReturnOutsideFunction: true, allowHashBang: true });
const fns = {};
(function w(n) { if (!n || typeof n !== 'object') return; if (n.type === 'FunctionDeclaration' && n.id && !fns[n.id.name]) fns[n.id.name] = src.slice(n.start, n.end); for (const k in n) { const v = n[k]; if (Array.isArray(v)) v.forEach(w); else if (v && typeof v.type === 'string') w(v); } })(ast);
const fn = (name) => { if (!fns[name]) throw new Error('Funktion fehlt: ' + name); return eval('(' + fns[name] + ')'); };
const seite = (muster) => {
  const f = fs.readdirSync(SQ).find(x => x.includes(muster));
  if (!f) throw new Error('Seitenquelle fehlt: ' + muster);
  const s = fs.readFileSync(path.join(SQ, f), 'utf8');
  const { document, window } = parseHTML(s.indexOf('<html') >= 0 ? s.slice(s.indexOf('<html')) : '<html><body>' + s + '</body></html>');
  if (!document.scripts) Object.defineProperty(document, 'scripts', { get() { return [...document.querySelectorAll('script')]; } });
  return { d: document, w: window, roh: s };
};
global.window = global; global.UNIT_STATS = {}; global.tabbenUnitShortLabel = (u) => u; global.BELOHNUNG_RES = ['wood', 'stone', 'iron']; global.BELOHNUNG_MAX_JE_LAUF = 20;
let ok = 0, fehl = 0;
const pruefe = (name, f) => { try { const r = f(); if (r === true) { ok++; console.log('  OK   ' + name); } else { fehl++; console.log('  FEHL ' + name + ' -> ' + JSON.stringify(r)); } } catch (e) { fehl++; console.log('  FEHL ' + name + ' -> ' + e.message); } };

console.log('GodBot-Regression: ' + path.basename(GB));
// Befehle / Bestaetigung
pruefe('Zielabgleich Karte (Formular statt Sprungfeld)', () => { const v = fn('attackPlannerVerifyConfirmTarget'); const { d } = seite('08_de259_map'); return v(d, { toCoord: '305|548' }).ok === true && v(d, { toCoord: '1|1' }).ok === false || 'falsch'; });
pruefe('Laufzeit Angriff 1527 s', () => fn('readTabbenTravelDuration')(seite('08_de259_map').d) === 1527 || 'abweichend');
pruefe('Laufzeit Unterstuetzung 849 s', () => fn('readTabbenTravelDuration')(seite('09_de259_map').d) === 849 || 'abweichend');
pruefe('Barbarendorf-Besitzer 0', () => fn('readTabbenConfirmTargetOwnerId')(seite('08_de259_map').d) === 0 || 'abweichend');
pruefe('Abbruch-URL byte-gleich mit Spiel-Link', () => { const { d, roh } = seite('15_de259_place'); global.game_data = { csrf: (roh.match(/"csrf":"([^"]+)"/) || [])[1] }; const a = d.querySelector('a.command-cancel[data-id]'); return fn('buildTabbenCancelUrl')(a.getAttribute('data-home'), a.getAttribute('data-id')) === a.getAttribute('href') || 'abweichend'; });
pruefe('Versammlungsplatz: Desktop-Ziel + Formularcheck', () => { const { d, w } = seite('15_de259_place'); global.Event = w.Event; const sp = d.querySelector('input.unitsInput[name="spear"]'); sp.setAttribute('data-all-count', '10'); sp.value = '4'; const at = { toCoord: '305|548', troops: { spear: 4 } }; fn('attackPlannerFillDesktopTarget')(d, at); fn('attackPlannerFillMobileTarget')(d, at); return fn('attackPlannerCheckForm')(d, at).ok === true || 'nicht ok'; });
// Raubzug
pruefe('Sammelseite 1: 50 Doerfer + Weiter-Link', () => { const { d } = seite('17_de256_place-scavenge'); const r = fn('parseScavengeMassDoc')(d); return (r && Object.keys(r).length === 50 && !!d.querySelector('a.paged-nav-item[rel="next"]')) || 'abweichend'; });
pruefe('Sammelseite 2: 12 Doerfer, letzte Seite', () => { const { d } = seite('18_de256_place-scavenge'); const r = fn('parseScavengeMassDoc')(d); return (r && Object.keys(r).length === 12 && !d.querySelector('a.paged-nav-item[rel="next"]')) || 'abweichend'; });
// Belohnungen
pruefe('Belohnungsliste lesbar (2 sichtbar, rewards_all)', () => { global.belohnungJsonWertLesen = fn('belohnungJsonWertLesen'); const l = fn('belohnungListeAusDialog')(seite('13_de259_overview').roh); return (l && l.sichtbar.length === 2 && Object.keys(l.alle).length >= 1) || 'abweichend'; });
// Export
pruefe('Berichte mobil: Liste ohne Weiterleiten-Knopf, mit Kaesten', () => { const f = seite('19_de259_report').d.querySelector('form[action*="mode=process_reports"]'); return (!!f && !f.querySelector('input[type="submit"][name="forward"]') && f.querySelectorAll('input[type="checkbox"][name^="id_"]').length > 0) || 'abweichend'; });
pruefe('Berichte: Zwischenseite publish_and_forward_many', () => { const f = seite('22_de259_report-process').d.querySelector('form[action*="publish_and_forward_many"]'); return (!!f && !!f.querySelector('input[type="submit"]')) || 'abweichend'; });
pruefe('Berichte: [report]-Codes auf der Mail-Seite gefunden', () => { const t = fn('twSucheExportText')(seite('07_de259_mail').d, /\[report\]/); return (!!t && (t.match(/\[report\]/g) || []).length === 4) || 'abweichend'; });
pruefe('Angriffe mobil mit Eintraegen: #incomings_form + reqdef', () => { const f = seite('04_de256_Eintreffende').d.querySelector('#incomings_form'); return (!!f && !!f.querySelector('input[name="reqdef"]')) || 'abweichend'; });

console.log(`\n${ok} bestanden, ${fehl} fehlgeschlagen`);
process.exit(fehl ? 1 : 0);
