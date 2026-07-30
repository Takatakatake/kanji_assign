# -*- coding: utf-8 -*-
# 第24レンズ「優先順位の入力そのものを検証する」 2026-07-30
#   v2 (2026-07-30): 独立検証(8エージェント)が指摘した測定バグを全て修正した版。
#
#   第1〜23レンズは全て **割り当ての出力** を測ってきた。優先順位そのものは
#     ① CSV2890 というメンバーシップ ② Unified_Level という層内の難易度数値
#     ③ PEJVO 44104行 / PIV という層境界
#   の3入力で定義されるが、①③は第6/第22レンズが検証済み、**②だけ未検証**だった。
#
#   ★v1 から直した測定バグ(すべて独立検証が実証付きで指摘):
#     B1 CSVの見出しに `/` を含む37件(ter/pomo 等)が bare2segs に当たらず、
#        スラッシュ付き文字列そのものを1形態素とみなして「単一形態素」母集団に混入。
#        コーパスには絶対に現れないので頻度が構造上0になっていた。
#     B2 コーパス側だけ .lower() していたため、大文字始まりの形態素(Di/Krist/Eŭrop…)は
#        必ず頻度0。16件が全滅していた。
#     B3 被覆の分母 seen_tot が行単位の和で、分子は形態素集合の和。重複90形態素を
#        二重計上して分母が +7.5% 水増し(過去バグ型(3)の三度目の再発)。
#     B4 純粋な文法語尾の見出し(-o -a -as …)は、コーパス側では語尾が剥がれているので
#        連結母音しか数えられず、指標名と実測対象がずれていた → 母集団から除外。
#     B5 語幹キーの先勝ちで `ili`→`il`・`kia`→`ki`・`amen`→`am` 等の誤帰属(B で延べ3,206)。
#        語幹辞書を分離し、さらに「形態素連結がトークン語頭に一致」ガードを入れた。
#     B6 コーパスBの斜体抽出 `{6,}` が5文字以下の斜体(=基本語)を8,342断片捨て、
#        位相ずれで地の文1,175件を混入。行内で `_` を順に対にする方式へ変更。
#     B7 分詞形(-ant/-int/-ont/-at/-it/-ot)に到達できず動詞語根が系統的に過小評価
#        (B で4,647語)。語尾を剥がした後に分詞接尾も剥がす。
#
#   ★v1 から変えた「読み方」(独立検証の反証を容れた):
#     R1 A+B合算はコーパスBが延べの98%を占めるため **B単独と同義**。Bは辞書編纂者が
#        書いた用例句であって実文ではない。**主結果はコーパスA(ユーザー自身の原文)** とし、
#        A+Bは参考に降格する。
#     R2 「単調」は誤り(十分位で1段・実値33段では12段が逆行)。「概ね右肩下がり」と書く。
#     R3 F との比較は、F が閉じたクラス(la/mi/en…)に値を持たないため不公平だった。
#        **F が定義される内容語根に限った比較** を併記する。
#     R4 Unified_Level の小数部は出典族のIDらしいので、族内での相関も出す。
import io, os, re, sys, csv as _csv, collections, math

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = "漢字注入_学習者版_20260620.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
PWORK = "_p_work.csv"
SIDE = "_identifier_sidecar.tsv"
DIARY = os.path.join("..", "漢字化エスペラント日記")
PIVF = "10_PIV2020参照データ/PIV2020_structured.txt"
SEP = re.compile(r'[/ ]')
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us',
           'o', 'a', 'e', 'i', 'u', 'j', 'n']
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
PART = ['ant', 'int', 'ont', 'at', 'it', 'ot']
PURE_ENDING = {'o', 'a', 'e', 'i', 'u', 'j', 'n', 'as', 'is', 'os', 'us'}   # B4


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


# ---------- 1. 注入 -> 見出し語(裸形) と 語幹 の2辞書に分ける(B5) ----------
bare2segs, stem2segs = {}, {}
for line in io.open(INJ, encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        continue
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')] if '⟦' in head else head
    if ' ' in raw:
        continue
    cs = [s for s in SEP.split(raw) if s]
    while len(cs) > 1 and cs[-1] in ENDPOP:
        cs.pop()
    if not cs:
        continue
    segs = [c.strip('-') for c in cs]
    bare = raw.replace('/', '')
    for k in (bare, bare.lower()):                     # B2: 小文字キーも併設
        bare2segs.setdefault(k, segs)
    st = bare
    for e in ENDINGS:
        if st.endswith(e) and len(st) > len(e):
            st = st[:-len(e)]
            break
    if st:
        for k in (st, st.lower()):
            stem2segs.setdefault(k, segs)


def lookup(w):
    """裸形を最優先し、外れたときだけ語幹辞書を見る(B5)"""
    for k in (w, w.lower()):
        if k in bare2segs:
            return bare2segs[k]
    for k in (w, w.lower()):
        if k in stem2segs:
            return stem2segs[k]
    return None


# ---------- 2. CSV2890 ----------
csv_rows = []
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if len(rec) < 4 or not rec[0].strip():
            continue
        try:
            lv = float(rec[3])
        except ValueError:
            continue
        mark = 'O' if '{Ｏ}' in (rec[1] if len(rec) > 1 else '') else 'B'
        for tok in rec[0].split(','):
            w = to_hsys(tok.strip())
            if not w or ' ' in w or '(' in w:           # B1: 句見出しは除外
                continue
            key = w.strip('-')
            segs = (lookup(w) or lookup(w.replace('/', '')) or lookup(key)
                    or lookup(key.rstrip('o').rstrip('a')) or [key])   # B1/B2
            csv_rows.append((w, lv, [s.strip('-') for s in segs], mark))

print("=" * 100)
print("第24レンズ v2「優先順位の入力そのものを検証する」— Unified_Level は実文頻度を予測するか")
print("=" * 100)
print("  CSV2890 の行 = %s" % format(len(csv_rows), ','))


# ---------- 3. コーパス ----------
def load_diary():
    if not os.path.isdir(DIARY):
        return ''
    return '\n'.join(io.open(os.path.join(DIARY, f), encoding='utf-8', errors='replace').read()
                     for f in os.listdir(DIARY) if f.endswith('.md') and '原文エスペラント' in f)


def load_piv():
    """B6: 行内で _ を順に対にする(短い斜体も拾い、位相ずれを起こさない)"""
    if not os.path.exists(PIVF):
        return ''
    out = []
    for line in io.open(PIVF, encoding='utf-8', errors='replace'):
        parts = line.split('_')
        for i in range(1, len(parts), 2):
            if parts[i].strip():
                out.append(parts[i])
    return '\n'.join(out)


WORD = re.compile(r"[A-Za-zĉĝĥĵŝŭĈĜĤĴŜŬ]{1,}")


def seg_of(w):
    """トークン -> 内容形態素列。分詞も剥がす(B7)。誤帰属ガード付き(B5)"""
    s = lookup(w)
    if s is None:
        st = w
        for e in ENDINGS:
            if st.endswith(e) and len(st) > len(e):
                st = st[:-len(e)]
                break
        s = lookup(st)
        if s is None:
            for p in PART:
                if st.endswith(p) and len(st) > len(p):
                    s = lookup(st[:-len(p)])
                    if s:
                        break
    if s is None:
        return None
    if not w.lower().startswith(''.join(s).lower()[:max(1, len(''.join(s)) - 1)]):
        return None                                     # B5: 語頭不一致は誤帰属として捨てる
    return s


def morph_counts(text):
    c = collections.Counter()
    ntok = hit = 0
    for w in WORD.findall(text):
        ntok += 1
        w = to_hsys(w.lower())
        s = seg_of(w)
        if s is None:
            continue
        hit += 1
        for x in s:
            c[x] += 1
    return c, ntok, hit


cA, nA, hA = morph_counts(load_diary())
cB, nB, hB = morph_counts(load_piv())
cAll = collections.Counter()
cAll.update(cA)
cAll.update(cB)
print("  コーパスA(ユーザー原文・唯一の実文) 総語 %s / 照合 %s (%.1f%%) / 延べ形態素 %s"
      % (format(nA, ','), format(hA, ','), 100.0 * hA / max(1, nA), format(sum(cA.values()), ',')))
print("  コーパスB(PIV用例句・辞書の自己記述) 総語 %s / 照合 %s (%.1f%%) / 延べ形態素 %s"
      % (format(nB, ','), format(hB, ','), 100.0 * hB / max(1, nB), format(sum(cB.values()), ',')))
print("  ★A+B合算は延べの %.1f%% を B が占める＝**B単独と同義**。主結果はAを見る(R1)。"
      % (100.0 * sum(cB.values()) / max(1, sum(cA.values()) + sum(cB.values()))))

# ---------- 4. F と band ----------
Fmap, bandmap = {}, {}
with io.open(PWORK, encoding='utf-8-sig') as f:
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split(',')]
        if len(p) >= 5:
            r = to_hsys(p[0])
            bandmap[r] = p[2]
            try:
                Fmap[r] = float(p[4])
            except ValueError:
                pass


# ---------- 5. スピアマン ----------
def ranks(xs):
    order = sorted(range(len(xs)), key=lambda i: xs[i])
    r = [0.0] * len(xs)
    i = 0
    while i < len(order):
        j = i
        while j + 1 < len(order) and xs[order[j + 1]] == xs[order[i]]:
            j += 1
        avg = (i + j) / 2.0 + 1
        for k in range(i, j + 1):
            r[order[k]] = avg
        i = j + 1
    return r


def spearman(xs, ys):
    if len(xs) < 3:
        return float('nan')
    rx, ry = ranks(xs), ranks(ys)
    n = len(rx)
    mx, my = sum(rx) / n, sum(ry) / n
    num = sum((a - mx) * (b - my) for a, b in zip(rx, ry))
    dx = math.sqrt(sum((a - mx) ** 2 for a in rx))
    dy = math.sqrt(sum((b - my) ** 2 for b in ry))
    return num / (dx * dy) if dx and dy else float('nan')


# ---------- 6. 母集団 ----------
single = [(w, lv, segs[0], mk) for w, lv, segs, mk in csv_rows
          if len(segs) == 1 and segs[0] not in PURE_ENDING]        # B4
excl_pure = [r for r in csv_rows if len(r[2]) == 1 and r[2][0] in PURE_ENDING]
multi = [r for r in csv_rows if len(r[2]) > 1]
print("\n  母集団: 単一形態素 %s 件 / 複数形態素 %s 件(除外) / 純文法語尾 %s 件(除外=B4)"
      % (format(len(single), ','), format(len(multi), ','), format(len(excl_pure), ',')))

print("\n" + "=" * 100)
print("■ 結果① Unified_Level は実文頻度を予測するか(スピアマン。負が『易しい語ほどよく出る』)")
rows = []
for cname, cnt in (('A_ユーザー原文(実文)', cA), ('B_PIV用例句', cB), ('A+B(=実質B)', cAll)):
    xs = [lv for _, lv, _, _ in single]
    ys = [cnt.get(s, 0) for _, _, s, _ in single]
    rho = spearman(xs, ys)
    nz = sum(1 for y in ys if y > 0)
    print("   Unified_Level      vs %-18s ρ = %+.3f  (出現>0 %s/%s = %.1f%%)"
          % (cname, rho, format(nz, ','), format(len(ys), ','), 100.0 * nz / len(ys)))
    rows.append(('Unified_Level', cname, rho, nz, len(ys)))
    xs2 = [-Fmap[s] for _, _, s, _ in single if s in Fmap]
    ys2 = [cnt.get(s, 0) for _, _, s, _ in single if s in Fmap]
    rho2 = spearman(xs2, ys2)
    print("   F(符号反転・F有りのみ) vs %-18s ρ = %+.3f  (%s件)" % (cname, rho2, format(len(xs2), ',')))
    rows.append(('F_negated', cname, rho2, len(xs2), len(xs2)))

# 難易度帯を絞ったときの崩壊(R1の反証を明示的に載せる)
print("\n■ 結果①-b 相関は易しい側でしか効かない(独立検証の指摘を検算)")
for lo in (0.0, 4.0, 6.83, 7.90):
    sub = [(lv, s) for _, lv, s, _ in single if lv >= lo]
    if len(sub) < 30:
        continue
    ra = spearman([lv for lv, _ in sub], [cA.get(s, 0) for _, s in sub])
    rall = spearman([lv for lv, _ in sub], [cAll.get(s, 0) for _, s in sub])
    print("   Unified_Level >= %-5.2f (%s件)  ρ(A)=%+.3f  ρ(A+B)=%+.3f" % (lo, format(len(sub), ','), ra, rall))

# 出典族(小数部)ごと
print("\n■ 結果①-c 小数部は『出典族のID』らしい — 族内では相関が消える(独立検証の指摘を検算)")
fam = collections.defaultdict(list)
for _, lv, s, _ in single:
    fam[round(lv % 1, 2)].append((lv, s))
print("   %-6s %8s %10s %10s %s" % ("小数部", "件数", "族内ρ(A)", "族内ρ(A+B)", "含む値"))
for k in sorted(fam):
    v = fam[k]
    vals = sorted(set(x[0] for x in v))
    if len(vals) < 2:
        print("   %-6.2f %8d %10s %10s %s" % (k, len(v), '測定不能', '測定不能',
                                              ','.join('%.2f' % x for x in vals[:6])))
        continue
    ra = spearman([x[0] for x in v], [cA.get(x[1], 0) for x in v])
    rall = spearman([x[0] for x in v], [cAll.get(x[1], 0) for x in v])
    print("   %-6.2f %8d %+10.3f %+10.3f %s" % (k, len(v), ra, rall,
                                                ','.join('%.2f' % x for x in vals[:6])))

# ---------- 7. 被覆曲線(分母を重複排除 B3) ----------
print("\n" + "=" * 100)
print("■ 結果② 層内順序と実文被覆(分母は形態素集合＝重複排除済み B3)")
KS = [100, 300, 500, 1000, 2000, 2841]


def curve(seq, cnt, universe):
    tot = sum(cnt.get(s, 0) for s in universe)
    acc, cum, out, idx = set(), 0, [], 0
    for k in KS:
        while idx < min(k, len(seq)):
            s = seq[idx][2]
            if s not in acc:
                acc.add(s)
                cum += cnt.get(s, 0)
            idx += 1
        out.append(100.0 * cum / max(1, tot))
    return out


def det_shuffle(seq, seed=20260730):
    s = list(seq)
    st = seed
    for i in range(len(s) - 1, 0, -1):
        st = (st * 1103515245 + 12345) % (2 ** 31)
        j = st % (i + 1)
        s[i], s[j] = s[j], s[i]
    return s


for label, pop in (('全単一形態素', single),
                   ('★Fが定義される内容語根のみ(R3=公平な比較)',
                    [t for t in single if t[2] in Fmap
                     and bandmap.get(t[2], '') not in ('correl', 'prep', 'func', 'num', 'suf', 'pref')])):
    uni = set(t[2] for t in pop)
    print("\n   [%s] %s形態素" % (label, format(len(uni), ',')))
    orders = [('①Unified_Level昇順', sorted(pop, key=lambda t: t[1])),
              ('②層内を無作為に破壊', det_shuffle(pop)),
              ('③F降順', sorted(pop, key=lambda t: -Fmap.get(t[2], 0))),
              ('④実文頻度降順(理論最良)', sorted(pop, key=lambda t: -cA.get(t[2], 0))),
              ('⑤Unified_Level降順', sorted(pop, key=lambda t: -t[1]))]
    print("   %-24s %s" % ("順序(コーパスA=実文で評価)", ' '.join('%7d' % k for k in KS)))
    for nm, sq in orders:
        print("   %-24s %s" % (nm, ' '.join('%6.1f%%' % v for v in curve(sq, cA, uni))))

with io.open("_lens24_input_validation.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("区分\t指標\tコーパス\tρ\t件数\t母数\n")
    for r in rows:
        f.write("相関\t%s\t%s\t%.3f\t%d\t%d\n" % r)
print("\n出力: _lens24_input_validation.tsv")
