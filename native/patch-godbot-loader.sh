#!/usr/bin/env bash
set -euo pipefail
# Odin GodBot loader.
#
# GodBot ist fester Bestandteil der App: die Quelle liegt im Repo unter
# godbot/GodBot.user.js und wird beim Bauen als Asset in die APK gelegt.
# Zur Laufzeit wird nichts mehr aus dem Gist geholt.
#
# Zwei Grenzen bestimmen dieses Design:
#  1. GodBot ist ~730 KB. So ein String durch WebView.evaluateJavascript zu
#     schicken schlaegt still fehl (Binder-Limit).
#  2. Die Spielseite kann per CSP (connect-src) ein fetch() auf fremde Hosts
#     blockieren.
# Deshalb wird das Skript ueber shouldInterceptRequest unter der GLEICHEN
# Origin ausgeliefert (/__odin_godbot.js) und per <script src> eingebunden.
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" || { echo 'GodBot loader: GameWebViewActivity.java not found'; exit 1; }
mkdir -p app/src/main/assets
cp ../godbot/GodBot.user.js app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
grep -q '==UserScript==' app/src/main/assets/godbot.user.js
rm -f app/src/main/assets/odin-test.user.js
VERSION=$(tr -d '[:space:]' < ../VERSION)
python3 - "$TARGET" "$VERSION" <<'PY'
from pathlib import Path
import sys, json

p = Path(sys.argv[1]); version = sys.argv[2]; s = p.read_text()

js = r"""
(function(){try{
 if(window.__odinGodBot)return 'already'; window.__odinGodBot=1;
 var p='odin_gm_';
 function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}
 function st(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}
 window.unsafeWindow=window;
 window.GM_info=window.GM_info||{script:{name:'GodBot',version:'__VERSION__'}};
 window.GM_getValue=window.GM_getValue||g;
 window.GM_setValue=window.GM_setValue||st;
 window.GM_deleteValue=window.GM_deleteValue||function(k){try{localStorage.removeItem(p+k)}catch(e){}};
 window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}}catch(e){}return a};
 window.GM_addStyle=window.GM_addStyle||function(c){var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x};
 window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){};
 window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||function(o){try{var z={status:200,responseText:OdinNative.httpGet(String(o.url)),response:''};z.response=z.responseText;if(o.onload)o.onload(z);return z}catch(e){if(o.onerror)o.onerror({status:0,error:e});return{abort:function(){}}}};
 // Ein Fehler beim Auswerten von GodBot wuerde sonst nur in der Konsole landen.
 // Ersten Fehler festhalten. Frueher wurde die Meldung von der spaeteren
 // Statuspruefung ueberschrieben - genau die Information ging dabei verloren.
 window.addEventListener('error',function(ev){try{if(window.__odinErrMsg)return;
  var m=(ev.error&&ev.error.message)||ev.message||'?';
  var w=(ev.filename||'')+':'+(ev.lineno||0);
  window.__odinErrMsg='JS-Fehler: '+m+' @'+w;
  OdinNative.status(window.__odinErrMsg);}catch(e){}},true);
 window.addEventListener('unhandledrejection',function(ev){try{if(window.__odinErrMsg)return;
  window.__odinErrMsg='Promise-Fehler: '+(ev.reason&&ev.reason.message?ev.reason.message:ev.reason);
  OdinNative.status(window.__odinErrMsg);}catch(e){}});
 // GodBot richtet Bruecken wie Object.defineProperty(window,'Timing',{get:...})
 // ein. Unter Tampermonkey laufen die in einer Sandbox, hier im Seitenkontext
 // hat das Spiel 'Timing' bereits nicht-konfigurierbar definiert -> TypeError,
 // und das Skript bricht in Zeile 24 ab. Deshalb fuer window tolerant machen.
 if(!window.__odinDefineFix){
  window.__odinDefineFix=1;
  var _odp=Object.defineProperty;
  Object.defineProperty=function(o,prop,desc){
   // Reine Getter-Bruecken auf window uebergehen. GodBot baut sie so:
   //   const globalWin = typeof unsafeWindow!=='undefined' ? unsafeWindow : window;
   //   Object.defineProperty(window,'game_data',{get:()=>globalWin.game_data||null});
   // Unter Tampermonkey ist window die Sandbox und unsafeWindow die Seite.
   // Hier sind beide dasselbe Objekt, der Getter ruft sich also selbst auf
   // -> 'Maximum call stack size exceeded'. Die Spielobjekte liegen ohnehin
   // schon auf window, die Bruecke ist im Seitenkontext ueberfluessig.
   if(o===window && desc && typeof desc.get==='function' && !desc.set){
    try{if(!window.__odinSkipped)window.__odinSkipped=[];window.__odinSkipped.push(prop);}catch(e0){}
    return o;
   }
   try{ return _odp(o,prop,desc); }
   catch(err){
    if(o!==window)throw err;
    try{OdinNative.status('Bruecke uebersprungen: '+prop);}catch(e3){}
    return o;
   }
  };
 }
 // --- Downloads ------------------------------------------------------------
 // GodBot speichert Protokolle ueber einen Blob und einen <a download>-Klick.
 // In Firefox geht das, in einer WebView passiert nichts: blob:-Adressen
 // erreichen den Download-Weg von Android gar nicht erst. Deshalb den Klick
 // abfangen, den Inhalt selbst lesen und nativ ablegen.
 (function(){
  document.addEventListener('click',function(e){
   try{
    var ziel=e.target;
    var a=ziel&&ziel.closest?ziel.closest('a[download]'):null;
    if(!a||!a.href)return;
    e.preventDefault(); e.stopPropagation();
    var name=a.getAttribute('download')||'odin.txt';
    fetch(a.href).then(function(r){return r.text();}).then(function(t){
     OdinNative.saveText(String(name),String(t));
    }).catch(function(err){
     try{ OdinNative.status('Download fehlgeschlagen: '+err); }catch(_){}
    });
   }catch(err){}
  },true);
 })();
 // --- Benachrichtigungen ---------------------------------------------------
 // GodBot verschickt ueber sendDiscordNotification()/postDiscordAlert() an eine
 // Webhook-URL aus tw_settings. Die Funktionen liegen in der IIFE und sind von
 // aussen nicht erreichbar - deshalb wird die ausgehende Anfrage abgefangen und
 // zusaetzlich als Odin-Meldung an alle Geraete verteilt. Discord selbst bleibt
 // unberuehrt, wer es weiter nutzen will, kann es eingetragen lassen.
 window.odinNotify=function(title,body,level){
  try{ return OdinNative.notify(String(title||'Odin'),String(body||''),String(level||'info')); }
  catch(e){ return false; }
 };
 (function(){
  var isHook=/discord(app)?\.com\/api\/webhooks/i;
  function mirror(body){
   try{
    var d=typeof body==='string'?JSON.parse(body):body;
    var e=d&&d.embeds&&d.embeds[0];
    var title=(e&&e.title)||d.content||'GodBot';
    var desc=(e&&e.description)||'';
    if(e&&e.fields)for(var i=0;i<e.fields.length;i++)
     desc+=(desc?' · ':'')+e.fields[i].name+': '+e.fields[i].value;
    // Discord-Farben: Rot 0xE74C3C, Orange 0xE67E22, Gruen 0x2ECC71, Blau 0x3498DB.
    // Ein Schwellwert auf die Zahl trifft daneben - deshalb den Rotanteil pruefen.
    // Nur echte Warnungen vibrieren (Rotanteil der Embed-Farbe). Routine -
    // Farmen, Raubzug, Statusmeldungen - laeuft still auf dem leisen Kanal.
    // Ausdrueckliche Liste statt Embed-Farbe plus Stichwort. Das alte Muster
    // verfehlte ausgerechnet die Meldungen mit echtem Schaden: "gesperrt"
    // enthaelt nicht "sperre", und "Rausstellen: manueller Rueckruf noetig"
    // sowie "Entscheidung noetig" trafen gar nichts - seit 1.54 liefen alle
    // drei stumm durch. Gegen alle 27 GodBot-Titel geprueft.
    var z=String(title||'')+' '+String(desc||''), lvl='info';
    if(/entwarnung|gelöst|geloest|eingestellt/i.test(String(title||''))) lvl='info';
    else if(/botschutz|captcha|gesperrt|sperre|ag-alarm|rückruf|rueckruf|entscheidung nötig|abgebrochen|übernommen|fehler|abbruch/i.test(z)) lvl='warn';
    else if(/gestoppt/i.test(String(title||''))&&!/manuell/i.test(String(desc||''))) lvl='warn';
    window.odinNotify(title,desc,lvl);
   }catch(err){}
  }
  var of=window.fetch;
  if(of)window.fetch=function(u,o){
   try{ if(isHook.test(String(u&&u.url?u.url:u))&&o&&o.body)mirror(o.body); }catch(e){}
   return of.apply(this,arguments);
  };
  var ox=XMLHttpRequest.prototype.open, os=XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open=function(m,u){ this.__odinUrl=String(u||''); return ox.apply(this,arguments); };
  XMLHttpRequest.prototype.send=function(b){
   try{ if(isHook.test(this.__odinUrl||'')&&b)mirror(b); }catch(e){}
   return os.apply(this,arguments);
  };
 })();
 // --------------------------------------------------------------------------
 // --- Einstellungsabgleich -------------------------------------------------
 // GodBot legt seine Einstellungen in localStorage ab. Wird der vor dem Laden
 // aus Supabase befuellt und werden Schreibzugriffe zurueckgespiegelt, ergibt
 // sich der Geraeteabgleich, ohne GodBot selbst anzufassen. Der Ingame-
 // Notizblock wird damit als Transportweg ueberfluessig.
 var SYNC_PREFIX=/^(tw_|godbot_|gb_)/;
 // tw_console_log ist ein reines Fehlerprotokoll und war mit ~288 KB der
 // groesste Posten im Abgleich - er wird bei jeder Aenderung mitgeschickt,
 // ohne dass ihn jemand liest. Ebenso der Zwischenspeicher fuer Produktion.
 // Weder Positiv- noch Ausschlussliste: beide gehen zwangslaeufig schief.
 // Die Ausschlussliste hinkte hinterher (GodBot fuehrt rund achtzig
 // Schluessel), die Positivliste uebersah stillschweigend Neues - zuletzt
 // tw_attack_scavenge_profiles, weshalb ohne Profile kein Raubzug lief.
 //
 // Stattdessen selbstlernend: abgeglichen wird alles mit tw_-Praefix, ausser
 // was sich nachweislich staendig aendert. Laufzeitzustand schreibt im
 // Sekundentakt, Einstellungen und Plaene nicht.
 // Schreiben am Spiegel vorbei. Muss VOR jeder Verwendung stehen: bisher war
 // origSetRoh erst weiter unten in einer anderen Funktion definiert, weshalb
 // sowohl der Volatilitaets-Merker als auch das Hydrieren beim Zugriff warfen.
 // Der Fehler wurde verschluckt - daher "Abgleich: 0 uebernommen" und die
 // 341 identischen Meldungen fuer denselben Schluessel.
 var ROH_SETZEN=Storage.prototype.setItem;
 function rohSetzen(k,v){ ROH_SETZEN.call(localStorage,k,String(v)); }
 var schonGemeldet={};
 var VOLATIL_SCHWELLE=5, VOLATIL_FENSTER=180000;   // 5 Schreibzugriffe in 3 min
 var schreibZaehler={};
 // Diese gelten immer als Nutzlast, auch wenn ein Import sie mehrfach
 // hintereinander schreibt.
 var IMMER=['tw_settings','tw_build_templates','tw_build_plans','tw_build_assign',
  'tw_troop_templates','tw_troop_plans','tw_troop_assign','tw_attack_plans',
  'tw_tabben_plan','tw_attack_scavenge_profiles','tw_scavenge_options_config',
  'tw_scavenge_mode','tw_scavenge_min_value','tw_mass_support','tw_mass_single_run',
  'tw_fake_vorlagen','tw_fake_quelle','tw_fake_tarnen','tw_village_groups_cache',
  'tw_am_template_catalog','tw_am_assignments',
  'tw_farm_template_counts','tw_farm_template_units'];
 // Nur hochladen: der Wecker und die Uebersicht brauchen sie, uebernommen
 // werden duerfen sie nie - sonst kippt der Stand des zweiten Geraets.
 var NUR_HOCH=['tw_next_recheck_at','tw_loop_active','tw_scavenge_slots','tw_aktivitaet'];

 function istVolatil(k){
  if(IMMER.indexOf(k)>=0)return false;
  try{ if(localStorage.getItem('odin_vol_'+k))return true; }catch(e){}
  var jetzt=Date.now(), z=schreibZaehler[k];
  if(!z||jetzt-z.seit>VOLATIL_FENSTER){ schreibZaehler[k]={seit:jetzt,n:1}; return false; }
  z.n++;
  if(z.n>=VOLATIL_SCHWELLE){
   // Einmal erkannt, dauerhaft gemerkt - spart die Zaehlung beim naechsten Start.
   try{ rohSetzen('odin_vol_'+k,'1'); }catch(e){}
   // Einmal je Schluessel melden, nicht bei jedem Schreibzugriff.
   if(!schonGemeldet[k]){ schonGemeldet[k]=1;
    try{ OdinNative.status('nicht abgeglichen (Laufzeitwert): '+k); }catch(e){} }
   return true;
  }
  return false;
 }
 // Harte Sperre unabhaengig von der Volatilitaet: diese Schluessel sind
 // reine Protokolle und werden gross (tw_console_log lag bei 288 KB). Die
 // Volatilitaetsregel greift erst nach fuenf Schreibzugriffen - bis dahin
 // waeren sie laengst hochgeladen.
 var NIE=/^(tw_console_log|tw_debug_log|tw_request_log)$/;
 // Botschutz-Zustand darf NIE uebernommen werden. Diese Schluessel aendern
 // sich selten, entgehen also der Volatilitaetserkennung - ein alter
 // Serverstand von tw_bot_gesperrt_seit wuerde GodBot beim naechsten Oeffnen
 // wieder in den gesperrten Zustand versetzen, obwohl die Sperre laengst
 // geloest ist. Hochladen bleibt erlaubt, damit man den Verlauf sieht.
 var NIE_RUNTER=/^(tw_bot_|tw_botschutz_|tw_captcha)/;
 function sollHoch(k){
  if(!SYNC_PREFIX.test(k)||NIE.test(k))return false;
  if(NUR_HOCH.indexOf(k)>=0)return true;
  return !istVolatil(k);
 }
 function sollRunter(k){
  if(!SYNC_PREFIX.test(k)||NIE.test(k)||NIE_RUNTER.test(k))return false;
  if(NUR_HOCH.indexOf(k)>=0)return false;
  if(IMMER.indexOf(k)>=0)return true;
  try{ return !localStorage.getItem('odin_vol_'+k); }catch(e){ return true; }
 }
 try{
  if(OdinNative.syncReady()){
   // NUR EINMAL je Profil. Bei jedem Seitenaufruf zu hydrieren erzeugt eine
   // Rueckkopplung: GodBot loescht bestimmte Schluessel absichtlich als
   // Erledigt-Markierung, wir schreiben sie aus der Datenbank zurueck, GodBot
   // sieht sie erneut und laeuft wieder los. Im Protokoll sah das als
   // "Abgleich: 1 ergaenzt" bei JEDEM Aufruf aus, dazu ein Seitenaufruf pro
   // Minute - die Dauerschleife des Managers.
   if(localStorage.getItem('odin_hydriert')){
    OdinNative.status('Abgleich: bereits eingerichtet, nur Hochladen');
   }else{
   var loaded=JSON.parse(OdinNative.settingsLoad()||'{}');
   var applied=0, behalten=0;
   for(var k in loaded){ if(!sollRunter(k))continue;
    try{
     var eintrag=loaded[k], wert=eintrag&&eintrag.v!==undefined?eintrag.v:eintrag;
     var eigen=localStorage.getItem(k);
     // Nur fuellen, nie ueberschreiben.
     //
     // Vorher gewann der Server, sobald sein Stand aelter als 90 s jung war.
     // Bei einem Einstellungsblob wie tw_settings kippt damit irgendein
     // frueherer Stand die aktuelle Konfiguration - der Raubzug stand danach
     // wieder auf aus. Ein Blob laesst sich nicht sinnvoll zusammenfuehren,
     // also darf er auch nicht automatisch ersetzt werden.
     //
     // Ein neues Geraet oder ein frisches Profil hat nichts und bekommt
     // deshalb alles. Ein bestehendes behaelt, was es hat.
     if(eigen!==null){ behalten++; continue; }
     if(!wert||wert.length<=2||wert==='null'||wert==='""'){ continue; }
     rohSetzen(k,wert); applied++;
    }catch(e){}
   }
   rohSetzen('odin_hydriert',Date.now());
   OdinNative.status('Erstabgleich: '+applied+' ergaenzt, '+behalten+' oertlich behalten');
   }
  }else{
   OdinNative.status('Abgleich inaktiv (keine Sitzung)');
  }
 }catch(e){ try{OdinNative.status('Abgleich-Fehler: '+e.message)}catch(_){} }

 // Schreibzugriffe sammeln und gebuendelt zurueckschreiben, damit nicht jede
 // Einzelaenderung eine eigene Anfrage ausloest.
 (function(){
  var pending={}, timer=null;
  // Am Prototyp ansetzen, damit auch Schreibzugriffe aus Arbeitsrahmen
  // (iframes) erfasst werden - die haben ein eigenes localStorage-Objekt.
  var origSet=ROH_SETZEN;
  function flush(){
   timer=null;
   var batch=pending; pending={};
   if(!Object.keys(batch).length)return;
   try{ if(OdinNative.syncReady()){
     // Namen statt blosser Anzahl melden - sonst sieht man im Protokoll nicht,
     // WAS gesichert wurde, und kann Rauschen nicht von Nutzlast trennen.
     OdinNative.settingsSave(JSON.stringify(batch));
     OdinNative.status('gesichert: '+Object.keys(batch).join(', ').slice(0,120));
   } }catch(e){}
  }
  var letzterPuls=0;
  // Frueher setzte jeder Schreibvorgang den Timer zurueck. GodBot schreibt
  // dauernd, also lief er nie ab und nichts wurde hochgeladen.
  Storage.prototype.setItem=function(k,v){
   origSet.call(this,k,v);
   if(this!==localStorage)return;
   // Lebenszeichen an die App: solange GodBot arbeitet, schreibt es staendig
   // in den localStorage. Hoert das auf, ist der Durchlauf fertig und das
   // Weckfenster kann schliessen. Auf einmal je Sekunde begrenzt.
   try{ if(SYNC_PREFIX.test(k)){ var n=Date.now(); if(n-letzterPuls>1000){letzterPuls=n;OdinNative.puls();} } }catch(e){}
   try{ if(sollHoch(k)){ pending[k]=String(v);
    try{ rohSetzen('odin_lw_'+k,Date.now()); }catch(e2){}
    if(!timer)timer=setTimeout(flush,4000);   // laeuft ab dem ERSTEN Eintrag
   } }catch(e){}
  };
  window.addEventListener('pagehide',flush);
  window.__odinSyncFlush=flush;
 })();
 // --------------------------------------------------------------------------
 // Reihenfolge: erst GodBot (eingebaut), dann je Zusatzskript dessen
 // @require und das Skript selbst - die duerfen sich auf GodBot stuetzen.
 var tn=__TEILE__, gb=__GODBOT_AN__, urls=[];
 for(var i=0;i<tn;i++)urls.push('/__odin_t_'+i+'.js');
 var done=0;
 function add(i){
  if(i>=urls.length){
   try{var V='__VERSION__';var A=document.querySelectorAll('*');for(var k=0;k<A.length;k++){var e=A[k],t=(e.textContent||'').trim();if(/USERSCRIPT OK/i.test(t)&&e.children.length===0){e.remove();continue}if(/loader aktiv/i.test(t)){e.style.width='fit-content';e.style.maxWidth='calc(100% - 24px)';e.style.display='inline-flex';e.style.padding='6px 10px';e.style.margin='8px';e.style.borderRadius='8px'}}}catch(e){}
   // window.godbotCommands wird von GodBot gesetzt - damit laesst sich
   // 'Datei geladen' von 'Skript wirklich durchgelaufen' unterscheiden.
   function verdict(){try{
    if(window.__odinSkipped&&window.__odinSkipped.length){
     OdinNative.status('Bruecken uebergangen: '+window.__odinSkipped.join(', '));
     window.__odinSkipped=[];
    }
    if(window.__odinErrMsg){OdinNative.status(window.__odinErrMsg);return;}
    // Ohne GodBot gibt es den Marker nicht - dann zaehlt nur, dass alle
    // Teile ohne Fehler durchgelaufen sind.
    if(!gb){OdinNative.status('aktiv ('+done+' Teile, ohne GodBot)');return;}
    if(typeof window.godbotCommands==='function'){OdinNative.status('aktiv ('+done+' Teile)');return;}
    // Kein Fehler geworfen: das Skript lief durch, nur der Marker fehlt.
    OdinNative.status('ausgefuehrt, kein Fehler (Marker fehlt)');
   }catch(e){}}
   setTimeout(verdict,3000); setTimeout(verdict,12000);
   OdinNative.status('geladen ('+done+' Teile), pruefe...');
   return;
  }
  var sc=document.createElement('script');
  sc.src=urls[i]; sc.async=false;
  sc.onload=function(){done++;add(i+1)};
  sc.onerror=function(){OdinNative.status('Fehler bei '+urls[i]);window.__odinGodBot=0};
  (document.head||document.documentElement).appendChild(sc);
 }
 OdinNative.status('injiziere...');
 add(0);
 return 'started';
}catch(e){window.__odinGodBot=0;try{OdinNative.status('Bootstrap-Fehler: '+e.message)}catch(_){}return 'error'}})();
""".replace('__VERSION__', version)

a = s.index(' private void loadEnabledScripts(WebView v){')
b = s.index('\n @Override public void onWindowFocusChanged', a)

new = ''' private void loadEnabledScripts(WebView v){
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  if(u.equals(v.getTag(0x0D1A0001)))return; v.setTag(0x0D1A0001,u); v.setTag(0x0D1A0002,null);
  setStatus("Seite bereit");
  // Dichter Takt am Anfang: die Bereitschaftspruefung sorgt dafuer, dass zu
  // fruehe Versuche folgenlos bleiben.
  for(long d:new long[]{250L,600L,1200L,2500L,5000L,9000L})
   v.postDelayed(()->{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);},d);
 }
 private void executeGodBotWhenReady(WebView v){
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$"))return;
  // Bei aktiver Zugangssperre bewusst nichts injizieren, damit die Captcha-
  // Seite unveraendert bleibt. Marker aus dem echten Seitenquelltext.
  v.evaluateJavascript("(function(){try{return !!document.getElementById('botprotection_quest')}catch(e){return false}})()",bp->{
   if("true".equals(bp)){
    setStatus("Zugangssperre aktiv - pausiert");
    v.postDelayed(()->{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);},15000L);
    return;
   }
   v.evaluateJavascript("(function(){try{return !!(document.body&&(window.game_data||window.TribalWars||document.querySelector('#content_value')))}catch(e){return false}})()",r->{if("true".equals(r))injectGodBot(v);});
  });
 }
 private void injectGodBot(WebView v){
  if(v.getTag(0x0D1A0002)!=null)return; v.setTag(0x0D1A0002,Boolean.TRUE);
  final String seite=v.getUrl()==null?"":v.getUrl();
  new Thread(()->{
   try{
    java.util.List<byte[]> teile=new java.util.ArrayList<>();
    // GodBot kommt aus der APK - kein Netz, kein Gist, keine Ablaufzeit.
    String gb=OdinSkripte.godbot(this);
    boolean gbAn=gb.length()>1000;
    if(gbAn){
     teile.add(OdinSkripte.godbotBytes(this));
     if(!godbotGemeldet){ godbotGemeldet=true; versionPruefen(OdinSkripte.GODBOT_ID,"GodBot",gb); }
    }else setStatus("GodBot fehlt in dieser App-Fassung");
    // Zusatzskripte (Tampermonkey) aus der Teamliste.
    org.json.JSONArray liste=serverSkripte();
    if(liste==null)liste=OdinSkripte.liste(this);
    int extra=0, uebergangen=0;
    for(int qi=0;qi<liste.length();qi++){
     org.json.JSONObject o=liste.optJSONObject(qi);
     if(o==null||!o.optBoolean("an",true))continue;
     String sid=o.optString("id",""), snam=o.optString("name","");
     if(OdinSkripte.istGodBotEintrag(sid,o.optString("url","")))continue;
     String q="code".equals(o.optString("quelle","url"))?o.optString("code",""):OdinSkripte.holeGecacht(o.optString("url",""));
     if(q==null||q.trim().isEmpty()){ setStatus("Skript nicht ladbar: "+snam); continue; }
     // @match/@include/@exclude wie bei Tampermonkey
     if(!OdinSkripte.passt(q,seite)){ uebergangen++; continue; }
     boolean ok=true;
     for(String req:OdinSkripte.meta(q,"require")){
      String rq=OdinSkripte.holeGecacht(req);
      if(rq==null||rq.isEmpty()){ setStatus(snam+": @require nicht ladbar"); ok=false; break; }
      teile.add(rq.getBytes("UTF-8"));
     }
     if(!ok)continue;
     teile.add(OdinSkripte.einpacken(q,snam).getBytes("UTF-8"));
     extra++; versionPruefen(sid,snam,q);
    }
    if(teile.isEmpty()){ setStatus("kein Skript aktiv"); v.setTag(0x0D1A0002,null); return; }
    godbotTeile=teile;
    if(extra>0||uebergangen>0)setStatus("Zusatzskripte: "+extra+" aktiv, "+uebergangen+" nicht fuer diese Seite");
    final String js=''' + json.dumps(js) + '''.replace("__TEILE__",String.valueOf(teile.size()))
      .replace("__GODBOT_AN__",gbAn?"1":"0");
    runOnUiThread(()->v.evaluateJavascript(js,r->android.util.Log.i("ODIN_GODBOT","bootstrap="+r)));
   }catch(Exception e){
    setStatus("Skripte laden fehlgeschlagen: "+e.getMessage());
    v.setTag(0x0D1A0002,null);
   }
  }).start();
 }
 // Liefert die Teile unter der Origin der Spielseite aus: umgeht CSP
 // (connect-src) und das Groessenlimit von evaluateJavascript.
 private WebResourceResponse odinIntercept(WebResourceRequest r){
  try{
   String path=r.getUrl().getPath(); if(path==null||!path.startsWith("/__odin_t_"))return null;
   int i=Integer.parseInt(path.substring(10,path.length()-3));
   java.util.List<byte[]> t=godbotTeile; if(i<0||i>=t.size())return null;
   java.util.Map<String,String> h=new java.util.HashMap<>();
   h.put("Access-Control-Allow-Origin","*"); h.put("Cache-Control","no-store");
   WebResourceResponse res=new WebResourceResponse("application/javascript","utf-8",
     new java.io.ByteArrayInputStream(t.get(i)));
   res.setStatusCodeAndReasonPhrase(200,"OK"); res.setResponseHeaders(h);
   return res;
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","intercept",e);return null;}
 }
'''

a = s.index(' private void loadEnabledScripts(WebView v){')
b = s.index('\n @Override public void onWindowFocusChanged', a)
s = s[:a] + new + s[b:]
p.write_text(s)
print('GodBot loader: interception mode, bootstrap %d chars' % len(js))
PY
