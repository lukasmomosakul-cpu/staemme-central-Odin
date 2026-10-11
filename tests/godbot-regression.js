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
global.slotZelleKlasse = fn('slotZelleKlasse'); global.belohnungJsonWertLesen = fn('belohnungJsonWertLesen'); global.parseScavengeVillageObj = fn('parseScavengeVillageObj'); global.slotRohdatenMerken = () => {};
pruefe('Sammelseite 1: gesperrte Slots (is_locked/unlock_time) als gesperrt', () => { const { d } = seite('17_de256_place-scavenge'); const r = fn('parseScavengeMassDoc')(d); return (r['734'].slots[4].locked === true && r['1933'].slots[4].locked === true && r['734'].slots[1].locked === false && r['311'].slots[1].locked === false) || JSON.stringify([r['734'].slots, r['1933'].slots[4]]); });
pruefe('Sammelseite: fehlende Option = gesperrt', () => { const { d } = seite('18_de256_place-scavenge'); const t = [...d.scripts].find(x => x.textContent.includes('new ScavengeMassScreen')); const vid = (t.textContent.match(/\[\{"village_id":(\d+)/) || [])[1]; t.textContent = t.textContent.replace(/"4":\{"base_id":4,"village_id":\d+,"is_locked":false/, '"4x":{"base_id":4,"village_id":0,"is_locked":false'); const r = fn('parseScavengeMassDoc')(d); return (r[vid].slots[4].locked === true && r[vid].slots[1].locked === false) || JSON.stringify(r[vid].slots); });
pruefe('Sammelseite 1: 50 Doerfer + Weiter-Link', () => { const { d } = seite('17_de256_place-scavenge'); const r = fn('parseScavengeMassDoc')(d); return (r && Object.keys(r).length === 50 && !!d.querySelector('a.paged-nav-item[rel="next"]')) || 'abweichend'; });
pruefe('Sammelseite 2: 12 Doerfer, letzte Seite', () => { const { d } = seite('18_de256_place-scavenge'); const r = fn('parseScavengeMassDoc')(d); return (r && Object.keys(r).length === 12 && !d.querySelector('a.paged-nav-item[rel="next"]')) || 'abweichend'; });
pruefe('Einzelseite de261 mobil (ohne Premium): alle 4 Slots gesperrt, 0 Truppen', () => { const { roh } = seite('25_de261_place-scavenge-einzel'); const r = fn('parseScavengeEinzelText')(roh); const v = r && r['17417']; return (v && [1,2,3,4].every(i => v.slots[i].locked === true && v.slots[i].busy === false) && Object.keys(v.homeUnits).length === 0) || JSON.stringify(r); });
pruefe('Einzelseite de261 desktop: gleiches Ergebnis', () => { const { roh } = seite('26_de261_place-scavenge-einzel'); const r = fn('parseScavengeEinzelText')(roh); return (r && [1,2,3,4].every(i => r['17417'].slots[i].locked === true)) || JSON.stringify(r); });
pruefe('Späherbericht de260: Ziel 6590 (558|555), Gebäude, 0 Verluste, Kampfzeit', () => { const { d } = seite('28_de260_report-spaeher'); const z = fn('berichtZielLesen')(d); const ok = z && z.id === '6590' && z.x === 558 && z.y === 555 && z.verluste === 0 && z.gebaeude && z.gebaeude.main === 1 && z.gebaeude.storage === 2 && z.gebaeude.hide === 1 && !('barracks' in z.gebaeude) && new Date(z.zeit).getHours() === 4; return ok || JSON.stringify(z); });
// Belohnungen
pruefe('Belohnungsliste lesbar (2 sichtbar, rewards_all)', () => { global.belohnungJsonWertLesen = fn('belohnungJsonWertLesen'); global.parseScavengeVillageObj = fn('parseScavengeVillageObj'); const l = fn('belohnungListeAusDialog')(seite('13_de259_overview').roh); return (l && l.sichtbar.length === 2 && Object.keys(l.alle).length >= 1) || 'abweichend'; });
// Export
pruefe('Berichte mobil: Liste ohne Weiterleiten-Knopf, mit Kaesten', () => { const f = seite('19_de259_report').d.querySelector('form[action*="mode=process_reports"]'); return (!!f && !f.querySelector('input[type="submit"][name="forward"]') && f.querySelectorAll('input[type="checkbox"][name^="id_"]').length > 0) || 'abweichend'; });
pruefe('Berichte: Zwischenseite publish_and_forward_many', () => { const f = seite('22_de259_report-process').d.querySelector('form[action*="publish_and_forward_many"]'); return (!!f && !!f.querySelector('input[type="submit"]')) || 'abweichend'; });
pruefe('Berichte: [report]-Codes auf der Mail-Seite gefunden', () => { const t = fn('twSucheExportText')(seite('07_de259_mail').d, /\[report\]/); return (!!t && (t.match(/\[report\]/g) || []).length === 4) || 'abweichend'; });
pruefe('Angriffe mobil mit Eintraegen: #incomings_form + reqdef', () => { const f = seite('04_de256_Eintreffende').d.querySelector('#incomings_form'); return (!!f && !!f.querySelector('input[name="reqdef"]')) || 'abweichend'; });

// Rekrutierungsschleife (v588): Restzeit des laufenden Auftrags
const rekrutSeite = (muster) => { const { d, w } = seite(muster); w.unit_managers = { units: { light: { wood: 125, stone: 100, iron: 250, pop: 4, requirements_met: true }, spear: { wood: 50, stone: 30, iron: 10, pop: 1, requirements_met: true } } }; w.game_data = { village: { wood: 1000, stone: 1000, iron: 1000, pop: 100, pop_max: 200 } }; return fn('rekrutSeiteLesen')(w, d); };
pruefe('Stall mobil, 1 Auftrag: 2 LKav, Rest 0:21:00', () => { const s = rekrutSeite('29_de260_stable-schleife'); const q = s.schlange; return (q.length === 1 && q[0].einheit === 'light' && q[0].anzahl === 2 && q[0].restMs === 1260000) || JSON.stringify(q); });
pruefe('Stall mobil, 2 Auftraege: laufender Rest 0:26:23, zweiter ohne Timer (Mitschnitt gekuerzt)', () => { const { d } = seite('30_de260_stable-schleife'); const q = rekrutSeite('30_de260_stable-schleife').schlange; const zweiter = d.querySelector('.queueItem[data-order="60992"]'); return (q[0].anzahl === 3 && q[0].restMs === 1583000 && !!zweiter && !zweiter.querySelector('span.timer') && /2 Leichte Kavallerie/.test(zweiter.textContent)) || JSON.stringify(q); });
pruefe('Kaserne desktop: 1 Speer, Rest 0:10:06', () => { const q = rekrutSeite('31_de259_barracks-schleife').schlange; return (q.length === 1 && q[0].einheit === 'spear' && q[0].anzahl === 1 && q[0].restMs === 606000) || JSON.stringify(q); });
pruefe('Volle Schleife: warten bis Platz frei (26:23)', () => { global.REKRUT_MAX_AUFTRAEGE = 2; const s = rekrutSeite('30_de260_stable-schleife'); s.schlange = [s.schlange[0], { id: '60992', einheit: 'light', anzahl: 2, restMs: null }]; s.trainLink = '/x'; s.popFrei = 100; const r = fn('naechsterRekrutSchritt')('6863', 'stable', s, { light: 200 }); return (r.art === 'warten' && r.freiInMs === 1583000 && /Platz frei in 27 Min/.test(r.grund)) || JSON.stringify(r); });

// GodBot-Farm (v591): Farm-Assistent lesen + Auswahl
global.godFarmTitelLesen = fn('godFarmTitelLesen'); global.godFarmLeistbar = fn('godFarmLeistbar'); global.GODFARM_MAX_ANGRIFFE = 40;
const farmSeite = (m) => { const { d, roh } = seite(m); return fn('godFarmSeiteLesen')(d, roh, { x: 559, y: 552 }); };
pruefe('Farm-Assistent desktop: 30 Ziele, Versandadresse, Truppen, Vorlagen', () => { const s = farmSeite('33_de260_am_farm'); return (s.ok && s.ziele.length === 30 && /ajaxaction=farm&json=1/.test(s.sendLink) && s.einheiten.light === 7 && s.vorlagen['1750'].beute === 80 && s.vorlagen['1766'].einheiten.light === 3 && s.seiten === 1) || JSON.stringify([s.fehler, s.seiten, s.vorlagen]); });
pruefe('Farm-Assistent mobil: gleiche Ziele/Koordinaten, 6463 volle Beute + 2 laufend', () => { const m = farmSeite('32_de260_am_farm'), dd = farmSeite('33_de260_am_farm'); const z = m.ziele.find(q => q.id === '6463'); return (m.ok && m.ziele.length === 30 && dd.ziele.every(q => m.ziele.some(r => r.id === q.id && r.x === q.x && r.y === q.y)) && z.voll === true && z.laufend === 2) || JSON.stringify(z); });
pruefe('GodBot-Farm Auswahl (v594): fremd laufende im Uebergang aus, nach Entfernung, Truppen nicht ueberzogen', () => { const s = farmSeite('33_de260_am_farm'); const a = fn('godFarmAuswahl')(s, { abstandMin: 15, maxFelder: 20 }, {}, Date.now()); let sp = 0, l = 0; a.plan.forEach(p => { const v = s.vorlagen[p.vorlageId].einheiten; sp += v.spy || 0; l += v.light || 0; }); return (a.gruende.laufend === 22 && a.plan.length === 3 && a.plan.every((p, i, r) => !i || r[i - 1].ziel.dist <= p.ziel.dist) && sp <= 3 && l <= 7) || JSON.stringify([a.gruende, a.plan.map(p => p.ziel.id + p.art)]); });
pruefe('GodBot-Farm Abstand zwischen Ankuenften: eigener laufender Angriff ist kein Ausschluss', () => { const s = farmSeite('33_de260_am_farm'); s.einheiten = { light: 20, spy: 5 }; const j = Date.now(); const z = s.ziele.find(q => q.id === '5940'); const lz = z.vorlagen.A.laufzeitMs; const nah = fn('godFarmAuswahl')(s, { abstandMin: 15, maxFelder: 20 }, { '5940': j + 2 * 60000 }, j); const ok = fn('godFarmAuswahl')(s, { abstandMin: 15, maxFelder: 20 }, { '5940': j - 6 * 60000 }, j); const p = ok.plan.find(q => q.ziel.id === '5940'); return (lz === 600000 && !nah.plan.some(q => q.ziel.id === '5940') && !!p && p.ankunft === j + lz) || JSON.stringify([lz, nah.gruende, ok.plan.map(q => q.ziel.id)]); });

console.log(`\n${ok} bestanden, ${fehl} fehlgeschlagen`);
process.exit(fehl ? 1 : 0);
