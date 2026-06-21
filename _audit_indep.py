# -*- coding: utf-8 -*-
import os, glob, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

base = r'd:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
csvdir = os.path.join(base, '30_重要語彙CSV_日中対照_2890語')
cands = [f for f in glob.glob(os.path.join(csvdir, '2890 Gravaj*.csv')) if 'Korea' not in f]
csvpath = cands[0]
outpath = os.path.join(base, '漢字注入_学習者版_20260620.txt')
print('CSV:', os.path.basename(csvpath))
print('OUT:', os.path.basename(outpath))

# h-system map
hmap = {
 'ĉ':'c^','Ĉ':'C^',
 'ĝ':'g^','Ĝ':'G^',
 'ĥ':'h^','Ĥ':'H^',
 'ĵ':'j^','Ĵ':'J^',
 'ŝ':'s^','Ŝ':'S^',
 'ŭ':'u^','Ŭ':'U^',
}
def toh(s):
    return ''.join(hmap.get(ch,ch) for ch in s)

LB='⟦'  # left bracket ⟦
RB='⟧'  # right bracket ⟧

# Read CSV first column (skip header)
csv_words=[]
with open(csvpath, encoding='utf-8-sig') as f:
    lines=f.read().splitlines()
import re
for i,line in enumerate(lines):
    if i==0: continue  # header
    if not line.strip(): continue
    w=line.split(',')[0].strip()
    if not w: continue
    # CSV artifacts: strip surrounding quotes, parentheticals like " (sin)"
    w=w.strip('"').strip()
    w=re.sub(r'\s*\([^)]*\)\s*','',w).strip()
    if not w: continue
    csv_words.append(toh(w))
print('CSV words (excl header):', len(csv_words))

# Read output, build plainkey -> has_kanji map
m={}        # plainkey -> bool has_kanji
mk={}       # plainkey -> kanji content (first with kanji)
mhead={}    # plainkey -> sample headword
with open(outpath, encoding='utf-8') as f:
    olines=f.read().splitlines()
for line in olines:
    if not line: continue
    ci=line.find(':')
    if ci<0: continue
    headfull=line[:ci]
    has_k=False; kanji=''; head=headfull
    bi=headfull.find(LB)
    if bi>=0:
        ei=headfull.find(RB)
        head=headfull[:bi]
        if ei>bi: kanji=headfull[bi+1:ei]
        has_k=True
    key=head.replace('/','').replace('-','')
    if key not in m:
        m[key]=has_k
        if has_k: mk[key]=kanji
        mhead[key]=headfull
    else:
        if has_k and not m[key]:
            m[key]=True
        if has_k and key not in mk:
            mk[key]=kanji
print('Output headword keys:', len(m))

covered=[]; nokanji=[]; notfound=[]
for w in csv_words:
    key=w.replace('/','').replace('-','')
    if key in m:
        if m[key]:
            covered.append((w, mk.get(key,'')))
        else:
            nokanji.append((w, mhead.get(key,'')))
    else:
        notfound.append(w)

total=len(csv_words)
print()
print('=== COVERAGE (CSV2890 vs gakushu output) ===')
print('Total CSV words:', total)
print('Covered (has kanji): %d  (%.2f%%)' % (len(covered), 100.0*len(covered)/total))
print('In output, NO kanji (untargeted):', len(nokanji))
print('Not found in output at all:', len(notfound))

with open(os.path.join(base,'_indep_nokanji.txt'),'w',encoding='utf-8') as f:
    for w,h in nokanji: f.write('%s\t%s\n'%(w,h))
with open(os.path.join(base,'_indep_notfound.txt'),'w',encoding='utf-8') as f:
    for w in notfound: f.write(w+'\n')
with open(os.path.join(base,'_indep_covered.txt'),'w',encoding='utf-8') as f:
    for w,k in covered: f.write('%s\t%s\n'%(w,k))
print('(wrote _indep_nokanji.txt, _indep_notfound.txt, _indep_covered.txt)')
