from sim import *
# Ausbau nach Vorgabe Fetteruruk 11.10.: Eisen 15 -> Eisen 20 / Lehm 16 / Holz 16 -> Katapulte -> Adelshof.
q1=open('q1.txt').read()
lv=endlv(q1); lv['place']=1
steps=[]
def popused(lk):
    return sum(sum(pop(b,l) for l in range(1,lv.get(b,0)+1)) for b in B if b in lv)+lk*4
def inc(): return [prod(lv['wood']),prod(lv['stone']),prod(lv['iron'])]
LK=[0]
def bau(b):
    lv[b]=lv.get(b,0)+1; steps.append(b)
def stuetzen(naechste):
    # Speicher: mind. 10 Std. Produktion + teuerster naechster Auftrag passt (nichts laeuft ueber)
    while True:
        cap=storecap(lv['storage']); c=cost(naechste,lv.get(naechste,0)+1)
        if cap < max(inc())*10 or cap < max(c)*1.05: bau('storage'); continue
        fc=farmcap(lv['farm']); LK[0]=min(LK[0]+6, 200)   # LKav-Nachschub grob mitgefuehrt
        need=pop(naechste,lv.get(naechste,0)+1)
        if fc-popused(LK[0])-need < 0.15*fc: bau('farm'); continue
        break
def bis(b,ziel):
    while lv.get(b,0)<ziel:
        stuetzen(b); bau(b)
# Phase A: Eisen 15
bis('iron',15)
# Phase B: Eisen 20, Lehm 16, Holz 16 - jeweils die guenstigste naechste Stufe (gleichmaessig)
ziel={'iron':20,'stone':16,'wood':16}
while any(lv[k]<v for k,v in ziel.items()):
    kand=[k for k,v in ziel.items() if lv[k]<v]
    k=min(kand,key=lambda b: sum(cost(b,lv[b]+1))/((prod(lv[b]+1)-prod(lv[b]))*(2.0 if b=='iron' else 1)))
    stuetzen(k); bau(k)
# Phase C: Katapulte (Standardwerte: Werkstatt braucht HG 10 + Schmiede 10; Katapult Werkstatt 2 + Schmiede 12)
bis('smith',12); bis('garage',5)
# Phase D: Adelshof (HG 20, Schmiede 20, Markt 10; Speicher muss 25k Lehm fassen)
bis('main',20); bis('market',10); bis('smith',20)
while storecap(lv['storage'])<25000*1.05: bau('storage')
stuetzen('snob'); bau('snob')
# AG (Adelsgeschlecht) braucht Platz: Speicher bis 21 (Vorgabe 11.10.)
bis('storage',21)
q3=q1+';'+compress(steps)
print('Voraussetzungen:',check(q3)); el=endlv(q3); print('Endstufen',el); print(len(parse(q3)),'Auftraege, Laenge',len(q3))
print(compress(steps))
open('q3.txt','w').write(q3)
