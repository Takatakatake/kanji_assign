# -*- coding: utf-8 -*-
# 軸B 独立検証: band別 被覆率(basic>pejvo>piv が逓減しているか)
# 注入出力(line-aligned)+ CSV2890 + 辞書PIVマーカー から band を独立判定
import re, csv, sys

DIR = r"d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
INJ = DIR + r"\漢字注入_学習者版_20260620.txt"
DICT = DIR + r"\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
CSV = DIR + r"\30_重要語彙CSV_日中対照_2890語\2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"

def tohsys(s):
    rep = {'ĉ':'c^','Ĉ':'C^','ĝ':'g^','Ĝ':'G^','ĥ':'h^','Ĥ':'H^','ĵ':'j^','Ĵ':'J^','ŝ':'s^','Ŝ':'S^','ŭ':'u^','Ŭ':'U^'}
    for k,v in rep.items(): s = s.replace(k,v)
    return s

ENDING = re.compile(r'^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|j|n)$')

# --- CSV2890 basic root set (語尾1字除去) ---
basic = set()
with open(CSV, encoding='utf-8') as f:
    rdr = csv.reader(f)
    next(rdr, None)
    for row in rdr:
        if not row: continue
        w = row[0].strip().lower()
        if not w or w.startswith('-') or w.endswith('-'): continue
        r = re.sub(r'(o|a|e|i|u)$','', w)
        if r: basic.add(tohsys(r))

# --- inject lines (line-aligned with dict) ---
with open(INJ, encoding='utf-8') as f:
    inj = f.read().split('\n')
with open(DICT, encoding='utf-8') as f:
    dct = f.read().split('\n')

# build per-headword band by scanning dict for PIV membership
seen_nonpiv = set()
seen_any = set()
for line in dct:
    ci = line.find(':')
    if ci < 1: continue
    head = line[:ci]; gloss = line[ci+1:]
    is_piv = '【PIV】' in gloss
    for wd in head.split(' '):
        for s in wd.split('/'):
            if ENDING.match(s) or not s: continue
            seen_any.add(s)
            if not is_piv: seen_nonpiv.add(s)

def band_of(seg):
    h = seg
    if h in basic: return 'basic'
    if h in seen_any and h not in seen_nonpiv: return 'piv'
    return 'pejvo'

# Now: for each headword line in inject, take the FIRST content segment of first word as the representative root.
# A line is 'assigned' if it contains ⟦.
# We classify per representative root's band. Skip proper-name lines (capitalized head / {O}).
stats = {}  # band -> [assigned, total]
seen_roots = {}  # root -> band (dedupe to root level)
root_assigned = {}
for i, line in enumerate(inj):
    ci = line.find(':')
    if ci < 1: continue
    hasK = '⟦' in line
    head = line[:line.index('⟦')] if hasK else line[:ci]
    first = head.split(' ')[0]
    # representative content segment: first non-ending segment
    segs = [s for s in first.split('/') if s and not ENDING.match(s)]
    if not segs: continue
    rep = segs[0]
    repH = tohsys(rep) if any(ord(c)>127 for c in rep) else rep
    # skip proper names (cap start) for band coverage fairness — they are universally untargeted
    if rep[:1].isupper(): continue
    b = band_of(repH)
    # dedupe at root level: a root counts assigned if ANY of its lines assigned
    key = repH
    if key not in seen_roots:
        seen_roots[key] = b
        root_assigned[key] = hasK
    else:
        if hasK: root_assigned[key] = True

for key, b in seen_roots.items():
    stats.setdefault(b, [0,0])
    stats[b][1]+=1
    if root_assigned[key]: stats[b][0]+=1

print("=== 軸B独立: root-level band別 被覆(固有名除外) ===")
order = ['basic','pejvo','piv']
prev = None
for b in order:
    if b in stats:
        a,t = stats[b]
        rate = a/t if t else 0
        print(f"  {b:6s}  {a}/{t} = {rate:.3%}")
# monotonic check
rates = []
for b in order:
    if b in stats:
        a,t = stats[b]; rates.append((b, a/t if t else 0))
mono = all(rates[i][1] >= rates[i+1][1] for i in range(len(rates)-1))
print(f"  逓減(basic>=pejvo>=piv)? {mono}")
