# -*- coding: utf-8 -*-
# 第20レンズ「合成語の中での接地＝固定形態素描画の文脈コスト」 2026-07-28
#
#   第1〜19レンズは測定単位が【語根】【語根の語義】【語根の履歴】のいずれかだった。
#   第17レンズ(訳語グラウンディング)ですら「語根の字 vs その語根自身の訳語」であり、
#   **その字が“合成語の中に置かれたとき”も意味を担えているか**は一度も測っていない。
#
#   これは本プロジェクトの中心機構そのものの検査である:
#     固定形態素描画 = 各形態素は文脈によらず1つの master 字で描かれる
#   利点は一貫性、コストは【文脈での意味ずれ】。語根単体の訳語には接地していても
#   その語根を含む合成語の訳語には現れない、という取りこぼしは
#   語根単位の集計では**原理的に見えない**(語根としては満点になる)。
#
# ── 測定設計上の最大の障害と、その解き方 ──────────────────────────────
#   語釈は全層とも【日本語】である(CSV2890だけが中国語訳を併記)。割り当ては簡体字なので
#   素朴に照合すると elektr=电 が語釈「電気」に当たらず、字体差だけで大量の偽陽性が出る
#   (実測: 候補1768件の上位はほぼ全て 电/電・语/語・书/書・纸/紙・时/時 型)。
#   そこで **同一形態素・同一字を「単独語」と「合成語の中」の二条件で測り、その比を見る**。
#   字体差ペナルティは同じ字・同じ語釈言語なので分子分母で相殺される。
#   さらに単独語で一度も接地しない形態素(=字体差で測定不能な字)は比が未定義になり
#   自動的に脱落する。これで交絡を機構的に除去できる。
#
#   ★接辞トークンは内容形態素と別勘定。-eg-(大)・-in-(女)・-ej-(所) 等は文法演算子で
#     varm/eg/a=「酷暑」のように訳語に字が現れないのが正常。
#   ★mal-/sen-/ne- を含む語は測定対象から除く。意味を反転させる語であり
#     mal/varm/a=「寒い」に varm=暖 が現れないのは正しい挙動だからである。
#
# 出力: _lens20_context_ledger.tsv  (形態素ごとの単独時/合成時の接地)
#       _lens20_candidates.tsv      (単独では接地するのに合成語で落ちる形態素＝是正候補)
import io, os, re, csv as _csv, collections, sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = "漢字注入_学習者版_20260620.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
SIDE = "_identifier_sidecar.tsv"
PEJVO_END = 44104        # ここまでが PEJVO 本体
SUPL_END = 44440         # 44105〜44440 は PEJVO 追補
FUNC = {'suf', 'pref', 'prep', 'correl', 'num', 'func'}
NEGATORS = {'mal', 'sen', 'ne'}
OFFSET = 499             # chance level 用の固定巡回シフト(第17レンズと同じ手法)


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def is_cjk(ch):
    return '一' <= ch <= '鿿'


def cjk_only(s):
    return ''.join(c for c in s if is_cjk(c))


# 語釈から「訳語でないもの」を落とす。残すのは訳語本文だけ。
#   【解】【動】…分野タグ / {Ｏ}{Ｂ}…出典・用法タグ / ［他］［形容詞語尾］…文法注記
#   >>xxx …参照見出し(エス語) / ##偽分解… 内部マーカー / [词尾][后缀] …中国語側のタグ
_NOISE = [re.compile(p) for p in (
    r'##.*$', r'【[^】]*】', r'\{[^}]*\}', r'［[^］]*］', r'\[[^\]]*\]',
    r'>>[^,;，；]*', r'(?<![^\s,;，；])=[A-Za-z^\-]+')]


def clean_gloss(s):
    for r in _NOISE:
        s = r.sub('', s or '')
    return s


def measurable(txt):
    """訳語に漢字が1字も無ければ判定不能(PIV層のエスペラント語釈対策・第17レンズの教訓)"""
    return bool(txt) and any(is_cjk(c) for c in txt)


# ---------- 1. sidecar: 分節 -> band ----------
band = {}
with io.open(SIDE, encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 6:
            band[to_hsys(p[0])] = p[5]

# ---------- 2. CSV2890: 語 -> (日本語訳, 中国語訳) ----------
csv_ja, csv_zh = {}, {}
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        for term in rec[0].split(','):
            t = to_hsys(term.strip())
            if t:
                csv_ja[t] = rec[1] if len(rec) > 1 else ''
                csv_zh[t] = rec[2] if len(rec) > 2 else ''

# ---------- 3. 注入済み学習者版を読み、語ごとにトークン分解 ----------
SEP = re.compile(r'[/ ]')
words = []
with io.open(INJ, encoding='utf-8-sig') as f:
    for lineno, line in enumerate(f, 1):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head, gloss = line.split(':', 1)
        if '⟦' not in head or '⟧' not in head:
            continue
        raw = head[:head.index('⟦')]
        disp = head[head.index('⟦') + 1:head.rindex('⟧')]
        segs, disps = SEP.split(raw), SEP.split(disp)
        if len(segs) != len(disps):
            continue                                   # 1:1整列が崩れた行(実測0件)
        toks = [(s, cjk_only(d), band.get(s, '') not in FUNC)
                for s, d in zip(segs, disps) if cjk_only(d)]
        if not toks:
            continue
        bare = raw.replace('/', '').replace(' ', '')
        if bare in csv_zh:
            tier = 0
        elif lineno <= PEJVO_END:
            tier = 1
        elif lineno <= SUPL_END:
            tier = 2
        else:
            tier = 3
        if '【PIV】' in gloss and tier != 0:
            tier = 3
        words.append((tier, raw, bare, segs, toks, gloss))

TIERNAME = {0: 'tier0_CSV2890', 1: 'tier1_PEJVO本体', 2: 'tier1b_PEJVO追補', 3: 'tier2_PIV'}

# ---------- 4. 形態素の層(その形態素自身がどの層の語で初出するか) ----------
segtier = {}
for tier, raw, bare, segs, toks, gloss in words:
    for s, k, c in toks:
        if c and (s not in segtier or tier < segtier[s]):
            segtier[s] = tier

# ---------- 5. chance level 用の巡回シフト写像 ----------
allk = sorted({k for _, _, _, _, toks, _ in words for _, k, c in toks if c})
shift = {k: allk[(i + OFFSET) % len(allk)] for i, k in enumerate(allk)}


# ================================================================
# 測定A: 同字種アンカー — CSV2890 を中国語訳(簡体字=割り当てと同字種)で測る
# ================================================================
anchor = collections.defaultdict(lambda: [0, 0, 0, 0, 0])   # comp -> [語数,全接地,連結一致,偶然,測定不能]
anchor_ex = []
for tier, raw, bare, segs, toks, gloss in words:
    if tier != 0:
        continue
    ncont = sum(1 for _, _, c in toks if c)
    if ncont == 0:
        continue
    comp = ncont >= 2
    txt = csv_zh.get(bare, '')
    a = anchor[comp]
    a[0] += 1
    if not measurable(txt):
        a[4] += 1
        continue
    body = cjk_only(txt)
    ks = [k for _, k, c in toks if c]
    if all(any(ch in body for ch in k) for k in ks):
        a[1] += 1
    if ''.join(ks) in body:
        a[2] += 1
    rk = [shift.get(k, k) for k in ks]
    if all(any(ch in body for ch in k) for k in rk):
        a[3] += 1
    if comp:
        anchor_ex.append((raw, ''.join(ks), txt[:30],
                          'Y' if all(any(ch in body for ch in k) for k in ks) else 'N'))

# ================================================================
# 測定B: 文脈保持率 — 同一形態素を「単独語」と「合成語の中」で測り比を取る
#        (字体差は同じ字・同じ語釈言語なので分子分母で相殺される)
# ================================================================
BARE, COMP = 0, 1
occ = collections.defaultdict(lambda: [[0, 0], [0, 0]])     # seg -> [[単独n,単独接地],[合成n,合成接地]]
lenstat = collections.defaultdict(lambda: [0, 0])           # 内容形態素数 -> [n, 接地]
examples = collections.defaultdict(list)
for tier, raw, bare, segs, toks, gloss in words:
    if NEGATORS & set(segs):
        continue                                            # 意味反転語は除外
    txt = clean_gloss(gloss)
    if not measurable(txt):
        continue
    body = cjk_only(txt)
    ncont = sum(1 for _, _, c in toks if c)
    if ncont == 0:
        continue
    slot = COMP if ncont >= 2 else BARE
    for s, k, c in toks:
        if not c:
            continue
        hit = any(ch in body for ch in k)
        occ[s][slot][0] += 1
        occ[s][slot][1] += int(hit)
        if slot == COMP:
            L = min(ncont, 4)
            lenstat[L][0] += 1
            lenstat[L][1] += int(hit)
            if not hit:
                examples[s].append('%s %s→%s' % (raw, k, txt[:22]))

rows, cand = [], []
tierAgg = collections.defaultdict(lambda: [0, 0, 0, 0, 0])   # tier -> [形態素数,単独n,単独接地,合成n,合成接地]
for s, ((bn, bg), (cn, cg)) in occ.items():
    if bn == 0 or cn == 0:
        continue                                            # 両条件で観測できない形態素は対象外
    if bg == 0:
        continue                                            # 単独で一度も接地しない=字体差で測定不能な字
    t = segtier.get(s, 3)
    a = tierAgg[t]
    a[0] += 1; a[1] += bn; a[2] += bg; a[3] += cn; a[4] += cg
    br, cr = bg / float(bn), cg / float(cn)
    rows.append((TIERNAME[t], s, str(bn), '%.3f' % br, str(cn), '%.3f' % cr,
                 '%.2f' % (cr / br) if br else ''))
    if br >= 0.5 and cn >= 5 and cr <= 0.2:
        cand.append((cn - cg, s, TIERNAME[t], '%.2f' % br, '%.2f' % cr,
                     ' | '.join(examples[s][:3])))

with io.open("_lens20_context_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("層\t分節\t単独語数\t単独接地率\t合成語数\t合成接地率\t文脈保持率\n")
    for r in sorted(rows, key=lambda x: (x[0], float(x[6] or 9))):
        f.write('\t'.join(r) + '\n')
cand.sort(key=lambda x: -x[0])
with io.open("_lens20_candidates.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("非接地数\t分節\t層\t単独接地率\t合成接地率\t例(見出し 字→訳語)\n")
    for c in cand:
        f.write('%d\t%s\t%s\t%s\t%s\t%s\n' % c)


def pct(a, b):
    return 100.0 * a / b if b else 0.0


print("=" * 78)
print("第20レンズ「合成語の中での接地」 対象語 %d / 内容形態素 %d" % (len(words), len(segtier)))
print("=" * 78)

print("\n■ 測定A: 同字種アンカー(CSV2890を中国語訳で照合。割り当てと同じ簡体字)")
print("%-10s %7s %9s %9s %9s %9s" % ("", "語数", "測定不能", "全接地", "連結一致", "偶然"))
for comp, lb in ((False, "単純語"), (True, "★合成語")):
    a = anchor[comp]
    m = a[0] - a[4]
    print("%-10s %7d %8d %8.1f%% %8.1f%% %8.1f%%" %
          (lb, a[0], a[4], pct(a[1], m), pct(a[2], m), pct(a[3], m)))

print("\n■ 構造的事実: 合成語(内容形態素2つ以上)の層別の割合")
cnt = collections.Counter()
for tier, raw, bare, segs, toks, gloss in words:
    n = sum(1 for _, _, c in toks if c)
    if n:
        cnt[(tier, n >= 2)] += 1
for t in (0, 1, 2, 3):
    s_, c_ = cnt[(t, False)], cnt[(t, True)]
    if s_ + c_:
        print("  %-18s 単純%6d / 合成%6d  → 合成語率 %5.1f%%" % (TIERNAME[t], s_, c_, pct(c_, s_ + c_)))

print("\n■ ★測定B: 文脈保持率(同一形態素の 合成語での接地率 ÷ 単独語での接地率)")
print("%-18s %8s %10s %10s %10s" % ("形態素の層", "形態素数", "単独接地率", "合成接地率", "文脈保持率"))
tt = [0, 0, 0, 0, 0]
for t in (0, 1, 2, 3):
    a = tierAgg[t]
    if not a[0]:
        continue
    b, c = pct(a[2], a[1]), pct(a[4], a[3])
    print("%-18s %8d %9.1f%% %9.1f%% %9.3f" % (TIERNAME[t], a[0], b, c, (c / b) if b else 0))
    for i in range(5):
        tt[i] += a[i]
b, c = pct(tt[2], tt[1]), pct(tt[4], tt[3])
print("%-18s %8d %9.1f%% %9.1f%% %9.3f" % ("全体", tt[0], b, c, (c / b) if b else 0))

print("\n  [頑健性①] 単独接地率で層化しても各帯で tier0 > tier1 か")
print("  %-12s %14s %14s" % ("単独接地率の帯", "tier0 保持率", "tier1 保持率"))
for lo, hi in ((0.0, 0.4), (0.4, 0.6), (0.6, 0.8), (0.8, 1.01)):
    o = []
    for t in (0, 1):
        sel = [(bn, bg, cn, cg) for s, ((bn, bg), (cn, cg)) in occ.items()
               if bn and cn and bg and segtier.get(s, 3) == t and lo <= bg / float(bn) < hi]
        B = pct(sum(x[1] for x in sel), sum(x[0] for x in sel))
        C = pct(sum(x[3] for x in sel), sum(x[2] for x in sel))
        o.append((len(sel), (C / B) if B else 0))
    print("  %-12s %6d語根%7.3f %6d語根%7.3f" %
          ("%.1f–%.1f" % (lo, hi), o[0][0], o[0][1], o[1][0], o[1][1]))

print("\n  [頑健性②] 観測回数の下限を上げても順序が保たれるか (micro)")
for lim in (1, 3, 5, 10):
    o = []
    for t in (0, 1):
        sel = [(bn, bg, cn, cg) for s, ((bn, bg), (cn, cg)) in occ.items()
               if bn >= 3 and cn >= lim and bg and segtier.get(s, 3) == t]
        B = pct(sum(x[1] for x in sel), sum(x[0] for x in sel))
        C = pct(sum(x[3] for x in sel), sum(x[2] for x in sel))
        o.append((len(sel), (C / B) if B else 0))
    print("  単独>=3 かつ 合成>=%-2d : tier0 n=%4d %.3f / tier1 n=%4d %.3f" %
          (lim, o[0][0], o[0][1], o[1][0], o[1][1]))

print("\n■ ★測定C: 語釈言語に一切依存しない指標 — 合成語は何層の部品で出来ているか")
partcnt = collections.Counter()
allcore = collections.Counter()
for tier, raw, bare, segs, toks, gloss in words:
    cts = [s for s, k, c in toks if c]
    if len(cts) < 2:
        continue
    for s in cts:
        partcnt[segtier.get(s, 3)] += 1
    allcore[(tier, all(segtier.get(s, 3) == 0 for s in cts))] += 1
tp = sum(partcnt.values())
print("  合成語を構成する内容トークン 延べ%d の出自:" % tp)
for t in (0, 1, 2, 3):
    if partcnt[t]:
        print("    %-18s %7d (%5.1f%%)" % (TIERNAME[t], partcnt[t], pct(partcnt[t], tp)))
print("  ★『部品が全て最優先層(CSV2890)』である合成語の割合:")
for t in (0, 1, 2, 3):
    y, n = allcore[(t, True)], allcore[(t, False)]
    if y + n:
        print("    %-18s %6d / %6d = %5.1f%%" % (TIERNAME[t], y, y + n, pct(y, y + n)))

print("\n■ 合成語の長さ別(内容形態素の数)の接地率")
for L in sorted(lenstat):
    n, g = lenstat[L]
    print("  内容形態素%s個: 延べ%6d トークン中 接地 %5.1f%%" % ('4+' if L == 4 else L, n, pct(g, n)))

print("\n■ 単独では接地するのに合成語で落ちる形態素: %d件 (_lens20_candidates.tsv)" % len(cand))
for c in cand[:30]:
    print("   落ち%3d  %-12s %-16s 単独%s→合成%s  %s" % (c[0], c[1], c[2], c[3], c[4], c[5][:64]))

print("\n■ tier0 の合成語 %d件(全件)" % len(anchor_ex))
for e in anchor_ex:
    print("   [%s] %-24s %-8s %s" % (e[3], e[0], e[1], e[2]))
