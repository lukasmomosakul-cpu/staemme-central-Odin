import math, json
SPEED=1.624
B={ # base cost w,s,i ; factors ; pop base, pop factor ; build base seconds
'main':((90,80,70),(1.26,1.275,1.26),5,1.17,900),
'barracks':((200,170,90),(1.26,1.28,1.26),7,1.17,1800),
'stable':((270,240,260),(1.26,1.28,1.26),8,1.17,6000),
'smith':((220,180,240),(1.26,1.275,1.26),20,1.17,6000),
'market':((100,100,100),(1.26,1.275,1.26),20,1.17,2700),
'wood':((50,60,40),(1.25,1.275,1.245),5,1.155,900),
'stone':((65,50,40),(1.27,1.265,1.24),10,1.14,1080),
'iron':((75,65,70),(1.252,1.275,1.24),10,1.17,1350),
'farm':((45,40,30),(1.3,1.32,1.29),0,1,1200),
'storage':((60,50,40),(1.265,1.27,1.245),0,1,1020),
'hide':((50,60,50),(1.25,1.25,1.25),2,1.17,1800),
'wall':((50,100,20),(1.26,1.275,1.26),5,1.17,3600),
'place':((10,40,30),(1.26,1.275,1.26),0,1,10860),
'garage':((300,240,260),(1.26,1.28,1.26),8,1.17,6000),
'snob':((15000,25000,10000),(2,2,2),80,1.17,586994),
}
REQ={'barracks':{'main':3},'market':{'main':3,'storage':2},'smith':{'main':5,'barracks':1},'stable':{'main':10,'barracks':5,'smith':5},'wall':{'barracks':1},'snob':{'main':20,'smith':20,'market':10},'garage':{'main':10,'smith':10}}
def cost(b,l): base,f,*_=B[b]; return [round(base[k]*f[k]**(l-1)) for k in range(3)]
def pop(b,l):
    _,_,p,pf,_=B[b]
    if p==0: return 0
    return round(p*pf**(l-1))-(round(p*pf**(l-2)) if l>1 else 0)
def prod(l): return 30*SPEED*1.163118**(l-1) if l>0 else 5*SPEED
def farmcap(l): return round(240*1.172103**(l-1))
def storecap(l): return round(1000*1.2294**(l-1))
def parse(q): return [(a,int(b)) for a,b in (x.split(':') for x in q.split(';'))]
def endlv(q):
    lv={}
    for g,n in parse(q): lv[g]=lv.get(g,0)+n
    return lv
def check(q):
    lv={};bad=[]
    for i,(g,n) in enumerate(parse(q),1):
        for r,m in REQ.get(g,{}).items():
            if lv.get(r,0)<m: bad.append((i,g,r,m,lv.get(r,0)))
        lv[g]=lv.get(g,0)+n
    return bad
def compress(steps):
    out=[]
    for g in steps:
        if out and out[-1][0]==g: out[-1][1]+=1
        else: out.append([g,1])
    return ';'.join(f'{g}:{n}' for g,n in out)
