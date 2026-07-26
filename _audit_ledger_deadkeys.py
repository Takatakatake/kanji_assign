# -*- coding: utf-8 -*-
# [M] 台帳の死にキー監査 (2026-07-27 第15レンズで新設)
#
# 【なぜ必要か】
# homonym台帳の sep 行は「見出し語リスト」で適用範囲を決める word-scoped 方式。
# ところが**正本(DICT)が分解をより細かくすると見出し綴りが変わり、語リストのキーだけが古いまま残る**。
# するとその規則は静かに不発火になり、第2義の漢字が第1義の字に退行する。実際に3回起きた:
#   ・pir/o/gajlol/o → pir/o/gajl/ol/o  (2026-07-26 続35で発覚。pir が 火ᴾ→梨(ナシ)に退行)
#   ・di/tionat/o    → di/tion/at/o     (2026-07-27 本レンズで発覚。di が 二ᴰᴵ→神(god)に退行)
#   ・tetra/tionat/o → tetra/tion/at/o  (同上。tetra が 四ᵀᴬ→野鸡(エゾライチョウ)に退行)
# いずれも「壊れたことを誰も検出できない」型の劣化なので、機械で検出できるようにする。
#
# 本監査は sep 語リストの各キーを両版の見出し集合と突き合わせ、どちらにも存在しないキーを
# ★死にキーとして報告する。BASELINE は「意図的に残している旧綴り」の許容数。
import io, os, re, sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))
BASELINE = int(sys.argv[1]) if len(sys.argv) > 1 else -1
SRCS = ['20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt',
        '20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt']
heads = set()
flat = {}
for p in SRCS:
    if not os.path.exists(p):
        continue
    for line in io.open(p, encoding='utf-8'):
        line = line.rstrip('\n')
        if ':' not in line or line.startswith('#'):
            continue
        h = line.split(':', 1)[0].strip()
        if h:
            heads.add(h)
            for w in h.split(' '):
                heads.add(w)
                flat.setdefault(w.replace('/', ''), set()).add(w)
dead = []
tot = 0
lists = {}
for ln in io.open('_homonym_disp.tsv', encoding='utf-8'):
    p = ln.rstrip('\n').split('\t')
    if len(p) < 5 or p[1] != 'sep':
        continue
    ws = set(x.strip() for x in p[2].split(',') if x.strip())
    lists.setdefault((p[0], p[3]), set()).update(ws)
    for w in ws:
        tot += 1
        if w not in heads:
            dead.append((p[0], p[3], w))
# ★最重要: 「スラッシュを除くと同じ綴りの生きた見出しがある」死にキー = 正本の再分解で綴りが変わった証拠。
#   規則が静かに不発火になっているので必ず語リストへ新綴りを足すこと。
#   ただし報告するのは「実害がある」ものだけに絞る:
#     (a) スラッシュを除くと同じ綴りの生きた見出しがある
#     (b) その見出しが**当該分節を実際に持っている**(si/n/kon/o のように分節自体が消えた場合は規則の出番が無い)
#     (c) その見出しが**まだ同じ(分節,漢字)の語リストに入っていない**(=規則が本当に不発火のまま)
renamed = []
for seg, kan, w in dead:
    for c in sorted(flat.get(w.replace('/', ''), ())):
        if seg not in c.split('/'):
            continue
        if c in lists.get((seg, kan), ()):
            continue
        renamed.append((seg, kan, w, [c]))
out = ["[M] 台帳sep語リスト: 総キー%d / 死にキー=%d / ★再分解で綴りが変わった疑い=%d" % (tot, len(dead), len(renamed))]
for seg, kan, w, cand in renamed:
    out.append("      ★%-8s →%-3s  台帳=%-22s 正本=%s" % (seg, kan, w, ','.join(cand)))
if BASELINE >= 0 and len(renamed) > BASELINE:
    out.append("    !! 正本の再分解で語リストのキーが古くなった → 新綴りを _build_homonym.ps1 の語リストに追加すること"
               "(旧綴りは他版のために残してよい)")
txt = '\n'.join(out)
try:
    sys.stdout.write(txt + '\n')
except Exception:
    sys.stdout.write(txt.encode('ascii', 'replace').decode('ascii') + '\n')
sys.exit(1 if (BASELINE >= 0 and len(renamed) > BASELINE) else 0)
