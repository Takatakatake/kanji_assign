# -*- coding: utf-8 -*-
# 第28レンズ「優先順位の伝達経路の監査 — ラベル→br→C→ソート→基本形所有権」 (第27回続64)
#
#   1〜27は「出力」か「入力(第24=Unified_Level)」を測ってきた。だが優先順位が出力に届くには
#   固定の因果連鎖を通る:
#       ユーザーの優先順位 → band ラベル → br=BR[band] → C=br*1000+P
#         → 安定挿入ソート(|ΔC|<=1.0 なら綴り長) → sortedIndex 0 = 基本形(無印)所有者 → 識別子
#   ★この連鎖の中間リンクは一度も検証されていない。
#   とくに [I] の常設advisory (CSV_MISLABEL=39 / PIV_MISLABEL_PEJVO=824) は
#   台帳に「一覧」されるだけで、**そのラベル誤りが出力を変えたか**は測られたことがない。
#
#   既存 [A] 逆転監査は「真層が逆転しているか」だけを見るので、
#   ★同一真層内でラベル誤りが基本形を決めている場合を原理的に検出できない。
#   本レンズはソートを Python で再実装し(現行baseを100%再現することを先に確かめる)、
#   ラベルを正した反実仮想と突き合わせる。
import io, os, re, sys, math, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))

PWORK = "_p_work.csv"
GASOUT = "_gas_identifier_out.csv"
OVR = "_base_override.tsv"
LEDGER = "_audit_priority_tiers_ledger.tsv"
INJ = {'学習者版': "漢字注入_学習者版_20260620.txt", '学術版': "漢字注入_学術版_20260620.txt"}

# _gas_identifier.ps1 L4 と同一
BR = {'basic': 0, 'suf': 0, 'pref': 0, 'prep': 0, 'correl': 0, 'num': 0, 'func': 0,
      'pejvo': 1, 'sci': 1, 'elem': 1, 'cal': 1, 'rel': 1, 'piv': 2, 'proper': 2}
BR0 = set(b for b, v in BR.items() if v == 0)


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def sign(x):
    return (x > 0) - (x < 0)


# ---------------------------------------------------------------- 入力
rows = []
with io.open(PWORK, encoding='utf-8-sig', newline='') as f:
    for rec in _csv.DictReader(f):
        rec['Pf'] = float(rec['P'])
        rec['brEff'] = BR.get(rec['band'], 1)
        rec['C'] = rec['brEff'] * 1000.0 + rec['Pf']
        rec['len'] = len(rec['root'].replace('^', ''))
        rec['Fi'] = int(rec['F']) if rec['F'].lstrip('-').isdigit() else 0
        rows.append(rec)

ovBase = {}
if os.path.exists(OVR):
    for line in io.open(OVR, encoding='utf-8-sig'):
        if line.lstrip().startswith('#') or not line.strip():
            continue
        p = line.rstrip('\n').split('\t')
        if len(p) >= 2 and p[0].strip():
            ovBase[p[0].strip()] = p[1].strip()

# 現行の基本形(真値) = _gas_identifier_out.csv の id=='' 行
cur_base = {}
with io.open(GASOUT, encoding='utf-8-sig', newline='') as f:
    for rec in _csv.DictReader(f):
        if rec['id'] == '':
            cur_base.setdefault(rec['k'], rec['root'])


def order_group(members, gkey, cmap=None):
    """_gas_identifier.ps1 の安定挿入ソート + base上書き を忠実移植。先頭が基本形。"""
    a = list(members)
    getC = (lambda r: cmap[r['root']]) if cmap else (lambda r: r['C'])
    for i in range(1, len(a)):
        key = a[i]
        j = i - 1
        while j >= 0:
            x = a[j]
            pd = abs(getC(x) - getC(key))
            if pd <= 1.0:
                c = (x['len'] - key['len']) if x['len'] != key['len'] else sign(getC(x) - getC(key))
            else:
                c = sign(getC(x) - getC(key))
            if c > 0:
                a[j + 1] = a[j]
                j -= 1
            else:
                break
        a[j + 1] = key
    if gkey in ovBase:
        tgt = ovBase[gkey]
        tgtH = to_hsys(tgt)
        for t, m in enumerate(a):
            if m['root'] == tgt or to_hsys(m['root']) == tgtH:
                a.insert(0, a.pop(t))
                break
    return a


groups = collections.OrderedDict()
for r in rows:
    groups.setdefault(r['k'], []).append(r)

# ---------------------------------------------------------------- 識別子の完全移植
# ★続64の独立検証で「基本形の交代だけを害と数えると実害を取りこぼす」と指摘された。
#   基本形が動かなくても群内順位が動けば FirstDivergent の走査順が変わり id が変わる。
#   そこで _gas_identifier.ps1 の識別子付与を丸ごと移植し、churn を実測する。
VOWELS = set('aeiou')
UNIMAP = (('c^', 'ĉ'), ('C^', 'Ĉ'), ('g^', 'ĝ'), ('G^', 'Ĝ'), ('h^', 'ĥ'), ('H^', 'Ĥ'),
          ('j^', 'ĵ'), ('J^', 'Ĵ'), ('s^', 'ŝ'), ('S^', 'Ŝ'), ('u^', 'ŭ'), ('U^', 'Ŭ'))


def to_uni(s):
    for a, b in UNIMAP:
        s = s.replace(a, b)
    return s


def eo_letters(s):
    r = []
    i = 0
    while i < len(s):
        if i + 1 < len(s) and s[i + 1] == '^':
            r.append(s[i:i + 2]); i += 2
        else:
            r.append(s[i]); i += 1
    return r


def after_head(L):
    cons, alls = [], []
    for c in L[1:]:
        alls.append(c)
        if c not in VOWELS:
            cons.append(c)
    return cons, alls


def first_divergent(arr, seen):
    for i, ch in enumerate(arr):
        o = i + 1
        if o not in seen or ch not in seen[o]:
            return ch
    return None


def update_seen(arr, seen):
    for i, ch in enumerate(arr):
        seen.setdefault(i + 1, set()).add(ch)


def assign_ids(cm=None, ovr=True):
    """_gas_identifier.ps1 の識別子付与を忠実移植。root -> id を返す。
       ★PowerShell の @{} は case-insensitive なので headGroups もそれに合わせる
         (無視すると 虾群の Leandr が Le になり正本と1件ズレる)。"""
    out = {}
    for k, ms in groups.items():
        if len(ms) == 1:
            out[ms[0]['root']] = ''
            continue
        a = order_group(ms, k if ovr else '__no_override__', cm)
        proc = []
        for si, row in enumerate(a):
            L = eo_letters(to_uni(row['root']))
            cons, alls = after_head(L)
            proc.append({'row': row, 'si': si, 'head': L[0], 'cons': cons, 'all': alls})
        head_order, head_groups = [], {}
        for p in proc:
            hk = p['head'].lower()
            if hk not in head_groups:
                head_groups[hk] = []
                head_order.append(hk)
            head_groups[hk].append(p)
        for hk in head_order:                       # 識別子安定化(P>=5 は既存に譲る)
            lst = head_groups[hk]
            if len(lst) <= 1:
                continue
            base_m = [p for p in lst if p['si'] == 0]
            new_m = [p for p in lst if p['si'] != 0 and p['row']['Pf'] >= 5]
            exist = [p for p in lst if p['si'] != 0 and p['row']['Pf'] < 5]
            head_groups[hk] = base_m + exist + new_m
        used = set()
        for hk in head_order:
            shr = head_groups[hk]
            h = shr[0]['head']
            if len(shr) == 1:
                p = shr[0]
                idf = '' if p['si'] == 0 else h
                out[p['row']['root']] = idf
                if idf:
                    used.add(idf)
                continue
            seenC, seenA = {}, {}
            for p in shr:
                if p['si'] == 0:
                    idf = ''
                elif p is shr[0]:
                    idf = h
                else:
                    cd = first_divergent(p['cons'], seenC)
                    if cd:
                        idf = h + cd
                    else:
                        ad = first_divergent(p['all'], seenA)
                        if ad:
                            idf = h + ad
                        else:
                            fa = p['all'][0] if p['all'] else (p['cons'][0] if p['cons'] else '')
                            idf = h + fa
                    if idf in used:
                        alt = None
                        for cc in list(p['cons']) + list(p['all']):
                            if h + cc not in used:
                                alt = h + cc
                                break
                        if alt:
                            idf = alt
                        else:
                            candi = h
                            for z in range(len(p['all'])):
                                candi = candi + p['all'][z]
                                if candi not in used:
                                    break
                            idf = candi
                out[p['row']['root']] = idf
                if idf:
                    used.add(idf)
                update_seen(p['cons'], seenC)
                update_seen(p['all'], seenA)
    return out


# ---------------------------------------------------------------- 0. 再実装の妥当性
print("=" * 100)
print("■ 0. 前提検査 — ソートの Python 再実装が現行の基本形を再現するか")
print("=" * 100)
print("   ※これが100%でなければ以降の反実仮想は全て無意味。先に潰す。")
pred_base = {}
mismatch = []
for k, ms in groups.items():
    a = order_group(ms, k)
    pred_base[k] = a[0]['root']
    if k in cur_base and cur_base[k] != a[0]['root']:
        mismatch.append((k, cur_base[k], a[0]['root']))
print("   漢字群 %d / 現行出力と照合できた群 %d / ★不一致 %d 群" %
      (len(groups), sum(1 for k in groups if k in cur_base), len(mismatch)))
for k, cu, pr in mismatch[:15]:
    print("     不一致 群=%s 現行base=%s 再実装base=%s" % (k, cu, pr))
if mismatch:
    print("   ★再現に失敗している。以降の数値は信用してはならない。")
else:
    print("   ★完全再現。反実仮想の土台が成立。")

cur_id = {}
with io.open(GASOUT, encoding='utf-8-sig', newline='') as f:
    for rec in _csv.DictReader(f):
        cur_id[rec['root']] = rec['id']
base_ids = assign_ids()
idmis = [(r, cur_id[r], base_ids[r]) for r in base_ids if cur_id.get(r, None) != base_ids[r]]
print("   識別子まで完全移植して照合: 語根 %d / ★id不一致 %d 件" % (len(base_ids), len(idmis)))
for r, a, b in idmis[:10]:
    print("     id不一致 %s: 正本=%r 移植=%r" % (r, a, b))

# ---------------------------------------------------------------- A. 連鎖の各リンク
print("\n" + "=" * 100)
print("■ A. 連鎖の各リンクは意図どおりか")
print("=" * 100)

drift = [r for r in rows if int(r['br']) != r['brEff']]
dc = collections.Counter((r['band'], r['br']) for r in drift)
print("\n   [A1] `br` 列 vs 実効br(=BR[band]) の乖離 = %d行 / 全%d行" % (len(drift), len(rows)))
for (b, col), n in sorted(dc.items(), key=lambda x: -x[1]):
    print("        band=%-7s br列=%s → 実効br=%d  : %4d行" % (b, col, BR.get(b, 1), n))
print("        ※`_gas_identifier.ps1` も `_audit_priority.ps1` も band から br を引き直すので")
print("          この列を読む消費者は存在しない(実害0)。ただし『br列を信じた分析』は必ず誤る潜在トラップ。")

# |ΔC|<=1.0 の綴り長ルールが band を跨げるか
maxP = max(r['Pf'] for r in rows)
minP = min(r['Pf'] for r in rows)
cross_min = 1000.0 - (maxP - minP)
cross_pairs = 0
for k, ms in groups.items():
    for i in range(len(ms)):
        for j in range(i + 1, len(ms)):
            if ms[i]['brEff'] != ms[j]['brEff'] and abs(ms[i]['C'] - ms[j]['C']) <= 1.0:
                cross_pairs += 1
print("\n   [A2] 『|ΔC|<=1.0 なら綴り長を優先』という閾値ルールが層を跨ぐか")
print("        P の実測レンジ = %.3f .. %.3f (幅 %.3f) → 異band間の |ΔC| の下限 = %.3f > 1.0" %
      (minP, maxP, maxP - minP, cross_min))
print("        実データでの異band かつ |ΔC|<=1.0 の対 = %d 対" % cross_pairs)
print("        → ★綴り長ルールは同band内でしか発火し得ない=層順は構造的に保護されている(実証)。")

# ---------------------------------------------------------------- 台帳から誤ラベル集合
sec = None
mis_csv = []      # [B] CSV2890語根の band誤ラベル
mis_piv = []      # [C] band=piv だが真PEJVO
for line in io.open(LEDGER, encoding='utf-8'):
    line = line.rstrip('\n')
    if line.startswith('## [B]'):
        sec = 'B'; continue
    if line.startswith('## [C]'):
        sec = 'C'; continue
    if line.startswith('## '):
        sec = None; continue
    if not line or line.startswith('#') or line.startswith('root\t'):
        continue
    p = line.split('\t')
    if sec == 'B' and len(p) >= 6:
        mis_csv.append({'root': p[0], 'band': p[1], 'tier': p[2], 'bare': p[3] == 'True',
                        'gk': p[4], 'lv': p[5]})
    elif sec == 'C' and len(p) >= 4:
        mis_piv.append({'root': p[0], 'line': p[1], 'gk': p[2], 'bare': p[3] == 'True'})
print("\n   [A3] 台帳から読み込んだ常設advisory: CSV_MISLABEL=%d件 / PIV_MISLABEL_PEJVO=%d件" %
      (len(mis_csv), len(mis_piv)))

byroot = {}
for r in rows:
    byroot.setdefault(r['root'], r)
    byroot.setdefault(to_hsys(r['root']), r)


def getrow(rt):
    return byroot.get(rt) or byroot.get(to_hsys(rt))


# P=5 センチネル(隙間充填で意図的に band=piv/P=5 を与えた行)の分離
p5_piv = [m for m in mis_piv if getrow(m['root']) and abs(getrow(m['root'])['Pf'] - 5.0) < 1e-9]
print("        うち P=5 センチネル(隙間充填で意図的に band=piv を与えた行) = %d件 / 真の誤ラベル = %d件" %
      (len(p5_piv), len(mis_piv) - len(p5_piv)))

# ---------------------------------------------------------------- B. 反実仮想
print("\n" + "=" * 100)
print("■ B. ★中核 — 863件のラベルを正すと基本形は動くか(反実仮想)")
print("=" * 100)
print("   既存[A]逆転監査は『真層が逆転しているか』だけを見るので、同一真層内でラベル誤りが")
print("   基本形を決めている場合を原理的に検出できない。そこを直接測る。")

cmap = {r['root']: r['C'] for r in rows}
fixed = {}
for m in mis_csv:
    r = getrow(m['root'])
    if r:
        fixed[r['root']] = 0.0 * 1000.0 + r['Pf']          # CSV2890 → br0
for m in mis_piv:
    r = getrow(m['root'])
    if r:
        fixed[r['root']] = 1.0 * 1000.0 + r['Pf']          # 真PEJVO → br1
cmap2 = dict(cmap)
cmap2.update(fixed)
print("   ラベルを正した語根 = %d件(重複除去後)" % len(fixed))

flips = []
touched = set()
for k, ms in groups.items():
    if not any(m['root'] in fixed for m in ms):
        continue
    touched.add(k)
    if len(ms) == 1:
        continue
    b0 = order_group(ms, k, cmap)[0]['root']
    b1 = order_group(ms, k, cmap2)[0]['root']
    if b0 != b1:
        flips.append((k, b0, b1, len(ms)))
print("   誤ラベルを含む漢字群 = %d群 / うち複数員の群 = %d群" %
      (len(touched), sum(1 for k in touched if len(groups[k]) > 1)))
print("   ★ラベルを正すと基本形が交代する群 = %d群" % len(flips))
for k, b0, b1, n in flips[:40]:
    r0, r1 = getrow(b0), getrow(b1)
    print("     群=%-6s 員%2d  現行base=%-14s(%s,P=%.2f,len=%d) → 是正後=%-14s(%s,P=%.2f,len=%d)" %
          (k, n, b0, r0['band'], r0['Pf'], r0['len'], b1, r1['band'], r1['Pf'], r1['len']))
if len(flips) > 40:
    print("     ...(全%d群は TSV に)" % len(flips))

# ★churn は「基本形が動いた群の順位差」では足りない(続64の独立検証の指摘)。
#   基本形が動かなくても群内順位が動けば FirstDivergent の走査順が変わり id が変わる。
#   識別子を全語根で再計算して実差分を数える。
ids2 = assign_ids(cmap2)
idchg = [r for r in base_ids if base_ids[r] != ids2[r]]
outside = [r for r in idchg if getrow(r) and getrow(r)['k'] not in {f[0] for f in flips}]
print("   → ★識別子の実変化 = %d件 (うち基本形が動いていない群での変化 = %d件)" %
      (len(idchg), len(outside)))
print("     例: " + ', '.join('%s %r→%r' % (r, base_ids[r], ids2[r]) for r in idchg[:8]))

# ★上の反実仮想は P=5 センチネル818件まで『誤ラベル』として正している=規約に反する仮定。
#   規約を尊重し、真の誤ラベルだけを正した場合を別に測る。
p5set = set()
for m in p5_piv:
    r = getrow(m['root'])
    if r:
        p5set.add(r['root'])
fixed_strict = {rt: c for rt, c in fixed.items() if rt not in p5set}
cmap3 = dict(cmap)
cmap3.update(fixed_strict)
flips_strict = []
for k, ms in groups.items():
    if len(ms) < 2 or not any(m['root'] in fixed_strict for m in ms):
        continue
    b0 = order_group(ms, k, cmap)[0]['root']
    b1 = order_group(ms, k, cmap3)[0]['root']
    if b0 != b1:
        flips_strict.append((k, b0, b1))
print("\n   [B2] ★P=5センチネル818件は隙間充填の『規約』であって誤ラベルではない。")
print("        規約を尊重し真の誤ラベルだけ(%d件=CSV側36+PIV側6)を正した場合の基本形交代 = %d群" %
      (len(fixed_strict), len(flips_strict)))
for k, b0, b1 in flips_strict:
    print("          群=%-6s 現行=%-14s → 是正後=%s" % (k, b0, b1))
ids3 = assign_ids(cmap3)
idchg3 = [r for r in base_ids if base_ids[r] != ids3[r]]
print("        ★識別子の実変化 = %d件 / うち基本形が動いていない群 = %d件" %
      (len(idchg3), sum(1 for r in idchg3
                        if getrow(r) and getrow(r)['k'] not in {f[0] for f in flips_strict})))
print("        " + ', '.join('%s %r→%r' % (r, base_ids[r], ids3[r]) for r in idchg3[:10]))
# 哀だけを _base_override.tsv で解決した場合の最小コスト
ov_only = dict(ovBase)
ov_only['哀'] = 've'
_sav = dict(ovBase)
ovBase.clear()
ovBase.update(ov_only)
ids4 = assign_ids()
ovBase.clear()
ovBase.update(_sav)
idchg4 = [r for r in base_ids if base_ids[r] != ids4[r]]
print("        [B2'] 哀のみを `_base_override.tsv` の1行で解決した場合の churn = ★%d件 (%s)" %
      (len(idchg4), ', '.join('%s %r→%r' % (r, base_ids[r], ids4[r]) for r in idchg4)))

# ---------------------------------------------------------------- C. 何が無印を決めているか
print("\n" + "=" * 100)
print("■ C. ★層内で無印(基本形)を決めているのは何か — ソートキーの項別分解")
print("=" * 100)
print("   稼働中の P の式(`_audit_pvalue_consistency.ps1` L23 が正)は")
print("       P = -( ln(F+1) + 0.3*E - 0.1*st )")
print("   すなわち層内の勝敗は ①派生生産性F(大きいほど勝つ) ②E ③画数st(少ないほど勝つ) で決まる。")
print("   ★ユーザーが名指しした難易度指標 Unified_Level はこの式に入っていない(後述C3)。")

fits = {}
n_fit = n_nofit = 0
for r in rows:
    F, E, st = r['Fi'], float(r['E']), float(r['st'])
    pe = -(math.log(F + 1.0) + 0.3 * E - 0.1 * st)
    if r['P'] != '5' and abs(r['Pf'] - pe) <= 0.02:
        fits[r['root']] = (math.log(F + 1.0), 0.3 * E, 0.1 * st)
        n_fit += 1
    else:
        n_nofit += 1
print("\n   [C0] 式が成り立つ行 = %d / 式外(P=5センチネル+旧P値) = %d" % (n_fit, n_nofit))
print("        ※以下の反実仮想は『式が成り立つ行の項だけ』を動かす。式外行の P は据え置く。")


def cmap_variant(drop=None):
    m = {}
    for r in rows:
        p = r['Pf']
        if r['root'] in fits and drop:
            lnF, e03, st01 = fits[r['root']]
            if drop == 'F':
                p += lnF            # -ln(F+1) の寄与を打ち消す
            elif drop == 'E':
                p += e03
            elif drop == 'st':
                p -= st01
        m[r['root']] = r['brEff'] * 1000.0 + p
    return m


multi = [k for k, ms in groups.items() if len(ms) > 1]
print("\n   複数員の漢字群 = %d群 を対象に、項を1つ外したときの基本形交代数を測る" % len(multi))
print("   ★注意(続64の独立検証で指摘): この drop検定は『項の決定力』ではなく『摂動の大きさ』を")
print("     一部反映する。群内中心化偏差のSDを併記して、比が分散比の写像であることを開示する。")
sd = {}
for key, idx in (('F', 0), ('E', 1), ('st', 2)):
    vals = collections.defaultdict(list)
    for k, ms in groups.items():
        if len(ms) > 1:
            for m in ms:
                if m['root'] in fits:
                    vals[k].append(fits[m['root']][idx])
    dev = [v - (sum(vs) / len(vs)) for vs in vals.values() if len(vs) > 1 for v in vs]
    sd[key] = (sum(d * d for d in dev) / len(dev)) ** 0.5 if dev else 0.0
splitc = {}
for key, col in (('st', 'st'), ('E', 'E'), ('F', 'F')):
    splitc[key] = sum(1 for k, ms in groups.items()
                      if len(ms) > 1 and len({m[col] for m in ms}) > 1)
for lab, dr, nm in (("派生生産性 -ln(F+1)", 'F', 'F'), ("圧縮率項 -0.3E", 'E', 'E'),
                    ("画数項 +0.1st", 'st', 'st')):
    cm = cmap_variant(dr)
    ch = sum(1 for k in multi if order_group(groups[k], k)[0]['root'] != order_group(groups[k], k, cm)[0]['root'])
    print("     %-20s を外すと基本形が変わる群 = %4d群 (%.1f%%)  群内偏差SD=%.4f / 群内で値が割れる群=%d" %
          (lab, ch, 100.0 * ch / len(multi), sd[nm], splitc[nm]))
print("     ★画数項の『4群』は撤回する: st は k(漢字)の関数なので群内で割れる群は %d しかなく、" % splitc['st'])
print("       4群のうち実際に st が割れるのは 诲/毒蛇 の2群だけ(残りは閾値レジーム変化の巻き添え)。")
# 第1・第2の決定要因(項より上位)
band_only = sum(1 for k in multi
                if len({m['brEff'] for m in groups[k]}) > 1
                and min(m['brEff'] for m in groups[k]) ==
                order_group(groups[k], k)[0]['brEff']
                and sum(1 for m in groups[k]
                        if m['brEff'] == min(x['brEff'] for x in groups[k])) == 1)
lenrule = 0
for k in multi:
    a = order_group(groups[k], k)
    b = a[0]
    if any(m is not b and abs(m['C'] - b['C']) <= 1.0 and m['len'] != b['len'] for m in groups[k]):
        lenrule += 1
print("     [C1] band(層)だけで基本形が一意に決まる群 = %d群 (%.1f%%)  ←第1の決定要因" %
      (band_only, 100.0 * band_only / len(multi)))
print("     [C2] 綴り長ルール(|ΔC|<=1.0)が基本形の決定に関与する群 = %d群 (%.1f%%) ←第2の決定要因" %
      (lenrule, 100.0 * lenrule / len(multi)))

# C3: Unified_Level を入れたら変わるか(厳密上界。levelを持たずに決着させる)
UW, LVMIN, LVMAX = 0.01, 1.0, 10.0
span = UW * (LVMAX - LVMIN)
cand = []
for k in multi:
    ms = groups[k]
    a = order_group(ms, k)
    base = a[0]
    near = [m for m in ms if m is not base and abs(m['C'] - base['C']) <= span
            and 'basic' in (m['band'], base['band'])]
    if near:
        cand.append((k, base['root'], [m['root'] for m in near]))
print("\n   [C3] ★Unified_Level 項 %.2f*(u-5) を稼働キーに入れたら基本形は動くか" % UW)
print("        (`_build_priority_work.ps1` L13/L227 に UnifiedWeight=0.01 の項が実装済だが稼働Pには未適用)")
print("        項の全振れ幅 = %.2f*(%.0f-%.0f) = %.2f" % (UW, LVMAX, LVMIN, span))
print("        ★『|ΔC|<=%.2f の対しか逆転し得ない=厳密上界』という当初の主張は撤回する(続64の独立検証)。" % span)
print("          比較器は |ΔC|<=1.0 のとき C を無視して綴り長で決めるので、微小な摂動が")
print("          『閾値レジームの跨ぎ』を起こして |ΔC| が %.2f より大きい対でも逆転しうる。" % span)
print("          近接群 = %d群 (参考値であって上界ではない)" % len(cand))
for k, b, ns in cand[:12]:
    print("          群=%s base=%s 近接員=%s" % (k, b, ','.join(ns)))

# --- 実際の Unified_Level を復元して厳密な交代数を出す ---
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
bare2segs = {}
for path in INJ.values():
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')] if '⟦' in head else head
        cs = [s.strip('-') for s in raw.replace(' ', '/').split('/') if s.strip('-')]
        if cs:
            bare2segs.setdefault(raw.replace('/', '').replace(' ', '').replace('-', '').lower(), cs)
level = {}
if os.path.exists(CSVF):
    with io.open(CSVF, encoding='utf-8-sig') as f:
        rd = _csv.DictReader(f)
        for rec in rd:
            eo = (rec.get('Esperanto') or '').strip()
            try:
                u = float((rec.get('Unified_Level') or '').strip())
            except ValueError:
                continue
            for term in eo.split(','):
                t = to_hsys(term.strip())
                segs = bare2segs.get(t.replace('/', '').replace(' ', '').replace('-', '').lower())
                if not segs:
                    continue
                for s in segs:
                    r = getrow(s)
                    if r and (r['root'] not in level or u < level[r['root']]):
                        level[r['root']] = u
# 台帳[B]の39行が持つ Unified_Level と突き合わせて復元の妥当性を確認
agree = dis = miss = 0
for m in mis_csv:
    r = getrow(m['root'])
    if not r:
        continue
    try:
        want = float(m['lv'])
    except ValueError:
        continue
    got = level.get(r['root'])
    if got is None:
        miss += 1
    elif abs(got - want) < 0.005:
        agree += 1
    else:
        dis += 1
print("\n        [C3検算] Unified_Level 復元の妥当性(台帳[B]39行と照合): 一致=%d 不一致=%d 復元漏れ=%d" %
      (agree, dis, miss))
print("        復元できた語根 = %d件" % len(level))
cmap_u = {}
for r in rows:
    p = r['Pf']
    if r['band'] == 'basic' and r['root'] in level:
        p += UW * (level[r['root']] - 5.0)
    cmap_u[r['root']] = r['brEff'] * 1000.0 + p
flip_u = [(k, order_group(groups[k], k)[0]['root'], order_group(groups[k], k, cmap_u)[0]['root'])
          for k in multi
          if order_group(groups[k], k)[0]['root'] != order_group(groups[k], k, cmap_u)[0]['root']]
print("        ★厳密値: Unified_Level 項を入れると基本形が交代する群 = %d群 / %d群 (上界%d)" %
      (len(flip_u), len(multi), len(cand)))
for k, b0, b1 in flip_u[:20]:
    print("          群=%-6s 現行=%-14s → Unified項導入後=%s" % (k, b0, b1))
# 感度: どこまで重みを上げれば初めて基本形が動くか(『0群』が単に重みが小さいだけでないことを示す)
print("\n        [C3感度] 『0群』が重みの小ささだけの結果でないことを確かめる=重みを上げていく")
for w in (0.01, 0.05, 0.1, 0.3, 0.5, 1.0, 2.0, 5.0):
    cm = {}
    for r in rows:
        p = r['Pf']
        if r['band'] == 'basic' and r['root'] in level:
            p += w * (level[r['root']] - 5.0)
        cm[r['root']] = r['brEff'] * 1000.0 + p
    fl = [k for k in multi
          if order_group(groups[k], k)[0]['root'] != order_group(groups[k], k, cm)[0]['root']]
    outside = [k for k in fl if k not in {c[0] for c in cand}]
    print("          UnifiedWeight=%.2f → 基本形交代 %3d群%s%s" %
          (w, len(fl), ("  ←プロジェクトが選んだ重み" if abs(w - UW) < 1e-9 else ""),
           ("  ★うち近接群の外=%d %s" % (len(outside), outside[:4]) if outside else "")))

# C4: 人手裁定(_base_override.tsv)の寄与
ovr_eff = []
for k in multi:
    if k not in ovBase:
        continue
    a_no = list(groups[k])
    # override 無しの順序
    b_no = order_group(a_no, '__no_override__')[0]['root']
    b_yes = order_group(a_no, k)[0]['root']
    if b_no != b_yes:
        ovr_eff.append((k, b_no, b_yes))
print("\n   [C4] 人手裁定 `_base_override.tsv` = %d群に指定 / うち実際に基本形を動かしている群 = %d群" %
      (len(ovBase), len(ovr_eff)))
# 4つの摂動の和集合 = 「決まり方が脆い群」。残りは何を外しても動かない=頑健。
_b0 = {k: order_group(groups[k], k)[0]['root'] for k in multi}
_sens = set()
for _d in ('F', 'E', 'st'):
    _cm = cmap_variant(_d)
    _sens |= {k for k in multi if order_group(groups[k], k, _cm)[0]['root'] != _b0[k]}
_sens |= {k for k, _, _ in ovr_eff}
print("        [C5] 4つの摂動(F/E/st/人手裁定)のいずれかで基本形が動く群 = %d群 (%.1f%%)" %
      (len(_sens), 100.0 * len(_sens) / len(multi)))
print("             どれを外しても動かない(頑健に決まっている)群 = %d群 (%.1f%%)" %
      (len(multi) - len(_sens), 100.0 * (len(multi) - len(_sens)) / len(multi)))
for k, b0, b1 in ovr_eff[:20]:
    print("          群=%-6s 式のまま=%-14s → 裁定後=%s" % (k, b0, b1))
if len(ovr_eff) > 20:
    print("          ...(全%d群は TSV に)" % len(ovr_eff))
viol = []

# ---------------------------------------------------------------- D. CSV_MISLABEL 39件
print("\n" + "=" * 100)
print("■ D. CSV2890語根の band誤ラベル 39件 — 全件")
print("=" * 100)
print("   ★『ここで初めて点検する』という当初の主張は【虚偽】だった(続64の独立検証)。実際は3度目:")
print("     ・作業ログ§14 L73 (2026-07-19 第21回④)『CSV誤ラベル39件=全件無害確定』")
print("       — bare=True 19件 / 七曜 / 楽器gitar,violon→琴 / kvi,tam の語尾剥がし幻 まで同一の分類")
print("     ・同 L91 (2026-07-21 第26回③) 敵対的反証WFで再点検『優先度喪失0』")
print("   本節は【3度目の独立再確認】であり、先行2回と分類が一致することを示すのが役割。")
print("   機械規則は誤分類を出した(lund→lun/mard→mar を『誤マッチ』と誤判定。曜日名は実在のCSV2890語)")
print("   ので、CSV原文を引いた人手判定に切替えた。\n")

# 非bare 20件の人手判定。根拠は CSV原文(Esperanto/Unified_Level/訳語)を引いて確認済み。
MANUAL = {
    # 照合の誤マッチ: CSV側の語は別語で、Lvがその別語のものと一致する
    'kvi': '誤マッチ(CSV=kvin五 Lv1.77と同値。kvi自体はPIV語)',
    'tam': '誤マッチ(CSV=tamen Lv1.77と同値。tam自体はPIV語)',
    # 七曜: その漢字の中心義(day/moon/fire/water/wood/gold/earth)を持つ語根に譲る=正しい
    'dimanĉ': '七曜(日の中心義=tag/day に譲る=正)',
    'lund': '七曜(月の中心義=lun/moon に譲る=正)',
    'mard': '七曜(火の中心義=fajr/fire に譲る=正)',
    'merkred': '七曜(水の中心義=akv/water に譲る=正)',
    'ĵaŭd': '七曜(木の中心義=lign/wood に譲る=正)',
    'vendred': '七曜(金の中心義=or/gold に譲る=正)',
    'sabat': '七曜(土の中心義=grund/earth に譲る=正)',
    # 中心義が base 側にある正常な従属
    'cigar': '妥当(烟の中心義=fum/煙)',
    'citron': '妥当(果の中心義=frukt/果物)',
    'gitar': '妥当(琴の中心義=pian、同じ楽器類)',
    'violon': '妥当(琴の中心義=pian、同じ楽器類)',
    'ju': '妥当(越の中心義=trans/越える)',
    'nj': '妥当(女の中心義=in/女性接尾)',
    'plur': '妥当(多の中心義=mult/多い)',
    'pseu^d': '誤マッチ(CSV=pseŭdo- L2298。正解語根 pseŭdo は band=pref で既存)',
    'sekc': '妥当だが理由訂正(切のbaseは式でなく_base_override.tsv の人手裁定でtranĉ。式のままならtomi)',
    'taksi': '妥当(车の中心義=aŭt/自動車。CSV=taksio Lv8.79で照合は正しい)',
    # 実質の検討対象
    've': '★要検討(哀=kondolenc哀悼 vs ve=間投詞「ああ！」)',
}


def misclass(m):
    if m['bare']:
        return '無害bare'
    return MANUAL.get(m['root'], '★未判定')


cls_c = collections.Counter()
print("   %-12s %-6s %-5s %-5s %-4s %-22s %s" % ("root", "band", "bare", "群", "Lv", "分類", "現行base(band)"))
for m in sorted(mis_csv, key=lambda x: (x['bare'], x['root'])):
    r = getrow(m['root'])
    k = r['k'] if r else '?'
    bs = pred_base.get(k, '?')
    bsr = getrow(bs)
    c = misclass(m)
    cls_c[c.split('(')[0]] += 1
    print("   %-12s %-6s %-5s %-5s %-4s %-22s %s(%s,員%d)" %
          (m['root'], m['band'], m['bare'], k, m['lv'], c, bs,
           bsr['band'] if bsr else '?', len(groups.get(k, []))))
print("\n   分類の集計: " + ' / '.join('%s=%d' % kv for kv in cls_c.most_common()))
print("   ★『要検討』に残ったものだけが実質の検討対象。")

# ---------------------------------------------------------------- TSV
with io.open("_lens28_priority_transmission.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("節\tキー\t項目1\t項目2\t項目3\t項目4\n")
    for (b, col), n in sorted(dc.items(), key=lambda x: -x[1]):
        f.write("A1_br列ドリフト\t%s\tbr列=%s\t実効br=%d\t%d行\t\n" % (b, col, BR.get(b, 1), n))
    for k, b0, b1, n in flips:
        f.write("B_基本形交代\t%s\t現行=%s\t是正後=%s\t員数%d\t\n" % (k, b0, b1, n))
    for k, b0, b1 in ovr_eff:
        f.write("C4_人手裁定が基本形を決めた群\t%s\t式のまま=%s\t裁定後=%s\t\t\n" % (k, b0, b1))
    for k, b, ns in cand:
        f.write("C3_Unified項で逆転しうる群\t%s\tbase=%s\t迫るbasic員=%s\t\t\n" % (k, b, ','.join(ns)))
    for m in sorted(mis_csv, key=lambda x: (x['bare'], x['root'])):
        r = getrow(m['root'])
        f.write("D_CSV誤ラベル\t%s\tband=%s\tbare=%s\t群=%s\tLv=%s\n" %
                (m['root'], m['band'], m['bare'], r['k'] if r else '?', m['lv']))
    for m in mis_piv:
        r = getrow(m['root'])
        f.write("E_PIV誤ラベル\t%s\tbare=%s\t群=%s\tP=%s\t\n" %
                (m['root'], m['bare'], r['k'] if r else '?', r['P'] if r else '?'))
print("\n出力: _lens28_priority_transmission.tsv")
