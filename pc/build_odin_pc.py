#!/usr/bin/env python3
"""Erzeugt OdinPC.user.js (Tampermonkey) aus drei Teilen:

  pc/odin-pc.js                    Odin-PC-Schicht (Anmeldung, Sperre, OdinNative)
  native/patch-godbot-loader.sh    Loader der App - unveraendert bis auf den Schluss
  godbot/GodBot.user.js            GodBot, in eine Funktion eingepackt

Aufruf:  python3 pc/build_odin_pc.py [ausgabe]   (Standard: pc/OdinPC.user.js)

Version: <GodBot-Version>.<PC_REV>. PC_REV bei jeder Aenderung an der
Schicht erhoehen; bei neuem GodBot wieder auf 1 setzen.
"""
import io, re, sys, os

PC_REV = 1
ANON = ("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNqcmNvb21odXVhaGF5enR6ZGdjIiwi"
        "cm9sZSI6ImFub24iLCJpYXQiOjE3ODg3NzM4NzIsImV4cCI6MjEwNDM0OTg3Mn0.XvgEyjfhczIM0hKnVcHIOPJ4MSfndoshw0oOuWcmDoM")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def lies(p): return io.open(os.path.join(ROOT, p), encoding='utf-8', newline='').read()
def genau_einmal(s, teil, name):
    n = s.count(teil)
    if n != 1: sys.exit('Abbruch: %s kommt %d-mal vor (erwartet 1)' % (name, n))

schicht = lies('pc/odin-pc.js')
# Zweites Argument (nur fuer Tests): anderer GodBot-Quelltext.
gb = io.open(sys.argv[2], encoding='utf-8', newline='').read() if len(sys.argv) > 2 else lies('godbot/GodBot.user.js')
sh = lies('native/patch-godbot-loader.sh')

m = re.search(r'@version\s+(\S+)', gb)
if not m: sys.exit('Abbruch: GodBot-Version nicht gefunden')
version = '%s.%d' % (m.group(1), PC_REV)

# --- Loader aus dem App-Bauskript ------------------------------------------
lm = re.findall(r'js = r"""(.*?)"""', sh, re.S)
if len(lm) != 1: sys.exit('Abbruch: Loader-Block nicht eindeutig (%d)' % len(lm))
loader = lm[0].replace('\r\n', '\n')

# Schluss ersetzen: statt die Teile als /__odin_t_i.js nachzuladen (gibt es
# nur in der App) wird GodBot direkt aufgerufen.
anfang = " // Reihenfolge: erst GodBot (eingebaut)"
ende = " add(0);\n return 'started';"
genau_einmal(loader, anfang, 'Loader-Schlussanfang')
genau_einmal(loader, ende, 'Loader-Schlussende')
a = loader.index(anfang); e = loader.index(ende) + len(" add(0);\n")
schluss = r""" // --- Odin PC: GodBot direkt starten (statt der Teil-Dateien der App) ---
 // Ohne stand() behaelt GodBot sein schwebendes Fenster - im Browser gibt
 // es keine GodBot-Leiste der App (odinEingebettet() in GodBot).
 try{ delete window.Odin.stand; }catch(e){}
 odinPcHochladenErzwingen();
 var gbStart=Date.now(), gbMs=-1;
 try{ odinPcGodBotStarten(); gbMs=Date.now()-gbStart; }
 catch(e){ window.__odinErrMsg='JS-Fehler beim Start: '+(e&&e.message); }
 var letztesUrteil='', spaet=false;
 var melde=function(t){ if(t===letztesUrteil)return; letztesUrteil=t; OdinNative.status(t); };
 var verdict=function(){try{
  if(window.__odinErrMsg){melde(window.__odinErrMsg);return;}
  if(typeof window.godbotCommands==='function'){melde('aktiv (GodBot '+gbMs+' ms)');return;}
  if(document.getElementById('tw-gate-input')){melde('wartet auf Freischaltcode');return;}
  if(!spaet)return;
  melde('Achtung: GodBot ausgefuehrt, aber nicht gestartet (Marker fehlt)');
 }catch(e){}};
 setTimeout(verdict,3000); setTimeout(function(){spaet=true;verdict();},12000);
"""
loader = loader[:a] + schluss + loader[e:]
for platz in ('__TEILE__', '__GODBOT_AN__', '/__odin_t_'):
    if platz in loader: sys.exit('Abbruch: %s steht noch im Loader' % platz)
loader = loader.replace('__VERSION__', 'pc-' + version)

# --- GodBot ohne eigenen Kopf ---------------------------------------------
gb_nl = gb.replace('\r\n', '\n')
km = re.match(r'(// ==UserScript==\n.*?// ==/UserScript==\n)', gb_nl, re.S)
if not km: sys.exit('Abbruch: GodBot-Kopf nicht gefunden')
gb_rumpf = '// (GodBot-Kopf entfernt - Version %s)\n' % m.group(1) + gb_nl[km.end():]
if '==UserScript==' in gb_rumpf: sys.exit('Abbruch: zweiter Skriptkopf in GodBot')

# --- zusammensetzen -------------------------------------------------------
genau_einmal(schicht, '/*__LOADER__*/', 'Loader-Platzhalter')
genau_einmal(schicht, '/*__GODBOT__*/', 'GodBot-Platzhalter')
out = schicht.replace('__PCVERSION__', version).replace('__ANONKEY__', ANON)
out = out.replace('/*__LOADER__*/', loader).replace('/*__GODBOT__*/', gb_rumpf)
out = out.replace('\r\n', '\n')

ziel = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'pc', 'OdinPC.user.js')
io.open(ziel, 'w', encoding='utf-8', newline='\n').write(out)
print('OdinPC %s -> %s (%d Bytes)' % (version, ziel, len(out.encode('utf-8'))))
