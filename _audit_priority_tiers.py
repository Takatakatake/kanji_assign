# -*- coding: utf-8 -*-
# 優先順位(層順)の包括監査 v2。base=min(band_rank) はC=br*1000+Pで構造保証されるので、
# 真の層順逆転は【band誤ラベル】時のみ発生(arketip型: prototipが真PEJVOなのにband=piv→
# 真PIVのarketipと同層化し短語根tiebreakでbareを奪われた)。
# ここでは arketip署名 を厳密に検出する:
#   多メンバー群で bare基本形が【真PIV】(正確見出しに【PIV】)なのに、
#   同群に【真PEJVO】(正確見出し<=44440かつ【PIV】無)のメンバーがいる = 逆転の疑い。
# 併せて band=piv だが真PEJVO の誤ラベル語(温床)を列挙。exact語根照合+【PIV】タグで判定。
import io, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
ACAD = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt"
SUPP_MAX = 44440   # <=44440 PEJVO(旧+追補) / >=44441 PIV
ENDINGS = {'o','a','e','i','oj','aj','on','ojn','an','ajn','en','as','is','os','us','u','j','n'}
FUNC_BANDS = {'suf','pref','prep','correl','num','func'}   # 機能形態素=br0で正当に基本形。真層判定から除外

def concat_root(head):
    if ' ' in head: return None
    parts = head.split('/')
    if len(parts) >= 2 and parts[-1] in ENDINGS:
        parts = parts[:-1]
    return ''.join(parts) if parts else None

# 学術版原本: 語根連結形 -> (最小行, その行に【PIV】タグ)。exact連結一致。
root_line, root_piv = {}, {}
with io.open(ACAD, encoding='utf-8') as f:
    for n, line in enumerate(f, 1):
        line = line.rstrip('\n')
        if ':' not in line: continue
        head, gloss = line.split(':', 1)
        head = head.strip()
        if not head or head.startswith('#'): continue
        r = concat_root(head)
        if not r: continue
        if r not in root_line:
            root_line[r] = n
            root_piv[r]  = ('【PIV】' in gloss)

def genuine(root):
    # 戻り: 'PIV' / 'PEJVO' / None(不明=見出し無し)
    ln = root_line.get(root)
    if ln is None: return None
    if ln >= 44441 or root_piv.get(root): return 'PIV'
    return 'PEJVO'

# sidecar
rows = []
with io.open("_identifier_sidecar.tsv", encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) < 8: continue
        rows.append({'root':p[0],'id':p[2],'band':p[5],'gk':p[7]})

from collections import defaultdict
groups = defaultdict(list)
for r in rows: groups[r['gk']].append(r)

KNOWN = {'蛾','气学家','气学','气计','高计','高测','脉炎','菌学','苔植','胚源','拍型',
         '胃炎','乐主义','乐家','肠炎','色计','神经学','振具','渗计','速计'}

# arketip署名(厳密): bareが band=piv かつ 真PIV。同群に band=piv だが真PEJVO のメンバー(=誤ラベル)。
# 真PEJVO語がband=pejvoならbr1で必ず勝つ→負けるのはそのPEJVO語がband=piv誤ラベルの時だけ。
flags = []
for gk, members in groups.items():
    if len(members) < 2: continue
    base = next((m for m in members if m['id']==''), None)
    if base is None: continue
    if base['band'] != 'piv': continue               # bareがpiv-bandの時だけ(pejvo-band基本形は正当)
    if genuine(base['root']) != 'PIV': continue       # bareが真PIVの時だけ
    mislabeled = [m['root'] for m in members
                  if m['root']!=base['root'] and m['band']=='piv'
                  and genuine(m['root'])=='PEJVO']     # band=piv誤ラベルの真PEJVOメンバー
    if mislabeled:
        flags.append((gk, base['root'], base['band'], ','.join(mislabeled[:6]), gk in KNOWN))

BR = {'basic':0,'suf':0,'pref':0,'prep':0,'correl':0,'num':0,'func':0,
      'pejvo':1,'sci':1,'elem':1,'cal':1,'rel':1,'piv':2,'proper':2}
# _base_override.tsv の (漢字,語根) = 意図的にbaseを固定した語(層順より意味/難易度優先=ユーザー承認)
ovr_roots = set()
with io.open("_base_override.tsv", encoding='utf-8') as f:
    for line in f:
        line=line.rstrip('\n')
        if not line or line.startswith('#'): continue
        parts=line.split('\t')
        if len(parts)>=2: ovr_roots.add(parts[1].strip())
# [D] 純band逆転(ノイズ皆無): base の band_rank が同群メンバーより悪い = 層順違反(base_override強制かバグ)
band_rev = []
for gk, members in groups.items():
    if len(members) < 2: continue
    base = next((m for m in members if m['id']==''), None)
    if base is None: continue
    bbr = BR.get(base['band'],1)
    worse_than = [(m['root'],m['band']) for m in members if BR.get(m['band'],1) < bbr]
    if worse_than:
        band_rev.append((gk, base['root'], base['band'], worse_than[:5], base['root'] in ovr_roots))

# band=piv だが真PEJVO = 誤ラベル(温床)
piv_mislabel = []
for r in rows:
    if r['band']=='piv' and genuine(r['root'])=='PEJVO':
        piv_mislabel.append((r['root'], root_line[r['root']], r['gk'], r['id']=='' ))

out = []
out.append("# 優先順位(層順)包括監査 v2 台帳  (base=min band_rank は構造保証・逆転はband誤ラベル時のみ)")
out.append("# arketip署名 = 多メンバー群でbare基本形が真PIVなのに同群に真PEJVOメンバー")
out.append("")
new = [x for x in flags if not x[4]]
out.append("## [A] arketip型 新規逆転疑い(既知20群除く) = %d件  (0が理想)" % len(new))
out.append("groupkey\tbare(真PIV)\tband\t同群の真PEJVOメンバー")
for gk,br,band,pej,known in sorted(new):
    out.append("%s\t%s\t%s\t%s" % (gk,br,band,pej))
out.append("")
out.append("## [D] 純band_rank逆転(base.band_rankが同群メンバーより悪い=層順違反) = %d件  (0が理想)" % len(band_rev))
out.append("#     C=band_rank*1000+P で base=min band_rank が構造保証。>0なら base_override強制かバグ")
unexpected = [x for x in band_rev if not x[4]]
out.append("#     うち _base_override.tsv 由来(意図的・ユーザー承認)=%d件 / 想定外=%d件" % (len(band_rev)-len(unexpected), len(unexpected)))
out.append("groupkey\tbase\tbase_band\tより良band_rankのメンバー\t判定")
for gk,br,band,worse,isovr in sorted(band_rev):
    out.append("%s\t%s\t%s\t%s\t%s" % (gk,br,band,';'.join("%s(%s)"%(w[0],w[1]) for w in worse),
               'base_override(意図的)' if isovr else '!!想定外=要調査'))
out.append("")
out.append("## [C] band=piv だが真PEJVO(<=44440・PIVタグ無)の誤ラベル語 = %d件" % len(piv_mislabel))
out.append("#     bare列=その語が漢字群のbare基本形か(Trueなら真PEJVO語が正しくbareを保持=無害)")
out.append("root\t行\tgroupkey\tbareか")
for r,ln,gk,isbare in sorted(piv_mislabel, key=lambda x:x[1]):
    out.append("%s\t%d\t%s\t%s" % (r,ln,gk,isbare))

io.open("_audit_priority_tiers_ledger.tsv","w",encoding="utf-8").write("\n".join(out)+"\n")
print("VALIDATE prototip=%s arketip=%s" % (genuine('prototip'), genuine('arketip')))
print("ARKETIP_NEW_FLAGS=%d  KNOWN=%d  BAND_RANK_REVERSALS=%d  PIV_MISLABEL_PEJVO(harmless_convention)=%d" % (
    len(new), len(flags)-len(new), len(band_rev), len(piv_mislabel)))
