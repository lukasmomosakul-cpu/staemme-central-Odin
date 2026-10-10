from sim import *
# Weg von KRORETTEF 100 (de260), Reihenfolge aus dem Bauprotokoll; von Hand gebaute Stufen
# (Schmiede, Wall, Hof 3-6, Kaserne 3-5, Stall, Markt 2-3, Speicher 5-6, Versteck 3-5) nach Voraussetzung eingeordnet.
steps=(['main','farm','storage']+['iron']*4+['wood','stone','wood','stone','wood','stone']+['main']*2+['barracks']*2
 +['iron']*5+['wood']*5+['stone']*4+['main','farm','storage','storage','market','main','main','main','main','storage','hide','hide','main']
 +['smith','wall','farm','farm','farm','main']+['smith']*4+['barracks']*3+['stable']
 +['storage','farm','stable','stable','market','market','storage','hide','hide','hide','wall','wall','wall','wall'])
q=compress(steps)
ziel={'main':10,'barracks':5,'stable':3,'smith':5,'market':3,'wood':8,'stone':7,'iron':9,'farm':6,'storage':6,'hide':5,'wall':5}
lv=endlv(q); print('Endstufen ok:',all(lv.get(k)==v for k,v in ziel.items()), {k:lv.get(k) for k in ziel}, 'extra', {k:v for k,v in lv.items() if k not in ziel})
print('Voraussetzungen:',check(q)); print(len(parse(q)),'Auftraege'); print(q)
open('q1.txt','w').write(q)
