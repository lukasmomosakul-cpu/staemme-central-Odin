// GodBot-Farm Botschutz-Szenarien (v600): node tests/godbot-farm-botschutz.js (braucht jsdom)
const fs=require('fs');const {JSDOM}=require('jsdom');
const SQ=require('path').join(__dirname,'..','seitenquellen')+'/';
const farm=fs.readFileSync(SQ+'33_de260_am_farm_desktop.html','utf8');
const captcha=fs.readFileSync(SQ+'03_de252_Botschutz-Captcha_desktop.html','utf8');
const combi=fs.readFileSync(SQ+'35_de260_overview_combined_desktop.html','utf8');
const gb=(()=>{const s=fs.readFileSync(require('path').join(__dirname,'..','godbot','GodBot.user.js'),'utf8');const i=s.lastIndexOf('})();');return s.slice(0,i)+'window.__t={godFarmLauf, godFarmCfgSetzen, godFarmStand, isBotProtectionActive, currentProcessOwner};\n'+s.slice(i);})();
function welt({farmHtml=farm,farmUrl=null,combiHtml=combi,villages='1',postAntwort=null,botImDok=false}){
 const dom=new JSDOM('<html><body>'+(botImDok?'<div id="bot_check">Bot-Schutz</div>':'')+'</body></html>',{url:'https://de260.die-staemme.de/game.php?village=6863&screen=overview',runScripts:'outside-only',pretendToBeVisual:true});
 const w=dom.window;const st={abrufe:[],posts:[],fehler:[]};
 w.addEventListener('error',e=>st.fehler.push(String(e.error&&e.error.stack||e.message).slice(0,200)));
 w.game_data={world:'de260',locale:'de_DE',csrf:'e',device:'desktop',screen:'overview',player:{id:'1',name:'FetterOrk',ally:'0',villages},village:{id:6863,x:559,y:552,name:'K',display_name:'K',wood:1,stone:1,iron:1,pop:1,pop_max:2,storage_max:100},features:{Premium:{active:true},AccountManager:{active:false},FarmAssistent:{active:true}}};
 w.localStorage.setItem('tw_a1','1');w.localStorage.setItem('tw_farm_loop_active','1');
 w.localStorage.setItem('tw_godfarm_cfg',JSON.stringify({modus:'godbot',abstandMin:15,tempo:'zuegig'}));
 w.localStorage.setItem('godfarm_befehle_at',String(Date.now()));
 w.TribalWars={post:(u,_,d,ok,err)=>{st.posts.push(d);setTimeout(()=>{ if(postAntwort&&st.posts.length===postAntwort.nach) (postAntwort.fehler?err:ok)(postAntwort.r); else ok({success:'x',target_village:Number(d.target),current_units:{}}); },10);}};
 w.fetch=(u)=>{u=String(u);st.abrufe.push(u);const istFarm=/screen=am_farm$/.test(u),istCombi=/mode=combined/.test(u);
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
 const alleFehler=[];
 console.log(R.join('\n'));process.exit(0);
})();
