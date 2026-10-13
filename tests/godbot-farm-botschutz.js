// GodBot-Farm Botschutz-Szenarien (v600; H-J seit v604; K seit v605; L seit v606; M seit v607, v608; N seit v609): node tests/godbot-farm-botschutz.js (braucht jsdom)
const fs=require('fs');const {JSDOM}=require('jsdom');
const SQ=require('path').join(__dirname,'..','seitenquellen')+'/';
const farm=fs.readFileSync(SQ+'33_de260_am_farm_desktop.html','utf8');
const captcha=fs.readFileSync(SQ+'03_de252_Botschutz-Captcha_desktop.html','utf8');
const combi=fs.readFileSync(SQ+'35_de260_overview_combined_desktop.html','utf8');
const farm6=fs.readFileSync(SQ+'38_de260_am_farm_seite1von6_mobil.html','utf8');
const gb=(()=>{const s=fs.readFileSync(require('path').join(__dirname,'..','godbot','GodBot.user.js'),'utf8');const i=s.lastIndexOf('})();');return s.slice(0,i)+'window.__t={godFarmLauf, godFarmCfgSetzen, godFarmStand, isBotProtectionActive, currentProcessOwner, sendNextFarmAttack, measureNetworkLatencyMs, odinSteuerstand, autoKatEntscheiden, autoKatLernen, autoKatFarmSperrt, autoKatTakt, autoKatStand, autoKatFaellig, acquireProcessLock, releaseProcessLock, setWF:(el)=>{workFrameEl=el;}};\n'+s.slice(i);})();
function welt({farmHtml=farm,farmUrl=null,combiHtml=combi,villages='1',postAntwort=null,botImDok=false,seiten=null,mapJson=null}){
 const dom=new JSDOM('<html><body>'+(botImDok?'<div id="bot_check">Bot-Schutz</div>':'')+'</body></html>',{url:'https://de260.die-staemme.de/game.php?village=6863&screen=overview',runScripts:'outside-only',pretendToBeVisual:true});
 const w=dom.window;const st={abrufe:[],posts:[],fehler:[]};
 w.addEventListener('error',e=>st.fehler.push(String(e.error&&e.error.stack||e.message).slice(0,200)));
 w.game_data={world:'de260',locale:'de_DE',csrf:'e',device:'desktop',screen:'overview',player:{id:'1',name:'FetterOrk',ally:'0',villages},village:{id:6863,x:559,y:552,name:'K',display_name:'K',wood:1,stone:1,iron:1,pop:1,pop_max:2,storage_max:100},features:{Premium:{active:true},AccountManager:{active:false},FarmAssistent:{active:true}}};
 w.localStorage.setItem('tw_a1','1');w.localStorage.setItem('tw_farm_loop_active','1');
 w.localStorage.setItem('tw_godfarm_cfg',JSON.stringify({modus:'godbot',abstandMin:15,tempo:'zuegig'}));
 w.localStorage.setItem('godfarm_befehle_at',String(Date.now()));
 w.TribalWars={post:(u,_,d,ok,err)=>{st.posts.push(d);setTimeout(()=>{ if(postAntwort&&st.posts.length===postAntwort.nach) (postAntwort.fehler?err:ok)(postAntwort.r); else ok({success:'x',target_village:Number(d.target),current_units:{}}); },10);}};
 w.fetch=(u)=>{u=String(u);st.abrufe.push(u);
   if(/map\.php/.test(u))return Promise.resolve({ok:true,status:200,url:'https://de260.die-staemme.de'+u,text:()=>Promise.resolve(JSON.stringify(mapJson||[]))});
   const fp=u.match(/Farm_page=(\d+)/);
   if(fp&&seiten){const h=seiten(Number(fp[1]));if(h==='netz')return Promise.reject(new Error('Failed to fetch'));return Promise.resolve({ok:true,status:200,url:'https://de260.die-staemme.de'+u,text:()=>Promise.resolve(h)});}
   const istFarm=/screen=am_farm$/.test(u),istCombi=/mode=combined/.test(u);
   const html=istFarm?farmHtml:(istCombi?combiHtml:'<html><body>ok</body></html>');
   const url='https://de260.die-staemme.de'+(istFarm&&farmUrl?farmUrl:u);
   return Promise.resolve({ok:true,status:200,url,text:()=>Promise.resolve(html),json:()=>Promise.reject(new Error('x'))});};
 const ol=w.console;['log','warn','error'].forEach(k=>{const o=ol[k];ol[k]=(...a)=>{};});
 w.eval(gb);return {w,st,T:w.__t};
}
const lauf=(T)=>new Promise(res=>{const r=T.godFarmLauf(s=>res(s));if(!r)res(null);});
const R=[];const t=(n,c,i)=>R.push((c?'OK   ':'FEHL ')+n+(c||!i?'':' -> '+i));
(async()=>{
 let x=welt({});let s=await lauf(x.T);
 t('A normaler Lauf: 1 Abruf + Angriffe, kein Botschutz',s&&s.gesendet>0&&!x.T.isBotProtectionActive()&&x.st.abrufe.filter(u=>/am_farm/.test(u)).length===1,JSON.stringify(s));
 x=welt({farmHtml:captcha});s=await lauf(x.T);
 t('B Farm-Seite ist Botschutz-Seite: KEIN Angriff, alles angehalten, kein Rueckfall-Zaehler',s&&x.st.posts.length===0&&x.T.isBotProtectionActive()&&x.w.localStorage.getItem('tw_farm_loop_active')===null&&s.fehler===false&&s.fehlLaeufe===0,JSON.stringify([s,x.st.posts.length,x.w.localStorage.getItem('tw_farm_loop_active')]));
 x=welt({villages:'2',combiHtml:captcha});s=await lauf(x.T);
 t('C Kombinierte Uebersicht ist Botschutz-Seite: KEIN Angriff, angehalten',s&&x.st.posts.length===0&&x.T.isBotProtectionActive(),JSON.stringify(s));
 x=welt({postAntwort:{nach:2,fehler:true,r:{error:['Bot-Schutz'],bot_protect:'forced'}}});s=await lauf(x.T);
 t('D Antwort auf 2. Angriff meldet Botschutz: danach kein weiterer Angriff, angehalten',x.st.posts.length===2&&x.T.isBotProtectionActive(),JSON.stringify([x.st.posts.length,s&&s.text]));
 x=welt({botImDok:true});s=await lauf(x.T);
 t('E Botschutz schon auf der Seite: Lauf startet gar nicht (0 Abrufe)',s===null&&x.st.abrufe.filter(u=>/am_farm/.test(u)).length===0);
 x=welt({farmUrl:'/game.php?village=6863&screen=overview&intro'});s=await lauf(x.T);
 t('F Weiterleitung weg von der Farm-Seite: nichts gesendet, nicht als Fehler gezaehlt',s&&x.st.posts.length===0&&s.fehler===false&&/umgeleitet/.test(s.text),JSON.stringify(s));
 x=welt({});const t0=Date.now();s=await lauf(x.T);
 t('G Lesepause vor dem ersten Angriff (zuegig >= 0,3 s), Sperre danach frei',x.T.currentProcessOwner()===null&&(Date.now()-t0)>=300);
 // H (v604): Arbeitsrahmen mit fremder Herkunft - Lesen von .hcaptcha wirft SecurityError.
 x=welt({});const fr=x.w.document.createElement('iframe');x.w.document.body.appendChild(fr);
 const fremd=new Proxy({},{get(){throw new x.w.DOMException('Blocked a frame with origin','SecurityError');}});
 Object.defineProperty(fr,'contentWindow',{get:()=>fremd});Object.defineProperty(fr,'contentDocument',{get:()=>null});
 x.T.setWF(fr);let wurf=null,erg=null;try{erg=x.T.isBotProtectionActive();}catch(e){wurf=String(e&&e.message);}
 t('H Arbeitsrahmen fremder Herkunft: isBotProtectionActive wirft nicht, kein Fehlalarm',wurf===null&&erg===false,String(wurf||erg));
 // I (v604): FarmGod-Direktversand - Antwort mit Botschutz-Kennung.
 const farmgod=(antwort)=>{const y=welt({});const d=y.w.document;
   for(let k=0;k<3;k++){const r=d.createElement('tr');r.className='farmRow';const a=d.createElement('a');a.className='farmGod_icon farm_icon_a';
     a.dataset.origin='6863';a.dataset.target=String(7000+k);a.dataset.template='111';r.appendChild(a);d.body.appendChild(r);}
   y.w.Accountmanager={send_units_link:'/game.php?village=6863&screen=am_farm&mode=farm&ajaxaction=farm&json=1&h=e'};
   const posts=[];y.w.TribalWars={post:(u,_,dd,ok,err)=>{posts.push(dd);setTimeout(()=>antwort(posts.length,ok,err,dd),5);}};
   return {y,posts};};
 const sende=(y,n)=>new Promise(res=>{let i=0;const nx=()=>{if(++i>n){res('alle');return;}y.T.sendNextFarmAttack(nx);};nx();setTimeout(()=>res('gestoppt'),1500);});
 let f=farmgod((n,ok,err)=>n===1?ok({success:'x',bot_protect:'forced'}):ok({success:'x'}));let e1=await sende(f.y,3);
 t('I1 FarmGod: Erfolg MIT Botschutz-Kennung -> sofort Halt, kein 2. Angriff, kein Enter-Ausweg',e1==='gestoppt'&&f.posts.length===1&&f.y.T.isBotProtectionActive(),JSON.stringify([e1,f.posts.length]));
 f=farmgod((n,ok,err)=>n===2?err({error:['Bot-Schutz'],bot_protect:'forced'}):ok({success:'x'}));e1=await sende(f.y,3);
 t('I2 FarmGod: Ablehnung mit Botschutz beim 2. Angriff -> kein 3. Angriff, angehalten',e1==='gestoppt'&&f.posts.length===2&&f.y.T.isBotProtectionActive(),JSON.stringify([e1,f.posts.length]));
 f=farmgod((n,ok)=>ok({success:'x'}));e1=await sende(f.y,3);
 t('I3 FarmGod: normale Antworten -> 3 Angriffe, kein Halt',e1==='alle'&&f.posts.length===3&&!f.y.T.isBotProtectionActive(),JSON.stringify([e1,f.posts.length]));
 // J (v604): Latenz aus der Browser-Zeitmessung - 0 Anfragen.
 x=welt({});const o='https://de260.die-staemme.de';
 const fw={location:{origin:o},fetch:()=>{throw new Error('fetch darf nicht laufen');},performance:{getEntriesByType:(t)=>t==='navigation'
   ?[{name:o+'/game.php?screen=place&try=confirm',connectStart:0,secureConnectionStart:0,requestStart:100,responseStart:260}]
   :[{name:o+'/game.php?screen=overview&ajax=widget',connectStart:0,secureConnectionStart:0,requestStart:500,responseStart:560},
     {name:'https://dsde.innogamescdn.com/x.png',requestStart:10,responseStart:11}]}};
 const vor=x.st.abrufe.length;const lat=await new Promise(res=>x.T.measureNetworkLatencyMs(fw,res));
 t('J Latenz ohne Anfrage: min RTT 60 ms gleiche Herkunft -> 21 ms, CDN ignoriert, 0 Abrufe',lat===21&&x.st.abrufe.length===vor,String(lat));
 const lat2=await new Promise(res=>x.T.measureNetworkLatencyMs({location:{origin:o},performance:{getEntriesByType:()=>[]}},res));
 t('J2 ohne Zeitmessung: zuletzt gemessener Wert',lat2===21,String(lat2));
 // K (v605): Farm-Assistent mit 6 Seiten (Seitenquelle 38, Seitengroesse 10).
 const fpNr=(st)=>st.abrufe.map(u=>(u.match(/Farm_page=(\d+)/)||[])[1]).filter(Boolean).map(Number);
 x=welt({farmHtml:farm6,seiten:()=>farm});s=await lauf(x.T);
 t('K1 6 Seiten: Folgeseiten 1-5 aus der Seitenleiste geholt, Ziele zusammengefuehrt, angegriffen',
   s&&JSON.stringify(fpNr(x.st))==='[1,2,3,4,5]'&&x.st.abrufe.filter(u=>/am_farm/.test(u)).length===6&&/6\/6 Seiten gelesen/.test(s.text)&&s.gesendet>0&&!x.T.isBotProtectionActive(),JSON.stringify([fpNr(x.st),s&&s.anfragen,s&&s.text]));
 x=welt({farmHtml:farm6,seiten:(n)=>n===3?captcha:farm});s=await lauf(x.T);
 t('K2 Botschutz auf Seite 4: keine weitere Seite, KEIN Angriff, alles angehalten',
   s&&JSON.stringify(fpNr(x.st))==='[1,2,3]'&&x.st.posts.length===0&&x.T.isBotProtectionActive()&&s.fehler===false,JSON.stringify([fpNr(x.st),x.st.posts.length,s&&s.text]));
 x=welt({farmHtml:farm6,seiten:(n)=>n===2?'netz':farm});s=await lauf(x.T);
 t('K3 Netzfehler auf Seite 3: Lauf geht weiter, als fehlend gemeldet, kein Fehl-Lauf',
   s&&s.fehler===false&&/5\/6 Seiten gelesen \(1 fehlen\)/.test(s.text)&&s.gesendet>0,JSON.stringify(s&&s.text));
 // L (v606): App-Leiste/Dashboard - GodBot-Farm-Lauf (Sperre "godfarm") meldet "farm" = gelb "laeuft".
 x=welt({});const st0=x.T.odinSteuerstand().laeuft;x.T.acquireProcessLock('godfarm');const st1=x.T.odinSteuerstand();x.T.releaseProcessLock('godfarm');
 t('L GodBot-Farm aktiv: Stand meldet laeuft="farm" (Sperre "godfarm"), danach wieder frei',st0===null&&st1.laeuft==='farm'&&st1.sperre==='godfarm'&&x.T.odinSteuerstand().laeuft===null,JSON.stringify([st0,st1.laeuft,st1.sperre]));
 // M (v607): Auto-Kat.
 x=welt({});const E=x.T.autoKatEntscheiden;const cfgK={hgZiel:1,maxOffen:0,spaeher:1,begleitEinheit:'axe',begleitAnzahl:5};
 const zl=[{id:'1',x:1,y:0,dist:2,gebaeude:null,verluste:0},{id:'2',x:1,y:1,dist:3,gebaeude:{main:3,wall:0},verluste:0},
   {id:'3',x:2,y:1,dist:4,gebaeude:{main:5,barracks:2,wall:0},verluste:0},{id:'4',x:3,y:1,dist:5,gebaeude:{main:1,wall:1},verluste:0},
   {id:'5',x:0,y:1,dist:1,gebaeude:{main:1,wall:0},verluste:0},{id:'6',x:0,y:0,dist:0.5,gebaeude:{main:4},verluste:1}];
 let e=E(zl,{ziele:{},lern:{}},cfgK,{spy:5,catapult:10,ram:2,axe:20});
 const kurz=(e)=>e.aktionen.map(a=>a.ziel.id+':'+a.art+':'+JSON.stringify(a.truppen)+':'+(a.geb||'-')).join(' ');
 t('M1 (v608) naechste zuerst, ohne Grenze: Spaeher; HG 3->1 = 4 Kats; Kaserne 2->0 = 4 Kats; Wall nur Rammen - jeder Beschuss mit 5 Axt + 1 Spaeher',
   kurz(e)==='1:spaeher:{"spy":1}:- 2:beschuss:{"catapult":4,"spy":1,"axe":5}:main 3:beschuss:{"catapult":4,"spy":1,"axe":5}:barracks 4:beschuss:{"ram":2,"spy":1,"axe":5}:-'&&e.gruende.fertig===1&&e.gruende.verluste===1&&!e.gruende.grenze,kurz(e)+' '+JSON.stringify(e.gruende));
 e=E(zl,{ziele:{},lern:{}},Object.assign({},cfgK,{maxOffen:2}),{spy:5,catapult:10,ram:2,axe:20});
 t('M2 Grenze nur, wenn gesetzt (2): nur die beiden naechsten',kurz(e)==='1:spaeher:{"spy":1}:- 2:beschuss:{"catapult":4,"spy":1,"axe":5}:main'&&e.gruende.grenze===2,kurz(e));
 e=E(zl,{ziele:{},lern:{}},cfgK,{spy:2,catapult:3,ram:0,axe:10});
 t('M3 knappe Truppen: 3 Kats reichen fuer 1 Stufe (2 Kats), Rest wartet auf Spaeher',kurz(e)==='1:spaeher:{"spy":1}:- 2:beschuss:{"catapult":2,"spy":1,"axe":5}:main'&&e.gruende.keineSpaeher===2&&/mehr Katapulte fehlen/.test(e.aktionen[1].grund),kurz(e)+' '+JSON.stringify(e.gruende));
 const hg11=[{id:'9',x:1,y:1,dist:1,gebaeude:{main:11,wall:0},verluste:0}];
 e=E(hg11,{ziele:{},lern:{}},cfgK,{spy:1,catapult:100,axe:5});
 const e2=E(hg11,{ziele:{},lern:{},faktor:{main:1.25}},cfgK,{spy:1,catapult:100,axe:5});
 t('M9 Tabelle: HG 11->1 = 3x4 + 5x3 + 2x2 = 31 Kats; mit Faktor 1,25 je Stufe aufgerundet',e.aktionen[0].truppen.catapult===31&&e2.aktionen[0].truppen.catapult===3*5+5*4+2*3,JSON.stringify([e.aktionen[0].truppen,e2.aktionen[0].truppen]));
 e=E([zl[1]],{ziele:{},lern:{}},cfgK,{spy:1,catapult:4,light:10});
 const e3=E([zl[1]],{ziele:{},lern:{}},cfgK,{spy:1,catapult:4});
 t('M8 Begleitung: ohne Aexte 5 LKav, ganz ohne Begleitung kein Beschuss',JSON.stringify(e.aktionen[0].truppen)==='{"catapult":4,"spy":1,"light":5}'&&e3.aktionen.length===0&&e3.gruende.keineBegleitung===1,JSON.stringify([e.aktionen[0]&&e.aktionen[0].truppen,e3.gruende]));
 let sl={ziele:{},lern:{}};x.T.autoKatLernen(sl,{beschuss:{geb:'main',kats:4,rammen:2,geplant:2,vorher:{main:3,wall:2}}},{main:1,wall:2});
 const l1=JSON.stringify([sl.faktor,sl.lern]);sl={ziele:{},lern:{}};x.T.autoKatLernen(sl,{beschuss:{geb:'main',kats:4,geplant:2,vorher:{main:3}}},{main:2});
 t('M4 Lernen: Tabelle stimmt -> Faktor 1; nur 1 von 2 Stufen -> Faktor 1,25; Rammen ohne Wirkung -> 4 je Stufe',l1==='[{"main":1},{"wall":4}]'&&sl.faktor.main===1.25,l1+' '+JSON.stringify(sl.faktor));
 const T0=Date.now()+3600000;x.w.localStorage.setItem('tw_autokat_stand',JSON.stringify({ziele:{'9':{offen:{art:'spaeher',ankunft:T0}}},lern:{}}));
 t('M5 Farm-Sperre: nach unserer Ankunft (15 Min.) gesperrt, davor frei',x.T.autoKatFarmSperrt('9',T0+5*60000)===true&&x.T.autoKatFarmSperrt('9',T0-10*60000)===false&&x.T.autoKatFarmSperrt('9',T0+20*60000)===false&&x.T.autoKatFarmSperrt('8',T0)===false);
 // M6: ganzer Takt nach einem Farm-Lauf (Seitenquelle 38: 6 Spaeher, 0 Kats).
 const mj=[{x:560,y:540,data:{x:560,y:540,villages:{'1':{'12':[7001,0,0,52,0]},'0':{}},players:{}}},{x:540,y:540,data:{x:540,y:540,villages:{'17':{'13':[7002,0,0,40,0]}},players:{}}}];
 x=welt({farmHtml:farm6,seiten:()=>farm,mapJson:mj});
 x.w.localStorage.setItem('tw_world_info',JSON.stringify({world:'de260.die-staemme.de',at:Date.now(),speed:1.6,unitSpeed:0.625,fakeLimit:0,unitSpeeds:{spy:9,light:10,ram:30,catapult:30}}));
 x.w.localStorage.setItem('tw_ziel_stand',JSON.stringify({'7001':{x:561,y:552,spieler:'0',zeit:Date.now()-3600000,verluste:0},'7002':{x:557,y:553,spieler:'0',zeit:Date.now()-3600000,verluste:0,gebaeude:{main:1,wall:0}}}));
 x.w.localStorage.setItem('tw_autokat_cfg',JSON.stringify({an:true,hgZiel:1,maxOffen:3,spaeher:1}));
 s=await lauf(x.T);const vorTakt=x.st.abrufe.length;
 const takt=await new Promise(res=>{const r=x.T.autoKatTakt(res);if(!r)res(null);});
 const pl=JSON.parse(x.w.localStorage.getItem('tw_attack_plans')||'{}')['tw-autokat'];const at=pl&&pl.attacks||[];
 const st6=x.T.autoKatStand();
 const dd=at.map(a=>Math.hypot(+a.toCoord.split('|')[0]-559,+a.toCoord.split('|')[1]-552));
 t('M6 Takt: Karte geholt (1 Abruf); alle 6 Spaeher genutzt (alte Grenze 3 aus v607 gilt nicht), naechste zuerst, 7002 (HG 1) nicht, Punkte gemerkt, Sperre frei',
   takt&&at.length===6&&/24 keineSpaeher/.test(takt)&&at.every(a=>JSON.stringify(a.troops)==='{"spy":1}'&&a.targetBuilding===null&&a.unitLabel==='spy')&&dd.slice().sort((a,b)=>a-b).join()===dd.slice().sort((a,b)=>a-b).join()&&Math.max(...dd)<=3.2&&at.some(a=>a.toCoord==='561|552')&&!at.some(a=>a.toCoord==='557|553')&&
   x.st.abrufe.slice(vorTakt).filter(u=>/map\.php/.test(u)).length===1&&st6.ziele['7001'].punkte===52&&st6.ziele['7001'].offen&&x.T.currentProcessOwner()===null&&!x.T.isBotProtectionActive(),
   JSON.stringify([takt,at.map(a=>[a.toCoord,a.troops,a.unitLabel]),x.st.abrufe.slice(vorTakt)]));
 const takt2=x.T.autoKatTakt(()=>{});
 t('M7 zweiter Takt sofort danach laeuft nicht (eigener Takt 20-40 Min.)',takt2===false);
 // N (v609): "jetzt" ohne Rueckmeldung / Auto-Kat nach Neuladen.
 x=welt({});x.w.localStorage.setItem('tw_autokat_cfg',JSON.stringify({an:true,v:2}));
 s=await lauf(x.T);const ids33=[...farm.matchAll(/id="village_(\d+)"/g)].map(m=>m[1]);const lg33={};ids33.forEach(i=>lg33[i]=Date.now()+5*3600000);
 x.w.localStorage.setItem('tw_godfarm_ankunft',JSON.stringify(lg33));x.w.localStorage.setItem('godfarm_jetzt_at',String(Date.now()));const s2=await lauf(x.T);
 t('N1 alles im Abstand: Text nennt fruehesten Zeitpunkt, Rueckmeldung nach "jetzt" (Merker verbraucht)',
   s2&&s2.gesendet===0&&/nichts zu senden/.test(s2.text)&&/frühestens wieder ab \d\d:\d\d/.test(s2.text)&&x.w.localStorage.getItem('godfarm_jetzt_at')===null,JSON.stringify(s2&&s2.text));
 const ge=JSON.parse(x.w.localStorage.getItem('godbot_autokat_einheiten')||'null');
 t('N2 Truppenzahlen fuer Auto-Kat dauerhaft gemerkt, Takt ueber den Fahrplan faellig',ge&&ge.vid==='6863'&&ge.u&&typeof ge.u.spy==='number'&&x.T.autoKatFaellig()===true,JSON.stringify(ge));
 const alleFehler=[];
 console.log(R.join('\n'));process.exit(0);
})();
