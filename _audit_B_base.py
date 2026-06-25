# -*- coding: utf-8 -*-
# 軸B task(3): piv-band 語が高優先(basic/pejvo)語の「基本形」(id無し)を奪っていないか
import csv

DIR = r"d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
SC = DIR + r"\_identifier_sidecar.tsv"

rank = {'basic':0,'suf':0,'pref':0,'prep':0,'correl':0,'num':0,'func':0,
        'pejvo':1,'sci':1,'elem':1,'cal':1,'rel':1,
        'piv':2,'proper':2}

with open(SC, encoding='utf-8-sig') as f:
    rdr = csv.DictReader(f, delimiter='\t', quotechar='"')
    rows = []
    for r in rdr:
        rows.append({(k.strip('"') if k else k): (v.strip('"') if isinstance(v,str) else v) for k,v in r.items()})

grp = {}
for r in rows:
    grp.setdefault(r['groupkey'], []).append(r)

piv_base_steals = []  # piv/proper holds base, while a higher-pri member has id
any_base_lower = []   # base is lower-priority than some member (general inversion)
for g, mem in grp.items():
    if len(mem) < 2: continue
    base = next((m for m in mem if m['id_super']==''), None)
    if not base: continue
    br = rank.get(base['band'], 1)
    # is base in a piv/proper band while members exist in higher pri?
    for m in mem:
        if m['id_super']=='': continue
        mr = rank.get(m['band'],1)
        if mr < br:
            any_base_lower.append((g, base['root'], base['band'], m['root'], m['band'], m['id_super']))
            if br == 2:  # base is piv/proper but a higher member has identifier
                piv_base_steals.append((g, base['root'], base['band'], m['root'], m['band'], m['id_super']))

print("=== piv/proper-band が基本形を保持し、高優先メンバーが識別子付き(真の違反候補) ===")
if not piv_base_steals:
    print("  0件")
for x in piv_base_steals:
    print("  ", x)

print()
print(f"=== 一般の基本形逆転(base.band > member.band) 全{len(any_base_lower)}件 ===")
for x in any_base_lower:
    print("  群%s: base=%s(%s) < member=%s(%s,id=%s)" % x)

# Also: among multi-member groups, count how often base band is the MIN band (healthy)
healthy = 0; total_multi = 0
for g, mem in grp.items():
    if len(mem) < 2: continue
    base = next((m for m in mem if m['id_super']==''), None)
    if not base: continue
    total_multi += 1
    br = rank.get(base['band'],1)
    minr = min(rank.get(m['band'],1) for m in mem)
    if br <= minr: healthy += 1
print()
print(f"=== 多メンバー群 {total_multi}: 基本形が最低band(=最高優先) {healthy} ({healthy/total_multi:.1%}) ===")
