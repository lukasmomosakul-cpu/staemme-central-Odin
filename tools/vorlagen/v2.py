from sim import *
q1=open('q1.txt').read()
lv=endlv(q1); lv['place']=1
LK=(125,100,250); LKPOP=4; LKSHARE=0.40   # Anteil des Einkommens fuer LKav (Annahme)
ZIEL={'garage':5,'wood':23,'stone':23,'iron':23,'main':20,'farm':22,'storage':21,'stable':10,'market':10,'smith':20,'wall':10,'snob':1}
t=0.0; res=[1400,1180,980]; lkav=0; steps=[]
def popused():
    p=sum(sum(pop(b,l) for l in range(1,lv.get(b,0)+1)) for b in B if b!='snob' or lv.get('snob'))
    return p+lkav*LKPOP+ 0
def income(): return [prod(lv['wood']),prod(lv['stone']),prod(lv['iron'])]
def price():
    inc=income(); dem=[0.5*LK[k]/sum(LK)+0.5*[0.36,0.34,0.30][k] for k in range(3)]
    p=[dem[k]/(inc[k]/sum(inc)) for k in range(3)]; s=sum(p)/3; return [x/s for x in p]
def req_ok(b):
    return all(lv.get(r,0)>=m for r,m in REQ.get(b,{}).items())
def kandidat():
    inc=income(); cap=storecap(lv['storage']); pr=price()
    nxt=lambda b: lv.get(b,0)+1
    # 1) Speicher: nie ueberlaufen - mind. 10 Std Produktion des staerksten Rohstoffs
    if lv['storage']<ZIEL['storage'] and cap < max(inc)*10: return 'storage'
    # 2) Bauernhof: Platz fuer LKav-Nachschub (+15 % Reserve)
    fc=farmcap(lv['farm'])
    if lv['farm']<ZIEL['farm'] and fc-popused() < 0.15*fc: return 'farm'
    # 3) Stall bis 5 frueh (schnellere Ausbildung)
    if lv['stable']<5: return 'stable'
    # Katapult-Phase, sobald stabil: Stall 10, HG 15, alle Minen >= 17.
    # Katapult braucht (Standardwerte) Werkstatt 2 + Schmiede 12; Werkstatt
    # selbst HG 10 + Schmiede 10. Danach Werkstatt bis 5 (schnellere Ausbildung).
    if lv['stable']>=10 and lv['main']>=15 and min(lv['wood'],lv['stone'],lv['iron'])>=17:
        if lv['smith']<12: return 'smith'
        if lv.get('garage',0)<5: return 'garage'
    am=(lv['wood']+lv['stone']+lv['iron'])/3
    if lv['main']<ZIEL['main'] and lv['main']<am-3: return 'main'
    if lv['stable']<ZIEL['stable'] and am>=16 and lv['stable']<am-8: return 'stable'
    best=None
    for b in ('wood','stone','iron'):
        if lv[b]>=ZIEL[b]: continue
        k={'wood':0,'stone':1,'iron':2}[b]; c=cost(b,nxt(b))
        if max(c)>cap: return 'storage'
        gain=(prod(nxt(b))-prod(lv[b]))*pr[k]; wc=sum(c[j]*pr[j] for j in range(3))
        sc=gain/wc
        if best is None or sc>best[0]: best=(sc,b)
    if best: return best[1]
    for b in ('main','market','smith','garage','storage','farm','stable','wall','snob'):
        if lv.get(b,0)<ZIEL[b] and req_ok(b):
            c=cost(b,nxt(b))
            if max(c)>storecap(lv['storage']) and lv['storage']<30: return 'storage'
            return b
    return None
log=[]
while True:
    b=kandidat()
    if not b: break
    l=lv.get(b,0)+1; c=cost(b,l)
    # warten bis bezahlbar (LKav-Anteil laeuft nebenher)
    inc=income(); bau=[x*(1-LKSHARE) for x in inc]
    need=max(max(0,c[k]-res[k])/bau[k] for k in range(3))
    t+=need
    for k in range(3): res[k]=min(storecap(lv['storage']),res[k]+bau[k]*need)-c[k]
    lkav+= sum(inc)*LKSHARE*need/sum(LK)
    fc=farmcap(lv['farm']); lkav=min(lkav,max(0,(fc-popused()+lkav*LKPOP)/LKPOP))
    lv[b]=l; steps.append(b)
    if b in('stable','main','farm','storage','snob','garage','smith') or l%5==0: log.append(f'{t:6.1f}h {b}{l} LKav~{int(lkav)}')
q2=q1+';'+compress(steps)
print('Voraussetzungen:',check(q2)); el=endlv(q2); print('Endstufen',el); print(len(parse(q2)),'Auftraege, Laenge',len(q2))
print('\n'.join(log[:60]))
open('q2.txt','w').write(q2)
