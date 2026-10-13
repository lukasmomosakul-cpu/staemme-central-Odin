// Bauvorlagen-Code aus Die Stämme ([construction_template]…[/construction_template])
// in die Odin-Kette "gebaeude:stufen;…" umrechnen (2.0.59, 13.10.2026).
//
// Format belegt am 28.08.2026 an einer echten Vorlage ("1. RaubzugStart",
// Account-Manager-Export), Schritt fuer Schritt gegen die Bauschleife im
// Spiel nachgerechnet (GodBot bauVorlageDekodieren, damals v269-v289):
//   Byte 0-1    Laenge n der Auftragsliste in Bytes (little endian, gerade)
//   Byte 2..    n/2 Paare (Gebaeude-Kennung, Stufen)
//   danach      Zusatzbytes, dann Felder getrennt durch F4 80 80 80:
//               Name, Art
// Kennung -> Gebaeude in genau dieser Reihenfolge (GodBot BAU_GEBAEUDE).
// 4 und 5 (Kirche, Erste Kirche) sind nur durch Ausschluss belegt - nie
// an einer echten Vorlage mit Kirche gesehen. Deshalb wird gewarnt.

export const STAMMES_GEBAEUDE = [
  'main', 'barracks', 'stable', 'garage', 'church', 'church_f',
  'watchtower', 'snob', 'smith', 'place', 'statue', 'market',
  'wood', 'stone', 'iron', 'farm', 'storage', 'hide', 'wall',
] as const;

const UNBESTAETIGT = new Set(['church', 'church_f']);
const TRENNER = [0xf4, 0x80, 0x80, 0x80];

export type StammesVorlage = {
  queue: string;
  name: string;
  auftraege: number;
  stufen: number;
  warnungen: string[];
};

function base64Bytes(b64: string): Uint8Array {
  const s = atob(b64);
  const out = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i);
  return out;
}

function trennerAb(a: Uint8Array, von: number): number {
  for (let i = von; i + 3 < a.length; i++) {
    if (a[i] === TRENNER[0] && a[i + 1] === TRENNER[1] && a[i + 2] === TRENNER[2] && a[i + 3] === TRENNER[3]) return i;
  }
  return -1;
}

// Wirft einen Error mit lesbarer Begruendung, wenn der Text kein gueltiger
// Bauvorlagen-Code ist. Raten wird nichts: unbekannte Kennung = Abbruch.
export function stammesBauCodeLesen(text: string): StammesVorlage {
  let roh = String(text ?? '').trim();
  const bb = roh.match(/\[construction_template\]([\s\S]*?)\[\/construction_template\]/i);
  if (bb) roh = bb[1];
  roh = roh.replace(/\s+/g, '');
  if (!roh) throw new Error('Kein Code eingefügt.');
  if (!/^[A-Za-z0-9+/]+={0,2}$/.test(roh)) throw new Error('Das ist kein Bauvorlagen-Code (kein Base64-Text).');

  let bin: Uint8Array;
  try { bin = base64Bytes(roh); } catch { throw new Error('Das ist kein gültiger Base64-Text.'); }
  if (bin.length < 4) throw new Error('Code zu kurz für eine Bauvorlage.');

  const n = bin[0] | (bin[1] << 8);
  if (n === 0) throw new Error('Die Vorlage enthält keine Aufträge.');
  if (n % 2 !== 0 || 2 + n > bin.length) {
    throw new Error(`Längenangabe (${n}) passt nicht zum Code (${bin.length} Bytes) – unvollständig kopiert?`);
  }

  const teile: string[] = [];
  const warnungen: string[] = [];
  const unbest = new Set<string>();
  let stufen = 0;
  for (let i = 0; i < n; i += 2) {
    const kennung = bin[2 + i];
    const st = bin[3 + i];
    const g = STAMMES_GEBAEUDE[kennung];
    if (!g) throw new Error(`Unbekannte Gebäudekennung ${kennung} in Auftrag ${i / 2 + 1}.`);
    if (st < 1) throw new Error(`Auftrag ${i / 2 + 1} (${g}) hat 0 Stufen.`);
    if (UNBESTAETIGT.has(g)) unbest.add(g);
    teile.push(`${g}:${st}`);
    stufen += st;
  }
  if (unbest.size) {
    warnungen.push(`Enthält ${[...unbest].join(', ')} – diese Kennung ist noch nicht an einer echten Vorlage bestätigt. Nach dem Senden im Account-Manager kontrollieren.`);
  }

  // Name aus dem ersten Feld nach dem Trenner (nur Vorschlag).
  let name = '';
  const t = trennerAb(bin, 2 + n);
  if (t >= 0) {
    const ende = trennerAb(bin, t + 4);
    try {
      name = new TextDecoder('utf-8').decode(bin.slice(t + 4, ende < 0 ? bin.length : ende)).trim();
    } catch { name = ''; }
  }

  return { queue: teile.join(';'), name: name.slice(0, 60), auftraege: n / 2, stufen, warnungen };
}
