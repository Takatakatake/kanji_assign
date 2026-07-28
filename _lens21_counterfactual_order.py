# -*- coding: utf-8 -*-
# 第21レンズ「反実仮想＝優先順位を採らなかった場合との差分」 2026-07-28
#
#   第1〜20レンズは全て【実際の状態】だけを測ってきた。被覆・構造・接地・履歴安定性…
#   どれも「単調である」「健全である」という所見は出せたが、
#   **その優先順位が実際にどれだけ得をさせたのか**は一度も測っていない。
#   対照群が無いからである。
#
#   本レンズは初めて【反実仮想】を置く。同じ漢字割り当てのまま、
#   学習者が語根を覚える順序だけを差し替えて、成果曲線を比べる:
#     ①実際の優先順位  CSV2890(Unified_Level昇順) → PEJVO(原本行順) → PIV(原本行順)
#     ②頻度貪欲        F降順(派生語を多く持つ語根から。素朴だが強力な代替案)
#     ③逆順            PIV → PEJVO → CSV2890(優先順位を反転した最悪ケース)
#     ④無作為          決定論的シャッフル(固定巡回シフト)
#
#   成果指標は2つ。**どちらも「語が完全に漢字で読めるか」**で測る:
#     (A) CSV2890語の完読率 … 最重要語彙。ユーザーの優先順位が『何のためか』を直接測る
#     (B) 全辞書語の完読率 … 広がり。①が②に負けうる側で、負けたら正直に報告する
#
#   ★循環に注意: F は辞書内の派生語数なので、②頻度貪欲は(B)に対して貪欲最適に近い。
#     よって(B)で②が勝つのは当然で、意味があるのは**(A)でどちらが勝つか**である。
#     (A)のCSV2890membershipは外部(ユーザー提供CSV)由来でFから独立している。
#
# 出力: _lens21_counterfactual_curves.tsv + stdout要約
import io, os, re, csv as _csv, collections, sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = "漢字注入_学習者版_20260620.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
SIDE = "_identifier_sidecar.tsv"
LEARN = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
PEJVO_END, SUPL_END = 44104, 44440
FUNC = {'suf', 'pref', 'prep', 'correl', 'num', 'func'}
CORE = {'basic', 'suf', 'pref', 'prep', 'correl', 'num', 'func', 'cal'}
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n']
OFFSET = 4993        # 無作為順序の固定巡回シフト(再現性のため乱数を使わない)


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def is_cjk(c):
    return '一' <= c <= '鿿'


# ---------- 1. sidecar: 分節 -> (band, F) ----------
band, F = {}, {}
with io.open(SIDE, encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 7:
            k = to_hsys(p[0])
            band[k] = p[5]
            try:
                F[k] = int(p[6])
            except Exception:
                F[k] = 0

# ---------- 2. CSV2890: 語 -> Unified_Level ----------
csv_lv = {}
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        try:
            lv = float(rec[3])
        except Exception:
            continue
        for t in rec[0].split(','):
            t = to_hsys(t.strip())
            if t:
                csv_lv[t] = min(csv_lv.get(t, 99), lv)

# ---------- 3. 原本の見出し行番号(層判定用) ----------
root_line = {}
with io.open(LEARN, encoding='utf-8-sig') as f:
    for n, line in enumerate(f, 1):
        if ':' not in line:
            continue
        head = line.split(':', 1)[0].strip()
        if not head or head.startswith('#') or ' ' in head:
            continue
        p = head.split('/')
        if len(p) >= 2 and p[-1] in set(ENDINGS):
            p = p[:-1]
        r = ''.join(p)
        if r and r not in root_line:
            root_line[r] = n

# ---------- 4. 注入出力から 語 -> 必要語根集合 ----------
SEP = re.compile(r'[/ ]')
words = []          # (isCSV, [必要語根], 読める見込みか)
seg_minlv = {}      # 分節 -> それを含むCSV語の最小Unified_Level
allsegs = set()
with io.open(INJ, encoding='utf-8-sig') as f:
    for line in f:
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head = line.split(':', 1)[0]
        if '⟦' not in head:
            continue
        raw = head[:head.index('⟦')]
        disp = head[head.index('⟦') + 1:head.rindex('⟧')]
        segs, disps = SEP.split(raw), SEP.split(disp)
        if len(segs) != len(disps):
            continue
        need, latinContent = [], False
        for s, d in zip(segs, disps):
            if not s or s in set(ENDINGS):
                continue
            if any(is_cjk(c) for c in d):
                need.append(s)
                allsegs.add(s)
            else:
                latinContent = True
        if not need:
            continue
        bare = raw.replace('/', '').replace(' ', '')
        lv = csv_lv.get(bare)
        isCSV = lv is not None
        if isCSV:
            for s in need:
                seg_minlv[s] = min(seg_minlv.get(s, 99), lv)
        words.append((isCSV, need, not latinContent))

print("対象語 %d (うちCSV2890語 %d) / 描画語根 %d"
      % (len(words), sum(1 for w in words if w[0]), len(allsegs)))

# ---------- 5. 4つの順序を作る ----------
def tierOf(s):
    if s in seg_minlv:
        return 0
    ln = root_line.get(s)
    if ln is None:
        return 3
    return 1 if ln <= PEJVO_END else (2 if ln <= SUPL_END else 3)


segs = sorted(allsegs)


def key_actual(s):
    """実際の優先順位: 機能形態素 → CSV2890(Unified_Level昇順) → PEJVO → 追補 → PIV"""
    if band.get(s, '') in FUNC:
        return (0, 0.0, 0)
    if s in seg_minlv:
        return (1, seg_minlv[s], root_line.get(s, 10 ** 9))
    return (2 + tierOf(s), 0.0, root_line.get(s, 10 ** 9))


orders = {}
orders['①実際の優先順位'] = sorted(segs, key=key_actual)
orders['②頻度貪欲(F降順)'] = sorted(segs, key=lambda s: (-F.get(s, 0), s))
orders['③逆順(PIV優先)'] = sorted(segs, key=lambda s: (-key_actual(s)[0], key_actual(s)[1], key_actual(s)[2]))
orders['④無作為'] = [segs[(i * 7919 + OFFSET) % len(segs)] for i in range(len(segs))]
seen = set()
orders['④無作為'] = [x for x in orders['④無作為'] if not (x in seen or seen.add(x))] + \
                     [x for x in segs if x not in seen]

# ★⑤⑥ = 層の順序は①と同じにして層内の並べ方だけ差し替える。
#   ①と⑤の差は **Unified_Level(難易度指標)そのものの寄与** を切り出す。
#   ①と⑥の差は 難易度指標 vs 頻度 のどちらが層内順序として良いかを切り出す。
_shuf = {s: (i * 7919 + OFFSET) % len(segs) for i, s in enumerate(segs)}
orders['⑤層順のみ(層内無作為)'] = sorted(segs, key=lambda s: (key_actual(s)[0], _shuf[s]))
orders['⑥層順+層内F降順'] = sorted(segs, key=lambda s: (key_actual(s)[0], -F.get(s, 0), s))

# ---------- 6. 各順序で完読曲線を計算 ----------
NC = sum(1 for w in words if w[0])
NA = len(words)
GRID = [250, 500, 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000, 8000, 10000]
curves = {}
for name, order in orders.items():
    rank = {s: i for i, s in enumerate(order)}
    csvHist = collections.Counter()
    allHist = collections.Counter()
    for isCSV, need, pure in words:
        # ★2026-07-28 訂正(別AI監査の指摘が正しかった): 当初は need(漢字描画された形態素)だけを見て
        #   「全部覚えたら完読」と数えていたが、それでは **ラテンのまま残る内容形態素を持つ語**まで
        #   完読に算入してしまい、曲線が 100% に到達する見かけの上限が出ていた。
        #   ラテン残りのある語はどの順序でも永久に完読できないので、分子から外し分母には残す。
        #   → 真の天井は CSV2890語 2,831/2,832=99.96% / 全辞書語 50,044/52,079=96.1%。
        #   順序間の比較は同じ母集団に対して行うので、**結論(節約語根数・逆転点・面積差)は不変**。
        if not pure:
            continue
        r = max(rank[s] for s in need)      # 最後に覚える語根の順位でその語が読めるようになる
        allHist[r] += 1
        if isCSV:
            csvHist[r] += 1
    cc = ca = 0
    cumC, cumA = {}, {}
    for i in range(len(order)):
        cc += csvHist.get(i, 0)
        ca += allHist.get(i, 0)
        cumC[i] = cc
        cumA[i] = ca
    curves[name] = (cumC, cumA)


def at(cum, k):
    return cum.get(min(k, len(segs)) - 1, 0)


def need_for(cum, total, frac):
    tgt = total * frac
    for i in range(len(segs)):
        if cum.get(i, 0) >= tgt:
            return i + 1
    return None


print("")
print("=" * 92)
print("■ 成果(A): CSV2890語 %d 語の完読率 — 最優先層がどれだけ早く読めるようになるか" % NC)
print("=" * 92)
print("%-18s" % "覚えた語根数" + ''.join("%8d" % k for k in GRID))
for name in orders:
    cumC = curves[name][0]
    print("%-18s" % name + ''.join("%7.1f%%" % (100.0 * at(cumC, k) / NC) for k in GRID))

print("")
print("到達に必要な語根数:")
print("%-18s %10s %10s %10s" % ("", "50%到達", "80%到達", "90%到達"))
for name in orders:
    cumC = curves[name][0]
    v = [need_for(cumC, NC, f) for f in (0.5, 0.8, 0.9)]
    print("%-18s %10s %10s %10s" % (name, *[('%d' % x if x else '—') for x in v]))

print("")
print("=" * 92)
print("■ 成果(B): 全辞書語 %d 語の完読率 — 広がり(★F降順が構造的に有利な指標)" % NA)
print("=" * 92)
print("%-18s" % "覚えた語根数" + ''.join("%8d" % k for k in GRID))
for name in orders:
    cumA = curves[name][1]
    print("%-18s" % name + ''.join("%7.1f%%" % (100.0 * at(cumA, k) / NA) for k in GRID))

with io.open("_lens21_counterfactual_curves.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("覚えた語根数\t" + '\t'.join(n + "_CSV2890完読率" for n in orders) +
            '\t' + '\t'.join(n + "_全語完読率" for n in orders) + '\n')
    for k in range(100, len(segs) + 1, 100):
        f.write(str(k) + '\t' +
                '\t'.join('%.4f' % (100.0 * at(curves[n][0], k) / NC) for n in orders) + '\t' +
                '\t'.join('%.4f' % (100.0 * at(curves[n][1], k) / NA) for n in orders) + '\n')

print("")
print("■ 面積差(全予算にわたる平均優位) — ①実際 が各対照より何ポイント上か")
for name in orders:
    if name.startswith('①'):
        continue
    dC = sum(100.0 * (at(curves['①実際の優先順位'][0], k) - at(curves[name][0], k)) / NC
             for k in range(100, len(segs) + 1, 100)) / len(range(100, len(segs) + 1, 100))
    dA = sum(100.0 * (at(curves['①実際の優先順位'][1], k) - at(curves[name][1], k)) / NA
             for k in range(100, len(segs) + 1, 100)) / len(range(100, len(segs) + 1, 100))
    print("   vs %-18s CSV2890完読率 %+6.1fpt / 全語完読率 %+6.1fpt" % (name, dC, dA))
