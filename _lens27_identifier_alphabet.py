# -*- coding: utf-8 -*-
# 第27レンズ「識別子アルファベットの体系性」 (第27回続63)
#
#   識別子は 密度(第8)・衝突解消力(第9,23)・長さ(第3)・時間軸(第25) で測ってきたが、
#   すべて【識別子を不透明な記号として】扱っていた。第25の批判[C5]が明示的に残した問い:
#     ★上付き文字は家族ローカルに再利用される(ᴴ = hidr(水ᴴ) / hermini(蛾ᴴ) / higien(卫ᴴ))。
#      つまり「上付き→語根」の対応は全域では一意でない。この横断的干渉は未測定。
#   本レンズは識別子を【記号体系】として測る:
#     A 生成規則の適合率 — id は語根綴りの先頭から機械的に導けるか(=学習者が予測できるか)
#     B 横断的多義度 — 同じ識別子文字列が全体で何語根を指すか
#     C 予測可能性 — 語根を知る学習者が「この語根の識別子」を当てられるか(群内競合を解いて)
#     D 復号方向 — 識別子を見て群内の語根を一意に絞れるか
#     E 優先順位との関係 — 上位層ほど予測しやすい/短い/干渉が少ないか
#   併せて 続62 で投入した識別子込み鏡像15件が体系に整合するかを検査する。
import io, os, re, sys, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
SIDE = "_identifier_sidecar.tsv"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
INJ = "漢字注入_学習者版_20260620.txt"
INJ2 = "漢字注入_学術版_20260620.txt"
SEP = re.compile(r'[/ ]')
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
# 続62 で投入した識別子込み鏡像(体系整合の別掲用)
MIRROR62 = {'aerosol', 'akvedukt', 'bikonkav', 'bikonveks', 'biplan', 'centiar', 'endoskopi',
            'inciziv', 'megalosaŭr', 'mikroskopi', 'piroz', 'reformator', 'resonator',
            'trikromi', 'trirem'}


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


# ---------- sidecar ----------
roots = {}
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    root, kanji, idr, idsup, disp, band, F, gk = p[:8]
    roots[root] = {'kanji': kanji, 'id': idr, 'sup': idsup, 'disp': disp, 'band': band,
                   'F': int(F) if F.isdigit() else 0, 'gk': gk}
fam = collections.defaultdict(list)
for r, d in roots.items():
    fam[d['gk']].append(r)
marked = {r: d for r, d in roots.items() if d['id']}
print("語根 %d / マーク付き %d / 家族(2人以上) %d" %
      (len(roots), len(marked), sum(1 for v in fam.values() if len(v) >= 2)))

# ---------- 層 ----------
bare2segs = {}
first_line = {}
for path in (INJ, INJ2):
    ln = 0
    for line in io.open(path, encoding='utf-8-sig'):
        ln += 1
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')] if '⟦' in head else head
        for s in SEP.split(raw):
            s = s.strip('-')
            if s and (s not in first_line or ln < first_line[s]):
                first_line[s] = ln
        if path == INJ and ' ' not in raw:
            cs = [s for s in raw.split('/') if s]
            while len(cs) > 1 and cs[-1] in ENDPOP:
                cs.pop()
            if cs:
                bare2segs.setdefault(raw.replace('/', ''), [c.strip('-') for c in cs])
csv_roots = set()
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        for tok in rec[0].split(','):
            w = to_hsys(tok.strip()).replace('/', '').replace('-', '').lower()
            segs = bare2segs.get(w)
            if segs and len(segs) == 1:
                csv_roots.add(segs[0])


def tier(r):
    d = roots[r]
    if d['band'] in GRAMMAR:
        return '文法層'
    rh = to_hsys(r)
    if rh in csv_roots or r in csv_roots:
        return 'CSV2890'
    if d['band'] == 'piv':
        return 'PIV'
    return 'PEJVO'


TIERS = ['文法層', 'CSV2890', 'PEJVO', 'PIV']

# ================================================================
# A. 生成規則の適合率
# ================================================================
print("\n" + "=" * 100)
print("■ A. 生成規則 — id は語根綴りから機械的に導けるか(=学習者が予測できるか)")
print("=" * 100)
kinds = collections.Counter()
odd = []
for r, d in marked.items():
    rid = d['id']
    # ★両側を h-system に正規化してから比較する。片側だけだと ĉe/ĉ 型が
    #   全て「規則外」に落ちる([[reference-audit-encoding-mixture]]の既知トラップ。
    #   v1で実際に踏み、id にUnicode特殊字を含む173件がまるごと誤分類されていた)
    rl = to_hsys(r).lower()
    idl = to_hsys(rid).lower()
    if rl.startswith(idl):
        kinds[('接頭辞', len(rid))] += 1
        continue
    # 子音抜き出し(先頭+以降の子音)
    cons = rl[0] + ''.join(c for c in rl[1:] if c not in 'aeiou')
    if cons.startswith(idl):
        kinds[('先頭+子音', len(rid))] += 1
        continue
    if all(c in rl for c in idl):
        kinds[('綴り内の文字', len(rid))] += 1
        odd.append((r, rid, d['disp']))
    else:
        kinds[('規則外', len(rid))] += 1
        odd.append((r, rid, d['disp']))
tot = sum(kinds.values())
agg = collections.Counter()
for (k, L), c in kinds.items():
    agg[k] += c
print("   ※実際の生成規則(_gas_identifier.ps1): 頭文字。頭文字が群内で競合する場合のみ")
print("     『頭文字＋最初に分岐する子音』(子音で分岐しなければ全文字列で分岐、それも尽きたら漸進接頭辞)。")
print("   マーク付き %d 件の id と語根綴りの関係:" % tot)
for k in ('接頭辞', '先頭+子音', '綴り内の文字', '規則外'):
    if agg[k]:
        print("      %-12s %5d (%5.1f%%)" % (k, agg[k], 100.0 * agg[k] / tot))
print("   ★『語根の先頭文字そのまま』が %.1f%%、『先頭+子音』を足すと %.1f%% が綴りから直に導ける。" %
      (100.0 * agg['接頭辞'] / tot, 100.0 * (agg['接頭辞'] + agg['先頭+子音']) / tot))
print("     残りも綴り内の文字の組合せで、無関係な記号を割り当てた例は %.1f%% のみ。" %
      (100.0 * agg['規則外'] / tot))
if odd:
    print("   綴りの先頭からは読めない例(最大12): %s" % ', '.join('%s→%s(%s)' % o for o in odd[:12]))

# 層別の id 長
print("\n   層別の id 長(短いほど負荷が軽い):")
for t in TIERS:
    ls = [len(d['id']) for r, d in marked.items() if tier(r) == t]
    if ls:
        print("      %-9s n=%-5d 平均 %.2f 文字 / 1文字率 %.1f%%" %
              (t, len(ls), sum(ls) / len(ls), 100.0 * sum(1 for x in ls if x == 1) / len(ls)))

# ================================================================
# B. 横断的多義度
# ================================================================
print("\n" + "=" * 100)
print("■ B. 横断的多義 — 同じ識別子文字列が全体で何語根を指すか([C5]が提起した干渉)")
print("=" * 100)
by_id = collections.defaultdict(list)
for r, d in marked.items():
    by_id[d['sup']].append(r)
sizes = collections.Counter(len(v) for v in by_id.values())
print("   異なる識別子文字列 %d 種 / マーク付き語根 %d" % (len(by_id), len(marked)))
print("   1つの識別子が指す語根数の分布: " +
      ' '.join('%d語根=%d種' % (k, v) for k, v in sorted(sizes.items())[:8]) +
      (' …最大 %d' % max(sizes)))
worst = sorted(by_id.items(), key=lambda x: -len(x[1]))[:8]
print("   最も多義な識別子:")
for sup, rs in worst:
    print("      %-4s %3d語根: %s…" % (sup, len(rs),
          ', '.join('%s(%s)' % (r, roots[r]['disp']) for r in sorted(rs, key=lambda x: -roots[x]['F'])[:5])))
print("   ★ただし識別子は【家族の中でだけ】読めばよい。全域の多義は学習者の課題ではない。")
print("     真の問いは C(語根→id が当てられるか) と D(家族内で id→語根 が一意か)。")

# ================================================================
# C. 逆引き可能性 — 学習者は id から語根を絞れるか
#   実際の生成規則(_gas_identifier.ps1 実装)は
#     「頭文字。頭文字が群内で競合するときのみ 頭文字+最初に分岐する子音(無ければ全文字)」
#   なので、学習者側の反転規則は
#     「id の先頭字 = 語根の先頭字 / 残りの id 文字は語根内に(頭文字より後で)順に現れる」
#   これで家族メンバーを絞れるか(候補が1つなら逆引き成功)を測る。
# ================================================================
print("\n" + "=" * 100)
print("■ C. 逆引き可能性 — 学習者規則『先頭字一致＋残り文字が語根内に順出現』で1語根に絞れるか")
print("=" * 100)


def compatible(idstr, root):
    """id の先頭字=語根の先頭字 かつ 残りの id 文字が語根内に順に現れるか。
       ★両側を h-system に正規化(片側だけだと ĉe/ĉ 型が全滅=v1のバグ)。
       h-system の ^ は直前字と一体の1字として扱う(c^ を2字と数えない)。"""
    def units(s):
        s = to_hsys(s).lower()
        out, i = [], 0
        while i < len(s):
            if i + 1 < len(s) and s[i + 1] == '^':
                out.append(s[i:i + 2])
                i += 2
            else:
                out.append(s[i])
                i += 1
        return out
    ru, iu = units(root), units(idstr)
    if not ru or not iu or ru[0] != iu[0]:
        return False
    pos = 1
    for c in iu[1:]:
        try:
            nxt = ru.index(c, pos)
        except ValueError:
            return False
        pos = nxt + 1
    return True


res = collections.Counter()
amb_ex = []
for gk, mem in fam.items():
    if len(mem) < 2:
        continue
    for r in mem:
        d = roots[r]
        if not d['id']:
            continue
        cands = [x for x in mem if compatible(d['id'], x)]
        t = tier(r)
        if len(cands) == 1:
            res[(t, 'ok')] += 1
        else:
            res[(t, 'ng')] += 1
            if len(amb_ex) < 10:
                amb_ex.append((d['disp'], d['id'], r, [x for x in cands if x != r][:3]))
print("   %-9s %8s %8s %s" % ("層", "一意", "候補複数", "逆引き成功率"))
for t in TIERS:
    a, b = res[(t, 'ok')], res[(t, 'ng')]
    if a + b:
        print("   %-9s %8d %8d %9.1f%%" % (t, a, b, 100.0 * a / (a + b)))
A = sum(res[(t, 'ok')] for t in TIERS)
B = sum(res[(t, 'ng')] for t in TIERS)
print("   %-9s %8d %8d %9.1f%%" % ('全体', A, B, 100.0 * A / max(1, A + B)))
if amb_ex:
    print("   候補が複数残る例(語根を丸暗記しないと決められない):")
    for disp, i, r, others in amb_ex[:8]:
        print("      %-8s id=%-3s 正解=%-12s 他候補=%s" % (disp, i, r, ', '.join(others)))

# ================================================================
# D. 識別子空間の近傍 — 末尾マークを1つ見落とすと別語根になるか
#   ★第23レンズは識別子を【外した】漢字列で近傍衝突を測った(識別子を属性として扱った)。
#     識別子そのものが作る近傍(穿ᴾ vs 穿ᴾᴿ)は原理的に測っていない=本節が初。
# ================================================================
print("\n" + "=" * 100)
print("■ D. 識別子空間の近傍 — マークを取りこぼすと別語根に着地するか(第23レンズの死角)")
print("=" * 100)
dup = 0
for gk, mem in fam.items():
    c = collections.Counter(roots[r]['sup'] for r in mem)
    if any(v > 1 for v in c.values()):
        dup += 1
print("   家族内で識別子が完全重複する群 = %d (0が正=§9契約の実測)" % dup)

# (1) 全マーク付き語根は「マークを全部落とす」と家族の基本形になる = 最大の近傍
base_of = {}
for gk, mem in fam.items():
    b = [r for r in mem if not roots[r]['id']]
    if len(b) == 1:
        base_of[gk] = b[0]
n_mark = sum(1 for r, d in roots.items() if d['id'])
fw = sum(d['F'] for r, d in roots.items() if d['id'])
print("   (1) マークを完全に見落とすと家族の基本形に着地する: 全マーク付き %d 件が該当(構造的)" % n_mark)
print("       ただし着地先は必ず【同じ字を共有する=意味的に隣接した】語根で、無関係語ではない。")

# (2) 部分的な取りこぼし: id が他メンバーの id の真の接頭辞
pref_pairs = []
for gk, mem in fam.items():
    ids = [(r, to_hsys(roots[r]['id']).lower()) for r in mem if roots[r]['id']]
    for r1, i1 in ids:
        for r2, i2 in ids:
            if r1 != r2 and i2.startswith(i1) and len(i1) < len(i2):
                pref_pairs.append((gk, r2, i2, r1, i1))   # r2 の末尾を落とすと r1 になる
print("   (2) 長いidの末尾を落とすと同じ家族の別語根になる対 = %d" % len(pref_pairs))
by_t = collections.Counter(tier(x[1]) for x in pref_pairs)
print("       被害側(長いid)の層別: " + ' / '.join('%s %d' % (t, by_t[t]) for t in TIERS if by_t[t]))
risk_f = sorted(pref_pairs, key=lambda x: -(roots[x[1]]['F'] + roots[x[3]]['F']))[:8]
print("       頻度が高い(=実際に目にする)対:")
for gk, rl_, il, rs, is_ in risk_f:
    print("      %-6s %s(%s F=%d) の末尾を落とすと → %s(%s F=%d)" %
          (gk, roots[rl_]['disp'], rl_, roots[rl_]['F'], roots[rs]['disp'], rs, roots[rs]['F']))
tot_marked_pairs = sum(len([r for r in mem if roots[r]['id']]) for mem in fam.values())
print("   ★率: マーク付き語根 %d のうち、末尾を落とすと別のマーク付き語根になるものが %d 件(%.1f%%)。" %
      (n_mark, len(set(x[1] for x in pref_pairs)),
       100.0 * len(set(x[1] for x in pref_pairs)) / max(1, n_mark)))
print("     残りは落とすと基本形に着地する。いずれも着地先は同じ字の家族内=意味的に隣接。")

# ================================================================
# E. 続62の鏡像15件の体系整合
# ================================================================
print("\n" + "=" * 100)
print("■ E. 続62で投入した識別子込み鏡像15件は体系に整合するか")
print("=" * 100)
found = 0
for r in sorted(MIRROR62):
    d = roots.get(r) or roots.get(to_hsys(r))
    if not d:
        print("   %-12s (sidecar未登録?)" % r)
        continue
    found += 1
    same = fam[d['gk']]
    print("   %-12s disp=%-10s 自身のid=%-4s 群サイズ=%d %s" %
          (r, d['disp'], d['id'] or '(無印)', len(same),
           '' if len(same) == 1 else '← ' + ', '.join(x for x in same if x != r)))
print("   ★15件とも群サイズ1(=識別子込み表面が一意)なら、鏡像は既存体系に干渉していない。")
print("     内包する上付きは成分語根のもので、本語根自身の識別子ではない(逆引きは表面全体で一意)。")

# ---------- TSV ----------
with io.open("_lens27_identifier_alphabet.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("語根\t層\tdisp\tid\t群サイズ\tF\t綴りとの関係\t逆引き候補数\t末尾を落とすと\n")
    for gk, mem in sorted(fam.items()):
        base = [x for x in mem if not roots[x]['id']]
        for r in mem:
            d = roots[r]
            if not d['id']:
                continue
            rl = to_hsys(r).lower()
            idl = to_hsys(d['id']).lower()
            cons = rl[0] + ''.join(c for c in rl[1:] if c not in 'aeiou')
            rule = ('接頭辞' if rl.startswith(idl) else
                    ('先頭+子音' if cons.startswith(idl) else
                     ('綴り内の文字' if all(c in rl for c in idl) else '規則外')))
            cands = [x for x in mem if compatible(d['id'], x)]
            shorter = [x for x in mem if roots[x]['id'] and x != r and
                       idl.startswith(to_hsys(roots[x]['id']).lower()) and
                       len(to_hsys(roots[x]['id'])) < len(to_hsys(d['id']))]
            land = shorter[0] if shorter else (base[0] if base else '')
            f.write("%s\t%s\t%s\t%s\t%d\t%d\t%s\t%d\t%s\n" %
                    (r, tier(r), d['disp'], d['id'], len(mem), d['F'], rule, len(cands), land))
print("\n出力: _lens27_identifier_alphabet.tsv")
