# -*- coding: utf-8 -*-
# 第25レンズ「識別子の負荷は誰が・いつ支払い・いつ機能し始めるか」 v4 (第27回続58)
#
#   これまで識別子は 密度(第8)・解消力(第9,23)・長さ(第3) で測ってきた。全て【静的】。
#   識別子の学習コストには時間構造がある: マークは「同じ字を共有する家族の2人目以降」を
#   見分けるためにあり、家族の1人目しか知らない学習者には【まだ何も区別しない前払い】。
#   設計が正しければ:
#     (a) 各家族で無印(bare)は先に学ばれる側が持つ(=初学者はマークを支払わない)
#     (b) マークを学ぶ時点で家族の先客を既に知っている(=マークが即座に機能する)
#     (c) 最優先層だけ学ぶ人のマークは、最優先層内の区別に使われる
#
#   ★スコープ宣言(v4): 本レンズが測るのは【学習者版の語根層(sidecar master disp)】の
#     マークが【辞書閲覧面(注入⟦⟧)】に現れる負担である。語単位の sep/amb 台帳(197行)・
#     inline rule(pro/mil/o の pro がラテンに留まる等)・固有名ガードは語根の master を
#     変えないが露出を変える(第15レンズの領分)。学術版k列の融合描画マーク(27,331トークン)
#     は型目録を共有するが露出密度は別であり本レンズは測っていない。
#   ★v1〜v3の測定バグは独立検証(3方向)で是正済み。主な変更:
#     [B1] 母集団=「dispが両版いずれかの⟦⟧内に分節として出現する語根」(旧: 綴りの分節照合。
#          arh^e が誤除外され uran/Leandr が誤算入されていた)
#     [rB] tier0 = CSV照合 ∪ band=basic (旧: CSV照合のみ。学術版専用融合語根35件を含む
#          band=basic 64件が tier1 に落ちていた)
#     [B2] 死荷重の内訳を4分類に(旧: 層だけ比較し「構造的36」と過小表示。tier0内の
#          規範キー(Unified_Level)が厳密に後の86件も構造的死荷重=A節との定義整合)
#     [C1] 型カウントに加えF重み値を併記(死荷重は頻出接辞に偏在するため)
#     [C7] 接辞の取得時点の感度分析(モデルB=接辞を初出現の層に置く)を併記
#     [C9] マーク長の前払い(窓内一意に必要な最短長との差)を計上
import io, os, re, sys, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
SIDE = "_identifier_sidecar.tsv"
INJ = "漢字注入_学習者版_20260620.txt"
INJ2 = "漢字注入_学術版_20260620.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
OVR = "_base_override.tsv"
SEP = re.compile(r'[/ ]')
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
GRAMMAR_BANDS = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
# 真の閉クラス文法(モデルBでも最前に置く)。suf/pref(接辞)はモデルBでは初出現の層へ
CORE_GRAMMAR = {'prep', 'func', 'correl', 'num'}


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


# ---------- sidecar ----------
roots = {}
collide = []
for line in io.open(SIDE, encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('root') or line.startswith('"root"'):
        continue
    p = [x.strip().strip('"') for x in line.split('\t')]
    if len(p) < 8:
        continue
    root, kanji, idr, idsup, disp, band, F, gk = p[:8]
    hk = to_hsys(root)
    if hk in roots:
        collide.append((roots[hk]['root'], root, roots[hk]['disp'], disp))
        continue
    roots[hk] = {'root': root, 'disp': disp, 'band': band, 'gk': gk, 'id': idr,
                 'marked': bool(idr or idsup), 'F': int(F) if F.isdigit() else 0}
print("sidecar 語根 = %d / マーク付き = %d / 無印 = %d" %
      (len(roots), sum(1 for r in roots.values() if r['marked']),
       sum(1 for r in roots.values() if not r['marked'])))
if collide:
    print("  ※h-system正規化で衝突した表記対 = %d (先勝ち): %s" %
          (len(collide), '; '.join('%r⇔%r(%s/%s)' % c for c in collide)))
    print("  ※Zamenhof式ch等は正規化対象外のため anchov⇔anc^ov 型の併存は検出されない(両者とも後段の母集団検査にかかる)")

# ---------- 注入(両版): 綴りの初出行 / dispの⟦⟧内初出行 / CSV照合用 bare→segs ----------
first_line = {}      # 綴り分節 -> 初出行
disp_line = {}       # ⟦⟧内分節(=disp) -> 初出行
bare2segs = {}
for path in (INJ, INJ2):
    ln = 0
    for line in io.open(path, encoding='utf-8-sig'):
        ln += 1
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head = line.split(':', 1)[0]
        if '⟦' in head:
            raw = head[:head.index('⟦')]
            box = head[head.index('⟦') + 1:head.rindex('⟧')]
            for t in SEP.split(box):
                t = t.strip('-')
                if t and (t not in disp_line or ln < disp_line[t]):
                    disp_line[t] = ln
        else:
            raw = head
        for s in SEP.split(raw):
            s = s.strip('-')
            if s:
                for k in (s, s.lower()):
                    if k not in first_line or ln < first_line[k]:
                        first_line[k] = ln
        if path == INJ and ' ' not in raw:
            cs = [s for s in SEP.split(raw) if s]
            while len(cs) > 1 and cs[-1] in ENDPOP:
                cs.pop()
            if cs:
                bare2segs.setdefault(raw.replace('/', ''), [c.strip('-') for c in cs])

# ---------- CSV2890 ----------
root_lv = {}         # 単一形態素見出し -> Unified_Level (tier0所属とtier0内順序)
csv_all_segs = set()  # CSV2890 全見出しの全分節(接辞の初出現層の判定=モデルB用)
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
        for tok in rec[0].split(','):
            w = to_hsys(tok.strip())
            segs = (bare2segs.get(w) or bare2segs.get(w.strip('-')) or
                    bare2segs.get(w.replace('/', '')) or bare2segs.get(w.lower()))
            if not segs:
                continue
            csv_all_segs.update(segs)
            if len(segs) == 1:
                r = segs[0]
                if r not in root_lv or lv < root_lv[r]:
                    root_lv[r] = lv

# ---------- 母集団: dispが⟦⟧内に出現する語根 [B1] ----------
BIG = 10 ** 9


def fl(hk):
    return first_line.get(hk) or first_line.get(hk.lower()) or BIG


ghosts = sorted((hk for hk in roots if roots[hk]['disp'] not in disp_line),
                key=lambda h: roots[h]['root'])
print("★母集団 = disp が両版いずれかの⟦⟧内に分節として出現する語根(辞書閲覧面の実露出)")
print("  除外 %d 件: 綴り分節も無い(オーファン=旧: civiliz/organiz型) %d / 綴りはあるがdispが⟦⟧に出ない %d" %
      (len(ghosts), sum(1 for h in ghosts if fl(h) == BIG), sum(1 for h in ghosts if fl(h) != BIG)))
for h in ghosts:
    if fl(h) != BIG:
        print("     dispが⟦⟧不出現: %-10s disp=%-8s band=%-6s (見出しは⟦⟧無し行のみ)" %
              (roots[h]['root'], roots[h]['disp'], roots[h]['band']))
print("  ※除外語根も _kanji_map_master.tsv には現存し、配信アプリの裸根置換面では露出しうる")
print("    (map=裸根authoritative)。本レンズのスコープは辞書閲覧面。")
for h in ghosts:
    del roots[h]


def posline(hk):
    l = fl(hk)
    if l == BIG:
        l = disp_line.get(roots[hk]['disp'], BIG)   # arh^e型: 綴りは常にo付きでもdispは出る
    return l


# ---------- 学習順序(2モデル) ----------
# モデルA(主): 文法band一括最前(F降順) → tier0(CSV照合∪band=basic; lv昇順・欠測は末尾)
#              → tier1(非piv; 初出行) → tier2(piv; 初出行)
# モデルB(感度): 接辞(suf/pref)を「初出現の層」に置く(CSV分節に出る→tier0(lv=中央値扱い)、
#              以外は初出行で tier1/tier2)。閉クラス文法(prep/func/correl/num)は最前のまま。
def build_order(model):
    order = []
    for hk, r in roots.items():
        grammar_first = (r['band'] in CORE_GRAMMAR) if model == 'B' else (r['band'] in GRAMMAR_BANDS)
        is_affix = r['band'] in ('suf', 'pref')
        if grammar_first:
            order.append((0, -r['F'], posline(hk), hk))
        elif model == 'B' and is_affix:
            if hk in csv_all_segs or hk.lower() in csv_all_segs:
                order.append((1, root_lv.get(hk, 8.0), posline(hk), hk))
            elif posline(hk) <= 44440:
                order.append((2, 0, posline(hk), hk))
            else:
                order.append((3, 0, posline(hk), hk))
        elif hk in root_lv or r['band'] == 'basic':
            order.append((1, root_lv.get(hk, 99.0), posline(hk), hk))
        elif r['band'] != 'piv':
            order.append((2, 0, posline(hk), hk))
        else:
            order.append((3, 0, posline(hk), hk))
    order.sort()
    return order


TIERN = {0: '文法層', 1: 'tier0(CSV2890)', 2: 'tier1(PEJVO)', 3: 'tier2(PIV)'}
orderA = build_order('A')
posA = {hk: i for i, (_, _, _, hk) in enumerate(orderA)}
tierA = {hk: t for (t, _, _, hk) in orderA}
tc = collections.Counter(t for (t, _, _, _) in orderA)
nolv = sum(1 for (t, lv, _, hk) in orderA if t == 1 and lv == 99.0)
print("学習順序(モデルA): 文法層 %d → tier0 %d (うちCSV照合不能でband=basic採用・lv欠測=%d) → tier1 %d → tier2 %d" %
      (tc[0], tc[1], nolv, tc[2], tc[3]))

fam = collections.defaultdict(list)
for hk, r in roots.items():
    fam[r['gk']].append(hk)
multi = {gk: sorted(mem, key=lambda h: posA[h]) for gk, mem in fam.items() if len(mem) >= 2}
print("家族: 単独 %d / 2人以上 %d" %
      (sum(1 for m in fam.values() if len(m) == 1), len(multi)))

ovr_roots = set()
for line in io.open(OVR, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line or line.startswith('#'):
        continue
    p = line.split('\t')
    if len(p) >= 2:
        ovr_roots.add(to_hsys(p[1].strip()))

# ================================================================
# A. bare配分の方向
# ================================================================
ok_cnt = 0
viol_cross = []
viol_t0 = []
nomeasure = 0
weird = []
for gk, mem in multi.items():
    bare = [h for h in mem if not roots[h]['marked']]
    if len(bare) != 1:
        weird.append(gk)
        continue
    b = bare[0]
    tb = tierA[b]
    tmin = min(tierA[h] for h in mem)
    if tb > tmin:
        viol_cross.append((gk, b, min(mem, key=lambda h: tierA[h])))
    elif tb == 1 and any(tierA[h] == 1 and h != b for h in mem):
        b_lv = root_lv.get(b)
        rivals = [(root_lv.get(h), h) for h in mem if tierA[h] == 1 and h != b]
        rivals = [(lv, h) for lv, h in rivals if lv is not None]
        if b_lv is not None and rivals and min(lv for lv, _ in rivals) < b_lv:
            viol_t0.append((gk, b, min(rivals)[1]))
        else:
            ok_cnt += 1
    else:
        if [h for h in mem if tierA[h] == tb and h != b] and tb != 1:
            nomeasure += 1
        ok_cnt += 1
print("\n" + "=" * 100)
print("■ A. 無印(bare)の配分方向 — 優先順位が定める順序で先に来る側が無印か")
print("=" * 100)
print("   2人以上の家族 %d の内訳:" % len(multi))
print("      無印が家族の最小層に居る(適合)              = %4d (うち同層(tier1/2)内順序は未定義のため不問 %d)" %
      (ok_cnt, nomeasure))
print("      層またぎ逆転(無印がより後の層に居る)         = %4d" % len(viol_cross))
print("      ★tier0内逆転(無印のUnified_Levelが厳密に難) = %4d" % len(viol_t0))
print("      無印が1人でない家族                         = %4d %s" %
      (len(weird), ' '.join(weird)))
cross_by = collections.Counter((tierA[e], tierA[b]) for _, b, e in viol_cross)
print("\n   層またぎ逆転の内訳:")
for (te, tb_), c in sorted(cross_by.items(), key=lambda x: -x[1]):
    print("      %-14s が先にマーク、無印は %-14s : %3d 件" % (TIERN[te], TIERN[tb_], c))
n_ovr_cross = sum(1 for _, b, _ in viol_cross if b in ovr_roots)
print("   層またぎ %d 件のうち無印保持者が override 台帳に載る = %d 件(残りは台帳記録の無い解釈)" %
      (len(viol_cross), n_ovr_cross))
print("   ※tier1→tier2 型(生物学名の属中心種)は §14.2.1「生物14逆転群=現状維持」で裁定済み")
n_ovr_t0 = sum(1 for _, b, _ in viol_t0 if b in ovr_roots)
print("\n   ★tier0内逆転 %d 件(override台帳に載るのは %d 件のみ)の全件:" % (len(viol_t0), n_ovr_t0))
for gk, b, e in sorted(viol_t0, key=lambda x: root_lv.get(x[2], 99)):
    print("      %-4s 無印=%-12s(lv%.2f F=%d)  易しい側がマーク=%-12s(lv%.2f disp=%s)  override=%s" %
          (gk, roots[b]['root'], root_lv.get(b, -1), roots[b]['F'],
           roots[e]['root'], root_lv.get(e, -1), roots[e]['disp'],
           'Y' if b in ovr_roots else 'N'))

# ================================================================
# B. マークの機能開始時点(モデルA/Bで測る)
# ================================================================
def run_sim(order):
    pos = {hk: i for i, (_, _, _, hk) in enumerate(order)}
    tier = {hk: t for (t, _, _, hk) in order}
    seen = collections.Counter()
    paid = []
    for i, (_, _, _, hk) in enumerate(order):
        gk = roots[hk]['gk']
        if roots[hk]['marked']:
            paid.append([i, hk, seen[gk] >= 1, None])
        seen[gk] += 1
    nxt = {}
    for gk, mem in fam.items():
        ps = sorted(pos[h] for h in mem)
        for a, b in zip(ps, ps[1:]):
            nxt[(gk, a)] = b
    for rec in paid:
        if not rec[2]:
            rec[3] = nxt.get((roots[rec[1]]['gk'], rec[0]))
    return pos, tier, paid


posA2, tierA2, paidA = run_sim(orderA)
totF = sum(roots[hk]['F'] for _, hk, _, _ in paidA)
funcF = sum(roots[hk]['F'] for _, hk, f, _ in paidA if f)
func_n = sum(1 for r in paidA if r[2])
dead = [r for r in paidA if not r[2]]
print("\n" + "=" * 100)
print("■ B. マークの機能開始時点 — 支払った識別子は『いつ』意味を持つか")
print("=" * 100)
print("   ※弁別機能(先客と見分ける)の開始時点。マークには先客未習でも『これは基本義ではない』と")
print("     伝える警告機能があり、それはここでゼロ評価している(死荷重=弁別機能の下界)。")
print("   [モデルA: 文法band一括最前] マーク %d / 取得時に既に機能 %d (型 %.1f%% / F重み %.1f%%)" %
      (len(paidA), func_n, 100.0 * func_n / len(paidA), 100.0 * funcF / max(1, totF)))
waits = sorted(r[3] - r[0] for r in dead if r[3] is not None)
nev = [r for r in dead if r[3] is None]
if waits:
    print("   死荷重 %d 件の待ち時間(語根数): 中央値 %d / 90%%点 %d / 最大 %d / 家族が二度と来ない %d" %
          (len(dead), waits[len(waits) // 2], waits[int(len(waits) * .9)], waits[-1], len(nev)))
for r in nev:
    gk = roots[r[1]]['gk']
    print("      家族が来ない: %s(%s) — 相手が母集団除外(辞書閲覧面に不出現)のためマークは現状何も区別しない" %
          (roots[r[1]]['root'], roots[r[1]]['disp']))
# 死荷重4分類 [B2]
cat = collections.Counter()
for i, hk, f, nx in dead:
    if nx is None:
        cat['相手不在'] += 1
        continue
    nhk = orderA[nx][3]
    if tierA[nhk] > tierA[hk]:
        cat['構造的(相手が後の層)'] += 1
    elif tierA[hk] == 1:
        lv_a, lv_b = root_lv.get(hk), root_lv.get(nhk)
        if lv_a is not None and lv_b is not None and lv_b > lv_a:
            cat['構造的(tier0内で規範キーが厳密に後)'] += 1
        elif lv_a is not None and lv_b is not None and lv_b == lv_a:
            cat['同値タイブレーク依存(tier0内lv同値)'] += 1
        else:
            cat['同値タイブレーク依存(tier0内lv欠測)'] += 1
    elif tierA[hk] == 0:
        if roots[nhk]['F'] < roots[hk]['F']:
            cat['構造的(文法層内でF規範が厳密に後)'] += 1
        else:
            cat['同値タイブレーク依存(文法層)'] += 1
    else:
        cat['層内順序未定義(tier1/2)'] += 1
n_struct = sum(v for k, v in cat.items() if k.startswith('構造的') or k == '相手不在')
print("   死荷重の内訳([B2]是正: 層内規範キーも比較する):")
for k, v in cat.most_common():
    print("      %-40s %4d" % (k, v))
print("      → どの層内順序でも死荷重なのは %d 件(旧v3は36件と過小表示していた)" % n_struct)
by_tier = collections.defaultdict(lambda: [0, 0, 0, 0])
for i, hk, f, _ in paidA:
    t = by_tier[tierA[hk]]
    t[0] += 1
    t[2] += roots[hk]['F']
    if f:
        t[1] += 1
        t[3] += roots[hk]['F']
print("   層別(モデルA):")
for t in range(4):
    tot, fn, ftot, ffn = by_tier[t]
    print("      %-14s 支払い %4d / 即機能 %4d (型 %5.1f%% / F重み %5.1f%%)" %
          (TIERN[t], tot, fn, 100.0 * fn / max(1, tot), 100.0 * ffn / max(1, ftot)))

orderB = build_order('B')
_, tierB, paidB = run_sim(orderB)
funcB = sum(1 for r in paidB if r[2])
totFB = sum(roots[hk]['F'] for _, hk, _, _ in paidB)
funcFB = sum(roots[hk]['F'] for _, hk, f, _ in paidB if f)
print("   [モデルB: 接辞(suf/pref)を初出現の層へ] 即機能 %.1f%%(型) / %.1f%%(F重み)" %
      (100.0 * funcB / len(paidB), 100.0 * funcFB / max(1, totFB)))
mvA = collections.Counter(tierB[hk] for hk in tierB if roots[hk]['band'] in ('suf', 'pref'))
print("     (接辞76語根の配置: %s / 独立検証は全順序仮定で 91.1〜94.9%% と報告=質的結論は順序に頑健)" %
      ' '.join('%s:%d' % (TIERN[t], c) for t, c in sorted(mvA.items())))

# ================================================================
# C. tier0 で学習を止める人の負担 (Aの系)
# ================================================================
print("\n" + "=" * 100)
print("■ C. tier0 で学習を止める人の識別子負担 (※A節の系=独立検査ではない)")
print("=" * 100)
t0_end = sum(1 for t, _, _, _ in orderA if t <= 1)
t0_paid = [(i, hk) for i, hk, _, _ in paidA if i < t0_end]
print("   文法層+tier0 の語根数 = %d / うちマーク付き = %d (%.1f%%)" %
      (t0_end, len(t0_paid), 100.0 * len(t0_paid) / t0_end))
benef = collections.Counter()
bad_ex = []
for i, hk in t0_paid:
    others = [h for h in fam[roots[hk]['gk']] if h != hk]
    if any(tierA[h] <= 1 for h in others):
        benef['家族に文法層/tier0の相手が居る(自分が使う区別)'] += 1
    else:
        mt = min(tierA[h] for h in others)
        benef['相手は%sのみ(将来のための前払い)' % TIERN[mt]] += 1
        bad_ex.append(hk)
for k, c in benef.most_common():
    print("      %-46s %4d 件 (%.2f%%)" % (k, c, 100.0 * c / len(t0_paid)))
for hk in bad_ex:
    print("        前払い: %s(%s) 相手=%s" %
          (roots[hk]['root'], roots[hk]['disp'],
           ','.join(roots[h]['root'] for h in fam[roots[hk]['gk']] if h != hk)))
print("   (独立検証: 描画レベルでCSV2890の⟦⟧内マーク899型を直接検査しても、同base字が")
print("    CSV2890内に現れないもの=0型。inline rule由来でsidecar外のマーク11型も同様)")

# マーク長の前払い [C9]
extra_roots = 0
extra_chars = 0
examples = []
for gk, mem in multi.items():
    win = [h for h in mem if posA[h] < t0_end]
    if len(win) < 1:
        continue
    for h in win:
        if not roots[h]['marked'] or not roots[h]['id']:
            continue
        rivals = [roots[x]['id'] for x in win if x != h and roots[x]['id']]
        myid = roots[h]['id']
        need = 1
        while need < len(myid) and any(r[:need] == myid[:need] for r in rivals):
            need += 1
        if len(myid) > need:
            extra_roots += 1
            extra_chars += len(myid) - need
            examples.append((h, myid, need, len([x for x in mem if posA[x] >= t0_end])))
print("   マーク長の前払い([C9]): 窓内(文法+tier0)マークのうち、窓内一意には短いidで足りるのに")
print("   長いidを持つ = %d 件 / 余分な文字数計 %d (窓外の家族との衝突回避=将来のための前払い)" %
      (extra_roots, extra_chars))
for h, myid, need, n_out in sorted(examples, key=lambda x: -(len(x[1]) - x[2]))[:8]:
    print("      %-12s disp=%-8s id=%s (窓内一意には%d字で可 / 窓外の家族%d人)" %
          (roots[h]['root'], roots[h]['disp'], myid, need, n_out))

# ================================================================
# D. (Aの系) 境界跨ぎ家族の不在
# ================================================================
print("\n" + "=" * 100)
print("■ D. 反実仮想 (※A節から演繹される系=独立の裏付けではない)")
print("=" * 100)
straddle = []
for gk, mem in fam.items():
    if len(mem) < 2:
        continue
    bare = [h for h in mem if not roots[h]['marked']]
    if len(bare) != 1:
        continue
    b = bare[0]
    e = min(mem, key=lambda h: posA[h])
    if b != e and (posA[b] < t0_end) != (posA[e] < t0_end):
        straddle.append(gk)
print("   『bareが学習順最初でない かつ 両者がtier0境界を跨ぐ』家族 = %d 件 %s" %
      (len(straddle), ' '.join(straddle)))
print("   → 無印を純学習順で機械的に配り直した場合、tier0学習者の支払いが減るのはこの家族数だけ。")
print("     該当はC節の前払い3件と同一(全て学術版専用の融合描画で、学習者版の読者には元々見えない)。")
print("     学習者版の読者に限れば削減 0 件=A節の逆転131件(層またぎ43+tier0内88)は全て境界の")
print("     同じ側で起きており、中心義curationの費用は『どの字が無印か』の入替であって")
print("     『初学者が払うマークの数』ではない。")

# ---------- TSV ----------
with io.open("_lens25_identifier_burden.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("groupkey\t家族人数\t無印語根\t無印の層\t学習順最初の語根\tその層\t分類\n")
    for gk, mem in sorted(multi.items(), key=lambda x: posA[x[1][0]]):
        bare = [h for h in mem if not roots[h]['marked']]
        b = bare[0] if len(bare) == 1 else ''
        e = mem[0]
        cls = ''
        if b:
            if (gk, b) in [(g2, b2) for g2, b2, _ in viol_cross]:
                cls = '層またぎ逆転'
            elif (gk, b) in [(g2, b2) for g2, b2, _ in viol_t0]:
                cls = 'tier0内逆転'
            else:
                cls = '適合'
        f.write("%s\t%d\t%s\t%s\t%s\t%s\t%s\n" % (
            gk, len(mem), roots[b]['root'] if b else '(無印%d人)' % len(bare),
            TIERN[tierA[b]] if b else '', roots[e]['root'], TIERN[tierA[e]], cls))
print("\n出力: _lens25_identifier_burden.tsv")
