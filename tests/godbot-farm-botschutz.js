// GodBot-Farm Botschutz-Szenarien (v600; H-J seit v604; K seit v605; L seit v606; M seit v607, v608; N seit v609; Pakete seit v610; O seit v611; P seit v612; Q seit v613; R seit v615): node tests/godbot-farm-botschutz.js (braucht jsdom)
const fs=require('fs');const {JSDOM}=require('jsdom');
const SQ=require('path').join(__dirname,'..','seitenquellen')+'/';
const farm=fs.readFileSync(SQ+'33_de260_am_farm_desktop.html','utf8');
const captcha=fs.readFileSync(SQ+'03_de252_Botschutz-Captcha_desktop.html','utf8');
const combi=fs.readFileSync(SQ+'35_de260_overview_combined_desktop.html','utf8');
const farm6=fs.readFileSync(SQ+'38_de260_am_farm_seite1von6_mobil.html','utf8');
const gb=(()=>{const s=fs.readFileSync(require('path').join(__dirname,'..','godbot','GodBot.user.js'),'utf8');const i=s.lastIndexOf('})();');return s.slice(0,i)+'window.__t={openFarmPlanWindow, godFarmLauf, godFarmCfgSetzen, godFarmStand, isBotProtectionActive, currentProcessOwner, sendNextFarmAttack, measureNetworkLatencyMs, odinSteuerstand, autoKatEntscheiden, autoKatLernen, autoKatFarmSperrt, autoKatTakt, autoKatStand, autoKatFaellig, godFarmLauf, farmGebieteEmpfangen, teamZielStandMischen, autoKatTeamBelegt, godFarmTeamAnkuenfte, buildOpenAttackGroups, findAllDueAttackBatches, serverNowMs, autoKatFarmSperrtX:(i,a)=>autoKatFarmSperrt(i,a), acquireProcessLock, releaseProcessLock, setWF:(el)=>{workFrameEl=el;}};\n'+s.slice(i);})();
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
 { const ls=x.w.localStorage, la=parseInt(ls.getItem('tw_last_farm_send_at')||'0',10), n=parseInt(ls.getItem('tw_farm_attacks_sent')||'0',10);
  t('S1 GodBot-Farm setzt tw_last_farm_send_at und tw_farm_attacks_sent (HUB "Farmen vor ..", App-Aktivitaet)',la>0&&Date.now()-la<60000&&n===s.gesendet,JSON.stringify([la,n,s&&s.gesendet])); }
 { x.T.openFarmPlanWindow(); const r=x.w.document.getElementById('tw-farm-plan'); const tx=r?r.textContent.replace(/\s+/g,' '):'';
  t('S2 Farmen-Fenster zeigt im GodBot-Modus GodBot-Farm statt FarmGod-Plan',/GodBot-Farm · letzter Lauf/.test(tx)&&/Unterwegs/.test(tx)&&!/min alt/.test(tx)&&!/FarmGod-Plan/.test(tx),tx.slice(0,300)); }
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
 let e=E(zl,{ziele:{},lern:{}},cfgK,{spy:8,catapult:10,ram:2,axe:30});
 const kurz=(e)=>e.aktionen.map(a=>a.ziel.id+':'+a.art+':'+(a.pakete?a.pakete.map(p=>JSON.stringify(p.truppen)).join('|'):JSON.stringify(a.truppen))+':'+(a.geb||'-')).join(' ');
 t('M1 (v625) erst Beschuss, dann Erkundung; HG 3->1 = 2 Pakete zu 2 Kats; Kaserne 2->0 = 2 Pakete; Wall nur Rammen - jedes Paket mit 5 Axt + 1 Spaeher',
   kurz(e)==='2:beschuss:{"catapult":2,"spy":1,"axe":5}|{"catapult":2,"spy":1,"axe":5}:main 3:beschuss:{"catapult":2,"spy":1,"axe":5}|{"catapult":2,"spy":1,"axe":5}:barracks 4:beschuss:{"ram":2,"spy":1,"axe":5}:- 1:spaeher:{"spy":1}:-'&&e.gruende.fertig===1&&e.gruende.verluste===1&&!e.gruende.grenze,kurz(e)+' '+JSON.stringify(e.gruende));
 e=E(zl,{ziele:{},lern:{}},Object.assign({},cfgK,{maxOffen:2}),{spy:8,catapult:10,ram:2,axe:30});
 t('M2 Grenze nur, wenn gesetzt (2): Beschuesse belegen die Plaetze zuerst',kurz(e)==='2:beschuss:{"catapult":2,"spy":1,"axe":5}|{"catapult":2,"spy":1,"axe":5}:main 3:beschuss:{"catapult":2,"spy":1,"axe":5}|{"catapult":2,"spy":1,"axe":5}:barracks'&&e.gruende.grenze===2,kurz(e)+' '+JSON.stringify(e.gruende));
 e=E(zl,{ziele:{},lern:{}},cfgK,{spy:2,catapult:3,ram:0,axe:10});
 t('M3 knappe Truppen: 3 Kats reichen fuer 1 Paket (2 Kats), Erkundung danach',kurz(e)==='2:beschuss:{"catapult":2,"spy":1,"axe":5}:main 1:spaeher:{"spy":1}:-'&&e.gruende.keineKatapulte===1&&/Truppen fehlen/.test(e.aktionen[0].grund),kurz(e)+' '+JSON.stringify(e.gruende));
 { const zs=[{id:'a',x:0,y:0,dist:1,gebaeude:null,verluste:0},{id:'b',x:0,y:0,dist:1.5,gebaeude:null,verluste:0},{id:'c',x:0,y:0,dist:2,gebaeude:null,verluste:0},{id:'d',x:0,y:0,dist:9,gebaeude:{main:3,wall:0},verluste:0}];
   const r=E(zs,{ziele:{},lern:{}},cfgK,{spy:3,catapult:10,axe:50});
   t('S3 (v625) Spaeher zuerst fuer den Kata-Trupp: fernes HG-Ziel bekommt 2 Pakete, Erkundung haelt Spaeher fuer weitere Pakete zurueck',
     kurz(r)==='d:beschuss:{"catapult":2,"spy":1,"axe":5}|{"catapult":2,"spy":1,"axe":5}:main'&&r.gruende.spaeherFuerBeschuss===3,kurz(r)+' '+JSON.stringify(r.gruende));
   const r2=E(zs.slice(0,3),{ziele:{},lern:{}},cfgK,{spy:3,catapult:10,axe:50});
   t('S4 (v625) ohne bekanntes Beschussziel darf die Erkundung alle Spaeher nutzen',r2.aktionen.length===3&&r2.aktionen.every(a=>a.art==='spaeher'),kurz(r2)); }
 const hg11=[{id:'9',x:1,y:1,dist:1,gebaeude:{main:11,wall:0},verluste:0}];
 e=E(hg11,{ziele:{},lern:{}},cfgK,{spy:20,catapult:100,axe:100});
 const e2=E(hg11,{ziele:{},lern:{},faktor:{main:1.25}},cfgK,{spy:20,catapult:100,axe:100});
 const ks=(x)=>x.aktionen[0].pakete.map(p=>p.truppen.catapult).join(',');
 t('M9 Tabelle je Paket: HG 11->1 = 10 Pakete 4,4,4,3,3,3,3,3,2,2 (31); Faktor 1,25 aufgerundet',ks(e)==='4,4,4,3,3,3,3,3,2,2'&&e.aktionen[0].truppen.catapult===31&&ks(e2)==='5,5,5,4,4,4,4,4,3,3',ks(e)+' / '+ks(e2));
 const e4=E(hg11,{ziele:{},lern:{}},cfgK,{spy:3,catapult:100,axe:100});
 t('M10 Pakete begrenzt durch Spaeher (3) -> 3 Pakete, HG 11->8',e4.aktionen[0].pakete.length===3&&/11→8 in 3 Paket/.test(e4.aktionen[0].grund),e4.aktionen[0].grund);
 e=E([zl[1]],{ziele:{},lern:{}},cfgK,{spy:1,catapult:4,light:10});
 const e3=E([zl[1]],{ziele:{},lern:{}},cfgK,{spy:1,catapult:4});
 t('M8 Begleitung: ohne Aexte 5 LKav (1 Spaeher -> 1 Paket), ganz ohne Begleitung kein Beschuss',JSON.stringify(e.aktionen[0].truppen)==='{"catapult":2,"spy":1,"light":5}'&&e3.aktionen.length===0&&e3.gruende.keineBegleitung===1,JSON.stringify([e.aktionen[0]&&e.aktionen[0].truppen,e3.gruende]));
 let sl={ziele:{},lern:{}};x.T.autoKatLernen(sl,{beschuss:{geb:'main',kats:4,rammen:2,geplant:2,pakete:2,vorher:{main:3,wall:2}}},{main:1,wall:2});
 const l1=JSON.stringify([sl.faktor,sl.lern]);sl={ziele:{},lern:{}};x.T.autoKatLernen(sl,{beschuss:{geb:'main',kats:4,geplant:2,pakete:2,vorher:{main:3}}},{main:2});
 const sl2={ziele:{},lern:{}};x.T.autoKatLernen(sl2,{beschuss:{geb:'main',kats:4,geplant:2,vorher:{main:3}}},{main:2});
 t('M4 Lernen: Tabelle stimmt -> Faktor 1; nur 1 von 2 Stufen -> Faktor 1,25; Rammen ohne Wirkung -> 4 je Stufe',l1==='[{"main":1},{"wall":4}]'&&sl.faktor.main===1.25&&!sl2.faktor,l1+' '+JSON.stringify(sl.faktor));
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
 // M11 (v610): Takt legt je Paket einen Planer-Eintrag an, nacheinander, mit Zielgebaeude.
 x=welt({mapJson:[{x:560,y:540,data:{x:560,y:540,villages:{'1':{'12':[7001,0,0,60,0]}},players:{}}}]});
 x.w.localStorage.setItem('tw_world_info',JSON.stringify({world:'de260.die-staemme.de',at:Date.now(),speed:1.6,unitSpeed:0.625,fakeLimit:0,unitSpeeds:{spy:9,axe:18,light:10,ram:30,catapult:30}}));
 x.w.localStorage.setItem('tw_ziel_stand',JSON.stringify({'7001':{x:561,y:552,spieler:'0',zeit:Date.now()-3600000,verluste:0,gebaeude:{main:3,wall:0}}}));
 x.w.localStorage.setItem('tw_autokat_cfg',JSON.stringify({an:true,v:2}));
 x.w.localStorage.setItem('godbot_autokat_einheiten',JSON.stringify({vid:'6863',at:Date.now(),u:{spy:10,axe:20,catapult:6,ram:0,light:0}}));
 const tk=await new Promise(res=>{const r=x.T.autoKatTakt(res);if(!r)res(null);});
 const at11=(JSON.parse(x.w.localStorage.getItem('tw_attack_plans')||'{}')['tw-autokat']||{}).attacks||[];
 const of11=x.T.autoKatStand().ziele['7001'];
 t('M11 Takt: HG 3 -> 2 Eintraege (je 2 Kats + 5 Axt + 1 Spaeher, Ziel Hauptgebaeude), 2-5 s nacheinander, beide im Ziel-Stand',
   at11.length===2&&at11.every(a=>JSON.stringify(a.troops)==='{"catapult":2,"spy":1,"axe":5}'&&a.targetBuilding==='Hauptgebäude'&&a.unitLabel==='catapult')&&
   at11[1].startsAtMs-at11[0].startsAtMs>=2000&&at11[1].startsAtMs-at11[0].startsAtMs<=5000&&of11&&of11.offen&&of11.offen.eintraege.length===2&&of11.offen.ankunft===at11[1].arrivesAtMs&&of11.beschuss.pakete===2,
   JSON.stringify([tk,at11.map(a=>[a.troops,a.targetBuilding,a.startsAtMs]),of11]));
 // O (v611): Truppen aus der Versand-Antwort, Berichte sofort lesen, Sperre bis gelesen.
 x=welt({postAntwort:{nach:1,fehler:false,r:{success:'x',current_units:{spy:'2',axe:'7',catapult:'1',light:'3'}}}});s=await lauf(x.T);
 const ge2=JSON.parse(x.w.localStorage.getItem('godbot_autokat_einheiten')||'null');
 t('O1 Truppenzahlen nach dem Farmangriff aus der Antwort (nicht vom Laufbeginn)',ge2&&ge2.u.spy===2&&ge2.u.catapult===1&&ge2.u.axe===7,JSON.stringify(ge2));
 x=welt({});const jetztO=Date.now();
 x.w.localStorage.setItem('tw_autokat_cfg',JSON.stringify({an:true,v:2}));
 x.w.localStorage.setItem('tw_autokat_stand',JSON.stringify({next:jetztO+3600000,ziele:{'7001':{x:561,y:552,warte:{art:'spaeher',ankunft:jetztO-60000,berichtVorher:'100'}},
   '7002':{x:557,y:553,warte:{art:'spaeher',ankunft:jetztO-4*3600000,berichtVorher:'200'}}},lern:{}}));
 x.w.localStorage.setItem('tw_ziel_stand',JSON.stringify({'7001':{x:561,y:552,spieler:'0',bericht:'101',zeit:jetztO-30000},'7002':{x:557,y:553,spieler:'0',bericht:'201',zeit:jetztO}}));
 t('O2 Bericht bereit -> Takt faellig, obwohl der Planungstakt erst in 1 Std. dran ist (keine Truppenzahlen noetig)',x.T.autoKatFaellig()===true);
 t('O3 Sperre: solange der Bericht nicht gelesen ist, kein Farmangriff nach unserer Ankunft; davor frei',
   x.T.autoKatFarmSperrtX('7001',jetztO+2*3600000)===true&&x.T.autoKatFarmSperrtX('7001',jetztO-5*60000)===false&&x.T.autoKatFarmSperrtX('7002',jetztO+60000)===false);
 const tkO=await new Promise(res=>{const r=x.T.autoKatTakt(res);if(!r)res(null);});
 const stO=x.T.autoKatStand();const abO=x.st.abrufe.filter(u=>/screen=report/.test(u));
 t('O4 Lese-Takt: 7001 gelesen (ohne Gebaeude -> neuer Spaeher statt zweitem Versuch), 7002 nach 3 Std. aufgegeben, keine Karte, Planungstakt unveraendert',
   tkO&&/gelesen/.test(tkO)&&abO.length===1&&/view=101/.test(abO[0])&&!stO.ziele['7001'].warte&&!stO.ziele['7002'].warte&&stO.next===jetztO+3600000&&!x.st.abrufe.some(u=>/map\.php/.test(u)),
   JSON.stringify([tkO,abO,stO.ziele,stO.next-jetztO]));
 // P (v612): Auto-Kat-Eintraege ohne Sollsekunde - kein Vorladen, keine Staffelung.
 x=welt({});const n0=x.T.serverNowMs();
 const mk=(id,dt,ohne)=>({id,type:'attack',villageId:'6863',targetId:id,toCoord:'560|552',targetPlayer:'Barbarendorf',startsAtMs:n0+dt,arrivesAtMs:n0+dt+600000,troops:{spy:1},sent:false,failed:false,ohneSekunde:ohne});
 x.w.localStorage.setItem('tw_attack_plans',JSON.stringify({'p-normal':{name:'n',attacks:[mk('a1',300000,false),mk('a2',305000,false),mk('a3',310000,false)]},
   'tw-autokat':{name:'Auto-Kat',attacks:[mk('k1',20000,true),mk('k2',23000,true),mk('k3',-1000,true)]}}));
 const gr=x.T.buildOpenAttackGroups();const pre={};gr.forEach(g=>{pre[g.group[0].attack.id]=g.preloadMs;});
 const due=x.T.findAllDueAttackBatches().map(g=>g[0].attack.id);
 t('P1 ohne Sollsekunde: Vorladen 0, nicht gestaffelt; normale Angriffe unveraendert 60 s; faellig erst zur Startzeit',
   pre.k1===0&&pre.k2===0&&pre.k3===0&&pre.a1===60000&&pre.a2===60000&&pre.a3===60000&&due.includes('k3')&&!due.includes('k1')&&!due.includes('k2'),JSON.stringify([pre,due]));
 // Q (v613): App geht mitten im Lauf in den Hintergrund.
 x=welt({});let qStand=null;const qLauf=new Promise(res=>{x.T.godFarmLauf(st=>{qStand=st;res(st);});});
 for(let k=0;k<200&&x.st.posts.length<2;k++)await new Promise(r=>setTimeout(r,50));
 const vorQ=x.st.posts.length;
 Object.defineProperty(x.w.document,'visibilityState',{configurable:true,get:()=>'hidden'});
 x.w.document.dispatchEvent(new x.w.Event('visibilitychange'));
 const endeSofort=!!qStand;const sperreFrei=x.T.currentProcessOwner()===null;
 await new Promise(r=>setTimeout(r,4000));
 const logQ=JSON.parse(x.w.localStorage.getItem('tw_godfarm_ankunft')||'{}');
 t('Q1 Hintergrund mitten im Lauf: Lauf endet sofort, Sperre frei, kein weiterer Angriff, Ankuenfte gesichert',
   vorQ>=2&&endeSofort&&sperreFrei&&x.st.posts.length<=vorQ+1&&Object.keys(logQ).length>=vorQ&&/App im Hintergrund/.test(qStand.text)&&qStand.fehler===false,
   JSON.stringify([vorQ,x.st.posts.length,endeSofort,sperreFrei,qStand&&qStand.text,Object.keys(logQ).length]));
 // R (v615): Team-Daten derselben Welt.
 x=welt({});const welt260=x.w.game_data.world;const jetztR=Date.now();
 const idsR=[...farm.matchAll(/id="village_(\d+)"/g)].map(m=>m[1]);
 const ankR={};idsR.forEach(i=>ankR[i]=jetztR+3600000);
 const zsTeam={'7001':{x:561,y:552,spieler:'0',zeit:jetztR,gebaeude:{main:3,barracks:1,wall:0},gebaeudeZeit:jetztR}};
 x.w.localStorage.setItem('tw_ziel_stand',JSON.stringify({'7001':{x:561,y:552,spieler:'0',zeit:jetztR-7200000,gebaeude:{main:1,wall:0},gebaeudeZeit:jetztR-7200000}}));
 x.T.farmGebieteEmpfangen([
  {account_id:'a2',skey:'tw_godfarm_ankunft',value:JSON.stringify(ankR),game_accounts:{name:'Ares20',world:welt260}},
  {account_id:'a2',skey:'tw_ziel_stand',value:JSON.stringify(zsTeam),game_accounts:{name:'Ares20',world:welt260}},
  {account_id:'a2',skey:'tw_autokat_stand',value:JSON.stringify({ziele:{'7001':{offen:{ankunft:jetztR+600000}}}}),game_accounts:{name:'Ares20',world:welt260}},
  {account_id:'a3',skey:'tw_godfarm_ankunft',value:JSON.stringify({'1':jetztR}),game_accounts:{name:'Fremd',world:'de999'}}]);
 const gm=x.T.teamZielStandMischen(JSON.parse(x.w.localStorage.getItem('tw_ziel_stand')));
 t('R1 Berichte geteilt: neuerer Spaeherbericht eines Teamkontos gewinnt (mit Name), andere Welt zaehlt nicht',
   gm['7001'].gebaeude.main===3&&gm['7001'].gebaeude.barracks===1&&gm['7001'].gebaeudeVon==='Ares20'&&x.T.godFarmTeamAnkuenfte('1').length===0);
 t('R2 Auto-Kat: Ziel, das ein Teamkonto gerade bearbeitet, gilt als belegt',x.T.autoKatTeamBelegt('7001')===true&&x.T.autoKatTeamBelegt('7002')===false);
 x.T.godFarmCfgSetzen({abstandMin:300});s=await lauf(x.T);
 t('R3 Farmen geteilt: kommt ein Teamkonto in derselben Abstandsspanne an, schickt dieses Konto nichts dorthin',
   s&&s.gesendet===0&&/Abstand/.test(s.text)&&x.st.posts.length===0,JSON.stringify(s&&s.text));
 const alleFehler=[];
 console.log(R.join('\n'));process.exit(0);
})();
