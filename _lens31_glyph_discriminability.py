# -*- coding: utf-8 -*-
# 第31レンズ「字形の弁別性と書字負荷」 (第27回続70)
#
#   ★空白の所在: 第1〜30の全レンズは漢字を【内部構造ゼロの原子記号】として扱ってきた。
#     第23レンズ(近傍衝突)は文字列レベルの取り違えを測ったが、報告書 line 86 で
#       「1字面は転置衝突も高重複近傍も構造的に起こり得ない」
#     と述べ、最優先層の安全性(91.0%が1字面)をそこに帰着させている。
#     さらに記録された落とし穴に「1字面どうしの距離1は『全く別の字』であって近傍ではない」とある。
#     = 1字どうしの取り違えは【定義によって】測定対象外にされていた。
#     したがって最優先層の安全論拠は、字そのものの形が紛らわしくないという
#     **一度も検定されていない仮定** の上に乗っている。己/已・未/末・土/士 は
#     文字列距離では「全く別の字」だが、読者は現に取り違える。
#
#   測る量:
#     [A] 書字負荷 = 画数。方針 R3「少画数優先」・§4.3「④画数」が優先順位どおり実行されているか。
#     [B] 割り当て字集合そのものの形の混み具合(基準率で正規化)。
#     [C] ★配信面の形近衝突 = ある面の1字を『形の双子』に読み違えると別語根の面になる箇所。
#         第23の完全衝突・転置・1字違いの、形空間版。
#     [D] 実配信テキストでの実害。
#     [E] 識別子マーク自体の弁別性(仕様書 L54 が既知例 anĉov ᶜ̂ / anchov ᶜ を「現状許容」としている)。
#
#   ★類似度の較正: 教科書的な形近字ペアを種集合として閾値を決め、無作為ペアでの
#     偽陽性率を実測して併記する。閾値は恣意ではなく「種集合の再現率と偽陽性率の組」で示す。
import io, os, re, sys, csv as _csv, collections, random, unicodedata
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))

SIDE = "_identifier_sidecar.tsv"
STROKE = "通用规范汉字表_一级3500字_画数.tsv"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
INJ = {'学習者版': "漢字注入_学習者版_20260620.txt", '学術版': "漢字注入_学術版_20260620.txt"}
CORPUS = [os.path.join("..", "漢字化エスペラント日記", f) for f in (
    "エスペラント随想_日記_漢字化エスペラント集成_20260705.md",
    "漢字化エスペラント日記_第2集_漢字化エスペラント集成_20260721.md")]
FONTS = [(r"C:\Windows\Fonts\simsun.ttc", 0, '宋体'), (r"C:\Windows\Fonts\msyh.ttc", 0, '黑体系')]
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
SUPCAT = ('Lm', 'Mn', 'Sk')
SZ, PAD = 64, 8
CAN = SZ + 2 * PAD
# 較正で決めた作用点(下で再現率と偽陽性率を実測して表示する)
T_IOU, T_BLUR = 0.45, 0.94
T_IOU2, T_BLUR2 = 0.35, 0.93


def is_mark(c):
    return unicodedata.category(c) in SUPCAT


def strip_marks(s):
    return ''.join(c for c in s if not is_mark(c))


def is_cjk(c):
    return '一' <= c <= '鿿'


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


# ================================================================
# 0. データ読み込み
# ================================================================
stroke = {}
pool = []
for i, l in enumerate(io.open(STROKE, encoding='utf-8-sig')):
    p = l.rstrip('\n').split('\t')
    if i == 0 or len(p) < 4:
        continue
    stroke[p[1]] = int(p[3])
    pool.append(p[1])

roots = {}
rows = []
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    d = {'root': p[0], 'kanji': p[1], 'id': p[2], 'sup': p[3], 'disp': p[4], 'band': p[5],
         'F': int(p[6]) if p[6].isdigit() else 0, 'gk': p[7]}
    rows.append(d)
    for key in {p[0], to_hsys(p[0]), to_hsys(p[0]).lower()}:
        roots.setdefault(key, d)

# CSV2890 語根の同定(第27レンズと同一手順)
bare2segs = {}
for path in INJ.values():
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')] if '⟦' in head else head
        if ' ' in raw:
            continue
        cs = [s for s in raw.split('/') if s]
        while len(cs) > 1 and cs[-1] in ENDPOP:
            cs.pop()
        if cs:
            bare2segs.setdefault(raw.replace('/', '').replace('-', '').lower(), [c.strip('-') for c in cs])
csv_roots = set()
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        for tok in rec[0].split(','):
            w0 = to_hsys(tok.strip())
            segs = None
            for k in (w0.replace('/', '').replace('-', '').lower(), w0.lower(), w0):
                segs = bare2segs.get(k)
                if segs:
                    break
            if segs and len(segs) == 1:
                csv_roots.add(segs[0])
                csv_roots.add(to_hsys(segs[0]).lower())


def tier_of(d):
    if d['band'] in GRAMMAR:
        return '文法層'
    r = d['root']
    if r in csv_roots or to_hsys(r).lower() in csv_roots:
        return 'CSV2890'
    if d['band'] == 'piv':
        return 'PIV'
    return 'PEJVO'


for d in rows:
    d['tier'] = tier_of(d)
    d['surf'] = strip_marks(d['disp'])
TIERS = ['文法層', 'CSV2890', 'PEJVO', 'PIV']

used = collections.Counter()
for d in rows:
    for c in d['disp']:
        if is_cjk(c):
            used[c] += 1
UC = sorted(used)
print("語根 %d / 使用漢字 %d 種(一级3500 のうち %.1f%%) / 一级外 %d"
      % (len(rows), len(UC), 100.0 * len(UC) / 3500, sum(1 for c in UC if c not in stroke)))

# ================================================================
# 1. 字形類似行列の構築 + 較正
# ================================================================
print("\n" + "=" * 100)
print("■ 1. 類似度の較正 — 閾値は『教科書的形近字の再現率』と『無作為ペアの偽陽性率』で示す")
print("=" * 100)


def build(fontpath, index):
    font = ImageFont.truetype(fontpath, SZ, index=index)
    bi, bl = [], []
    for ch in pool:
        img = Image.new('L', (CAN, CAN), 0)
        ImageDraw.Draw(img).text((CAN // 2, CAN // 2), ch, font=font, fill=255, anchor='mm')
        a = np.asarray(img, dtype=np.float32) / 255.0
        bi.append((a > 0.5).astype(np.float32).ravel())
        b = np.asarray(img.filter(ImageFilter.GaussianBlur(3.0)), dtype=np.float32).ravel()
        bl.append(b / (np.linalg.norm(b) + 1e-9))
    A = np.stack(bi)
    B = np.stack(bl)
    inter = A @ A.T
    area = np.diag(inter).copy()
    union = area[:, None] + area[None, :] - inter
    IOU = inter / np.maximum(union, 1e-9)
    BLR = B @ B.T
    return IOU, BLR


PIDX = {c: i for i, c in enumerate(pool)}
IOU, BLR = build(*FONTS[0][:2])
print("   フォント %s で %d×%d の類似度行列を構築" % (FONTS[0][2], len(pool), len(pool)))

SEED = ["己已", "己巳", "已巳", "未末", "土士", "天夭", "人入", "千干", "折析", "待侍",
        "竟竞", "撤撒", "微徽", "睛晴", "侯候", "廷延", "遣遗", "徒徙", "拨拔", "辩辨",
        "戊戌", "汞录", "曰日", "买卖", "赂路", "洒酒", "凑揍", "篮蓝", "崇祟", "鸟乌",
        "斤斥", "壬王", "犬大", "太大", "住往"]
seed = [(a, b) for a, b in SEED if a in PIDX and b in PIDX]


def hit(a, b, ti=T_IOU, tb=T_BLUR):
    i, j = PIDX[a], PIDX[b]
    return IOU[i, j] >= ti and BLR[i, j] >= tb


rec1 = sum(1 for a, b in seed if hit(a, b))
rec2 = sum(1 for a, b in seed if hit(a, b, T_IOU2, T_BLUR2))
iu = np.triu_indices(len(pool), 1)
allsim_i = IOU[iu]
allsim_b = BLR[iu]
npair = len(allsim_i)
fp1 = int(((allsim_i >= T_IOU) & (allsim_b >= T_BLUR)).sum())
fp2 = int(((allsim_i >= T_IOU2) & (allsim_b >= T_BLUR2)).sum())
print("   種集合(教科書的形近字) %d 対" % len(seed))
print("   厳(IoU>=%.2f かつ blur>=%.2f): 再現率 %d/%d = %.0f%%  / 一级3500 の全 %s 対中 %d 対 = %.4f%%"
      % (T_IOU, T_BLUR, rec1, len(seed), 100.0 * rec1 / len(seed), format(npair, ','), fp1, 100.0 * fp1 / npair))
print("   緩(IoU>=%.2f かつ blur>=%.2f): 再現率 %d/%d = %.0f%%  / 全対中 %d 対 = %.4f%%"
      % (T_IOU2, T_BLUR2, rec2, len(seed), 100.0 * rec2 / len(seed), fp2, 100.0 * fp2 / npair))
print("   ★再現率が5割前後なので、以下の件数は全て【下限】である。")
print("   ★既知の限界: 曰/日 は IoU=%.3f と低く拾えない(縦横比が違うため画素重なりが小さい)。"
      % IOU[PIDX['曰'], PIDX['日']])
print("     画素重なりは『同じ部品を同じ位置に持つ』型の紛らわしさを拾い、『比率違い』型は拾えない。")

# フォント頑健性
#   ★注意: 書体が違えば線の太さが違うので【同じ絶対閾値】を当てるのは誤り。
#     黑体系は線が太く画素重なりが全体に大きく出る(絶対閾値だと 7,153 対になる)。
#     そこで第2書体の閾値は『第1書体の閾値と同じ分位点』に取り、偽陽性率を揃えて比較する。
IOU2, BLR2 = build(*FONTS[1][:2])
qi = float((allsim_i < T_IOU).mean())
qb = float((allsim_b < T_BLUR).mean())
t_i2 = float(np.quantile(IOU2[iu], qi))
t_b2 = float(np.quantile(BLR2[iu], qb))
m1 = (IOU >= T_IOU) & (BLR >= T_BLUR)
m2 = (IOU2 >= t_i2) & (BLR2 >= t_b2)
both = int((m1 & m2)[iu].sum())
print("   フォント頑健性(分位点を揃える): %s IoU>=%.2f/blur>=%.2f → %d 対 ; %s IoU>=%.2f/blur>=%.2f → %d 対"
      % (FONTS[0][2], T_IOU, T_BLUR, fp1, FONTS[1][2], t_i2, t_b2, int(m2[iu].sum())))
print("   両書体で成立 %d 対 (宋体側の %.0f%%)。★以下は両書体で成立した対だけを採用する。"
      % (both, 100.0 * both / max(1, fp1)))
ROB = m1 & m2   # ★両フォントで成立する対だけを採用する
rec_rob = sum(1 for a, b in seed if ROB[PIDX[a], PIDX[b]])
print("   採用集合での種集合再現率: %d/%d = %.0f%% (=件数は下限)" % (rec_rob, len(seed), 100.0 * rec_rob / len(seed)))

# ================================================================
# 2. [A] 書字負荷(画数) — R3 と §4.3④ の実行度
# ================================================================
print("\n" + "=" * 100)
print("■ 2. [A] 書字負荷 = 画数。方針 R3「少画数優先」は優先順位どおりに効いているか")
print("=" * 100)
print("   基準: 一级3500 の平均画数 = %.2f 画" % (sum(stroke.values()) / len(stroke)))


def root_strokes(d):
    cs = [c for c in d['disp'] if is_cjk(c)]
    return sum(stroke.get(c, 0) for c in cs), len(cs)


print("   ★分解して見る: 面の総画数 = 面の字数 × 1字あたり画数。")
print("     方針 §4.3 は『③文字数 → ④画数』の順なので、どちらが効いているかは分けて測る必要がある。")
print("\n   (i) 型レベル(語根1件=1票。※第23レンズの字数はレキシーム単位なので数値は一致しない)")
print("   %-9s %8s %12s %10s %12s" % ("層", "語根", "面の総画数", "面の字数", "1字あたり画数"))
agg = collections.defaultdict(lambda: [0, 0, 0])
for d in rows:
    s, n = root_strokes(d)
    if n == 0:
        continue
    a = agg[d['tier']]
    a[0] += 1
    a[1] += s
    a[2] += n
for t in TIERS:
    a = agg[t]
    if a[0]:
        print("   %-9s %8d %12.2f %10.2f %12.2f" % (t, a[0], a[1] / a[0], a[2] / a[0], a[1] / a[2]))

# 延べ出現(注入出力の分節)で重み付け
print("\n   (ii) 延べ出現レベル(注入出力の漢字描画分節。学習者版)")
occ_st = collections.defaultdict(lambda: [0, 0, 0])
occ_char = collections.Counter()
for line in io.open(INJ['学習者版'], encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
        continue
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')]
    box = head[head.index('⟦') + 1:head.rindex('⟧')]
    rs = [x for x in re.split(r'[/ ]', raw) if x]
    bs = [x for x in re.split(r'[/ ]', box) if x]
    if len(rs) != len(bs):
        continue
    for r, b in zip(rs, bs):
        cs = [c for c in b if is_cjk(c)]
        if not cs:
            continue
        d = roots.get(r.strip('-')) or roots.get(to_hsys(r.strip('-'))) or roots.get(to_hsys(r.strip('-')).lower())
        if not d:
            continue
        a = occ_st[d['tier']]
        a[0] += 1
        a[1] += sum(stroke.get(c, 0) for c in cs)
        a[2] += len(cs)
        for c in cs:
            occ_char[c] += 1
print("   %-9s %10s %12s %10s %12s" % ("層", "延べ出現", "面の総画数", "面の字数", "1字あたり画数"))
for t in TIERS:
    a = occ_st[t]
    if a[0]:
        print("   %-9s %10d %12.2f %10.2f %12.2f" % (t, a[0], a[1] / a[0], a[2] / a[0], a[1] / a[2]))
print("\n   ★読み方: 総画数は層順に単調に増えるが、その差は【字数】が作っている。")
print("     1字あたり画数は層間でほぼ平坦(むしろ CSV2890 が PIV より僅かに多い)。")
print("     = R3『少画数優先』は層間の差を作る主要な梃子ではなく、効いているのは §4.3③『文字数』。")
print("     これは方針が定めた優先順(③文字数 → ④画数)そのままの結果であり、違反ではない。")

# ================================================================
# 3. [B] 割り当て字集合の『形の混み具合』 — 基準率で正規化
# ================================================================
print("\n" + "=" * 100)
print("■ 3. [B] 割り当てた 2,261 字は形の上でどれだけ混んでいるか(基準率で正規化)")
print("=" * 100)
uidx = np.array([PIDX[c] for c in UC])
sub = ROB[np.ix_(uidx, uidx)]
n_act = int(np.triu(sub, 1).sum())
print("   実際: 使用 %d 字の中に形近対 %d 組" % (len(UC), n_act))

random.seed(20260802)
rng = np.random.default_rng(20260802)


def count_pairs(idx):
    s = ROB[np.ix_(idx, idx)]
    return int(np.triu(s, 1).sum())


uni = [count_pairs(rng.choice(len(pool), size=len(UC), replace=False)) for _ in range(200)]
# 画数分布を保存した対照
by_st = collections.defaultdict(list)
for i, c in enumerate(pool):
    by_st[stroke[c]].append(i)
need = collections.Counter(stroke[c] for c in UC)
matched = []
for _ in range(200):
    idx = []
    for s, k in need.items():
        cand = by_st[s]
        idx.extend(rng.choice(cand, size=min(k, len(cand)), replace=False))
    matched.append(count_pairs(np.array(idx)))
print("   対照A 一様無作為に %d 字選ぶ        : 平均 %.1f 組 (lift %.2f 倍)"
      % (len(UC), np.mean(uni), n_act / max(1e-9, np.mean(uni))))
print("   対照B ★画数分布を保存して選ぶ        : 平均 %.1f 組 (lift %.2f 倍)"
      % (np.mean(matched), n_act / max(1e-9, np.mean(matched))))
print("   → 対照Aと対照Bの差 (%.1f→%.1f) が『R3 で易しい字を選んだこと』の代償。"
      % (np.mean(uni), np.mean(matched)))
print("     対照Bと実際の差 (%.1f→%d) が『どの字を選んだか』に由来する上乗せ。" % (np.mean(matched), n_act))

# ================================================================
# 4. [C] ★配信面の形近衝突 — 第23が定義上測れなかった空間
# ================================================================
print("\n" + "=" * 100)
print("■ 4. [C] 配信面の形近衝突 = 1字を『形の双子』に読み違えると別語根の面になる")
print("=" * 100)
twin = collections.defaultdict(list)
tri = np.triu(ROB, 1)
for i, j in zip(*np.nonzero(tri)):
    a, b = pool[i], pool[j]
    twin[a].append(b)
    twin[b].append(a)

surf2roots = collections.defaultdict(list)
for d in rows:
    if any(is_cjk(c) for c in d['surf']):
        surf2roots[d['surf']].append(d)

collisions = []
seen_pair = set()
for s, ds in surf2roots.items():
    for pos, ch in enumerate(s):
        if not is_cjk(ch):
            continue
        for tw in twin.get(ch, ()):
            s2 = s[:pos] + tw + s[pos + 1:]
            if s2 not in surf2roots:
                continue
            for d1 in ds:
                for d2 in surf2roots[s2]:
                    if d1['gk'] == d2['gk']:
                        continue
                    key = tuple(sorted((d1['root'], d2['root'])))
                    if key in seen_pair:
                        continue
                    seen_pair.add(key)
                    collisions.append((d1, d2, ch, tw))
print("   形近距離1の面の対: %d 組 (面の種類 %d)" % (len(collisions), len(surf2roots)))

#  ★真の欠陥は『マークまで同じ』対だけ。マークが違えば実配信面は区別される。
unresolved = [t for t in collisions if t[0]['sup'] == t[1]['sup']]
print("   うちマークまで同じ(=実配信面でも区別されない) %d 組 / マーク差で救済 %d 組"
      % (len(unresolved), len(collisions) - len(unresolved)))

tden = collections.Counter()
for d in rows:
    if any(is_cjk(c) for c in d['surf']):
        tden[d['tier']] += 1


def tier_rate(colls, label):
    inv = set()
    for d1, d2, a, b in colls:
        inv.add(d1['root'])
        inv.add(d2['root'])
    cnt = collections.Counter(d['tier'] for d in rows if d['root'] in inv)
    print("\n   層別 — %s" % label)
    print("   %-9s %10s %10s %8s" % ("層", "語根", "該当", "率"))
    for t in TIERS:
        if tden[t]:
            print("   %-9s %10d %10d %7.2f%%" % (t, tden[t], cnt[t], 100.0 * cnt[t] / tden[t]))
    return inv


inv_all = tier_rate(collisions, "形近双子を持つ面(マーク差での救済を含む)")
inv_unres = tier_rate(unresolved, "★マークでも救済されない形近双子を持つ面")

# 延べ出現で重み付け(実際に読者が遭遇する率)
print("\n   ★延べ出現で重み付け(注入出力・学習者版。実際に読者が遭遇する率)")
occ_tot = collections.Counter()
occ_hit = collections.Counter()
for line in io.open(INJ['学習者版'], encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
        continue
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')]
    box = head[head.index('⟦') + 1:head.rindex('⟧')]
    rs = [x for x in re.split(r'[/ ]', raw) if x]
    bs = [x for x in re.split(r'[/ ]', box) if x]
    if len(rs) != len(bs):
        continue
    for r, b in zip(rs, bs):
        if not any(is_cjk(c) for c in b):
            continue
        rr = r.strip('-')
        d = roots.get(rr) or roots.get(to_hsys(rr)) or roots.get(to_hsys(rr).lower())
        if not d:
            continue
        occ_tot[d['tier']] += 1
        if d['root'] in inv_unres:
            occ_hit[d['tier']] += 1
print("   %-9s %10s %10s %8s" % ("層", "延べ出現", "該当", "率"))
for t in TIERS:
    if occ_tot[t]:
        print("   %-9s %10d %10d %7.2f%%" % (t, occ_tot[t], occ_hit[t], 100.0 * occ_hit[t] / occ_tot[t]))
tt, th = sum(occ_tot.values()), sum(occ_hit.values())
print("   %-9s %10d %10d %7.2f%%" % ('全体', tt, th, 100.0 * th / max(1, tt)))

# 対照: 画数分布保存の無作為割り当てで同じ数を数える
print("\n   ★対照 — 同じ面の長さ構造のまま、字を【1字ずつ同じ画数の別字に】無作為に差し替えた場合")


def collide_count(mapping):
    s2r = collections.defaultdict(list)
    for d in rows:
        if not any(is_cjk(c) for c in d['surf']):
            continue
        s2r[''.join(mapping.get(c, c) for c in d['surf'])].append(d)
    n = nu = 0
    sp = set()
    for s, ds in s2r.items():
        for pos, ch in enumerate(s):
            if not is_cjk(ch):
                continue
            for tw in twin.get(ch, ()):
                s2 = s[:pos] + tw + s[pos + 1:]
                if s2 not in s2r:
                    continue
                for d1 in ds:
                    for d2 in s2r[s2]:
                        if d1['gk'] == d2['gk']:
                            continue
                        k = tuple(sorted((d1['root'], d2['root'])))
                        if k not in sp:
                            sp.add(k)
                            n += 1
                            if d1['sup'] == d2['sup']:
                                nu += 1
    return n, nu


by_st_used = collections.defaultdict(list)
for c in UC:
    by_st_used[stroke[c]].append(c)
ctrl, ctrl_u = [], []
for _ in range(10):
    mp = {}
    for s, cs in by_st_used.items():
        cand = [pool[i] for i in by_st[s]]
        tgt = rng.choice(cand, size=len(cs), replace=False).tolist()
        mp.update(zip(cs, tgt))      # ★1字ずつ同じ画数の別字へ写す(全体分布でなく各字で保存)
    a, u = collide_count(mp)
    ctrl.append(a)
    ctrl_u.append(u)
print("   対照(10回): 全体 平均 %.1f 組 / マーク未救済 平均 %.1f 組" % (np.mean(ctrl), np.mean(ctrl_u)))
print("   実際      : 全体 %d 組 (偶然の %.2f 倍) / マーク未救済 %d 組 (偶然の %.2f 倍)"
      % (len(collisions), len(collisions) / max(1e-9, np.mean(ctrl)),
         len(unresolved), len(unresolved) / max(1e-9, np.mean(ctrl_u))))
print("   → 1未満なら『意味で選んだ結果、偶然よりも形が離れている』ことを意味する。")

# 危険度順に列挙(両方の F の小さい方が大きいほど危険 = 両方とも実際に出る)
def risk(t):
    d1, d2, a, b = t
    return min(d1['F'], d2['F'])


collisions.sort(key=risk, reverse=True)
unresolved.sort(key=risk, reverse=True)
print("\n   ★危険度上位 — マークでも救済されない対のみ (min(F) が大きい = 両方とも実際によく出る)")
print("   %-24s %-24s %-6s %-6s %s" % ("語根A(面)", "語根B(面)", "字", "min F", "層"))
for d1, d2, a, b in unresolved[:30]:
    print("   %-24s %-24s %s⇔%s %5d   %s/%s"
          % ("%s(%s)" % (d1['root'], d1['disp']), "%s(%s)" % (d2['root'], d2['disp']),
             a, b, min(d1['F'], d2['F']), d1['tier'], d2['tier']))

# ================================================================
# 4b. [C2] ★語形レベル — 実際に配信される面(ラテン語尾込み・マーク込み)で測り直す
#     語根の面どうしが形近でも、実際の語形は語尾が付くので一致しないことがある。
#     例: si(己) は再帰代名詞なので【主格になれない】=常に 己a/己n/己an で現れ、
#         jam(已) は副詞で語尾を取らない。よって 已 と 己 は語形としては衝突しない。
#     これは第30レンズ続69の裁定(ラテン語尾が『エスペラント語だ』と標識する)と同型の機構。
# ================================================================
print("\n" + "=" * 100)
print("■ 4b. [C2] ★語形レベルの形近衝突 — 配信される面そのもの(語尾込み・マーク込み)で測る")
print("=" * 100)
form2head = collections.defaultdict(set)
form_tier = {}
for line in io.open(INJ['学習者版'], encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
        continue
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')]
    box = head[head.index('⟦') + 1:head.rindex('⟧')]
    rs = [x for x in re.split(r'[/ ]', raw) if x]
    bs = [x for x in re.split(r'[/ ]', box) if x]
    if len(rs) != len(bs):
        continue
    # 空白=見える語境界なので語ごとに分ける(第30レンズの教訓)
    for rw, bw in zip(raw.split(' '), box.split(' ')):
        surf = bw.replace('/', '')
        if not any(is_cjk(c) for c in surf):
            continue
        key = rw.replace('/', '')
        form2head[surf].add(key)
        segs = [x.strip('-') for x in rw.split('/') if x]
        ts = []
        for s in segs:
            dd = roots.get(s) or roots.get(to_hsys(s)) or roots.get(to_hsys(s).lower())
            if dd:
                ts.append(dd['tier'])
        for t in TIERS:
            if t in ts and t != '文法層':
                form_tier[surf] = t
                break
        else:
            form_tier.setdefault(surf, '文法層')
print("   配信される語形の面: %d 種" % len(form2head))
fcoll = []
for s, hs in form2head.items():
    for pos, ch in enumerate(s):
        if not is_cjk(ch):
            continue
        for tw in twin.get(ch, ()):
            s2 = s[:pos] + tw + s[pos + 1:]
            if s2 <= s or s2 not in form2head:
                continue
            if hs & form2head[s2]:
                continue
            fcoll.append((s, s2, sorted(hs)[:3], sorted(form2head[s2])[:3], ch, tw))
print("   ★語形の面が形近距離1で別語になる対: %d 組 (語形 %d 種のうち)" % (len(fcoll), len(form2head)))
ft = collections.Counter()
inv_f = set()
for s, s2, h1, h2, a, b in fcoll:
    inv_f.add(s)
    inv_f.add(s2)
fden = collections.Counter(form_tier[s] for s in form2head)
fhit = collections.Counter(form_tier[s] for s in inv_f)
print("   %-9s %10s %10s %8s" % ("層", "語形", "形近双子あり", "率"))
for t in TIERS:
    if fden[t]:
        print("   %-9s %10d %10d %7.2f%%" % (t, fden[t], fhit[t], 100.0 * fhit[t] / fden[t]))
print("   ※層は語形を構成する形態素のうち最上位のものを採る。")
print("\n   例(先頭30組):")
for s, s2, h1, h2, a, b in fcoll[:30]:
    print("   %-14s(%s) ⇔ %-14s(%s)  %s⇔%s" % (s, ','.join(h1), s2, ','.join(h2), a, b))

# ================================================================
# 5. [D] 実配信テキストでの実害
# ================================================================
print("\n" + "=" * 100)
print("■ 5. [D] ユーザー自身の配信テキストに、形近衝突する面が実際に現れるか")
print("=" * 100)
text = []
for cp in CORPUS:
    if os.path.exists(cp):
        for line in io.open(cp, encoding='utf-8', errors='replace'):
            if re.search(r'[ぁ-んァ-ヶ]', line) or line.startswith('#'):
                continue
            text.append(line)
body = '\n'.join(text)
surf_in_text = collections.Counter()
for m in re.finditer(r'[一-鿿][一-鿿]*', body):
    surf_in_text[m.group(0)] += 1
print("   ★実害の条件は『両方の面が本文に現れる』こと。片方しか出ないなら読み違えても着地先が無い。")
# 本文に現れる面(マークを剥がした漢字連続)
txt_surf = collections.Counter()
i = 0
while i < len(body):
    if is_cjk(body[i]):
        j = i + 1
        run = [body[i]]
        while j < len(body):
            if is_cjk(body[j]):
                run.append(body[j])
                j += 1
            elif is_mark(body[j]):
                j += 1
            else:
                break
        txt_surf[''.join(run)] += 1
        i = j
    else:
        i += 1
one = two = 0
rows_d = []
for d1, d2, a, b in collisions:
    n1, n2 = txt_surf.get(d1['surf'], 0), txt_surf.get(d2['surf'], 0)
    if n1 and n2:
        two += 1
        rows_d.append((min(n1, n2), d1, d2, a, b, n1, n2))
    elif n1 or n2:
        one += 1
rows_d.sort(key=lambda x: -x[0])
print("   本文の漢字連続 %d 種 / 片方だけ本文に現れる対 %d / ★両方現れる対 %d"
      % (len(txt_surf), one, two))
print("   %-24s %-24s %-6s %-14s %s" % ("語根A(面)", "語根B(面)", "字", "本文A/本文B", "マーク救済"))
for mn, d1, d2, a, b, n1, n2 in rows_d[:25]:
    print("   %-24s %-24s %s⇔%s %6d/%-6d %s"
          % ("%s(%s)" % (d1['root'], d1['disp']), "%s(%s)" % (d2['root'], d2['disp']),
             a, b, n1, n2, 'あり' if d1['sup'] != d2['sup'] else '★なし'))
nres = sum(1 for x in rows_d if x[1]['sup'] == x[2]['sup'])
print("   → 両方現れる %d 対のうち、マークでも区別されない = ★%d 対" % (two, nres))

# ★語形まで一致するか(ラテン語尾込み)。ここまで来て初めて『実際に取り違えうる』と言える。
print("\n   ★最終段 — 本文中の【語形】(ラテン語尾込み)が形近距離1で一致するか")
tok = collections.Counter()
for m in re.finditer(r'[A-Za-zĉĝĥĵŝŭ一-鿿̀-ͯᴬ-ᵪʰ-˿⁰-₟]+', body):
    t = m.group(0)
    if any(is_cjk(c) for c in t):
        tok[t] += 1
real = []
for mn, d1, d2, a, b, n1, n2 in rows_d:
    if d1['sup'] != d2['sup']:
        continue
    hits = []
    for t1, c1 in tok.items():
        for pos, ch in enumerate(t1):
            if ch != a and ch != b:
                continue
            t2 = t1[:pos] + (b if ch == a else a) + t1[pos + 1:]
            if t2 in tok:
                hits.append((t1, c1, t2, tok[t2]))
    forms1 = sorted(t for t in tok if a in t)[:6]
    forms2 = sorted(t for t in tok if b in t)[:6]
    print("   %s(%s) ⇔ %s(%s):" % (d1['root'], a, d2['root'], b))
    print("      本文の語形 %s=[%s] / %s=[%s]" % (a, ' '.join(forms1), b, ' '.join(forms2)))
    if hits:
        real.append((d1, d2, hits))
        print("      ★語形まで一致 → %s" % ' , '.join('%s(%d)⇔%s(%d)' % h for h in hits))
    else:
        print("      → 語形は一致しない(ラテン語尾または上付きが違うため実際には取り違え得ない)")
print("\n   ★★実配信テキストで本当に取り違えうるのは %d 対。" % len(real))

# ================================================================
# 6. [E] 識別子マーク自体の弁別性
# ================================================================
print("\n" + "=" * 100)
print("■ 6. [E] 識別子マークの弁別性 — 同一群の中でマークが形として見分けられるか")
print("=" * 100)
print("   ※仕様書 L54 が anĉov=鱼ᴬᶜ̂ / anchov=鱼ᴬᶜ を『視覚的に紛らわしいが現状許容』と明記している。")
print("     既知1件で終わっているのか、同型が他にもあるのかは未点検だった。")
grp = collections.defaultdict(list)
for d in rows:
    grp[d['gk']].append(d)
pairs_same = []
for gk, ds in grp.items():
    ds2 = [d for d in ds if d['sup']]
    for i in range(len(ds2)):
        for j in range(i + 1, len(ds2)):
            s1, s2 = ds2[i]['sup'], ds2[j]['sup']
            b1 = ''.join(c for c in s1 if unicodedata.category(c) != 'Mn')
            b2 = ''.join(c for c in s2 if unicodedata.category(c) != 'Mn')
            if s1 != s2 and b1 == b2:
                pairs_same.append((gk, ds2[i], ds2[j], 'ダイアクリティカルのみ差'))
            elif s1 != s2 and b1.lower() == b2.lower() and b1 != b2:
                pairs_same.append((gk, ds2[i], ds2[j], '大小のみ差'))
print("   同一群内でマークが『付加記号のみ/大小のみ』の差である対: %d 組" % len(pairs_same))
tc = collections.Counter()
fmax = 0
for gk, d1, d2, why in pairs_same:
    tc[tuple(sorted((d1['tier'], d2['tier'])))] += 1
    fmax = max(fmax, min(d1['F'], d2['F']))
print("   層の組: " + ' / '.join('%s×%s=%d' % (a, b, n) for (a, b), n in tc.most_common()))
print("   ★min(F) の最大値 = %d — どれも派生をほとんど持たない末端の生物名である" % fmax)
for gk, d1, d2, why in pairs_same:
    print("   [%s] %s(%s)F=%d ⇔ %s(%s)F=%d  %s  [%s/%s]"
          % (gk, d1['root'], d1['disp'], d1['F'], d2['root'], d2['disp'], d2['F'],
             why, d1['tier'], d2['tier']))

# 群を跨いだ場合も参考に(面が同じ漢字なら実質同型)
print("\n   ※群が違えば基底の漢字が違うので、マークが似ていても面は区別される。")

# ================================================================
# 7. [F] ★修復可能性の上界 — 形の弁別性を割り当て基準に足すことは可能か
#     R2 は「一级3500 内」を絶対条件にしている。3500 のうち 2,261 を使用済なので
#     交換先の在庫は 1,239 字。そのうち『使用済の字と形が近くない』ものが安全な交換先になる。
#     ★実測すると在庫は薄くない(90.7%が形の上で孤立)。つまり制約は字の供給ではなく
#       R4(意味の透明性)の側にある = 残っている衝突は『透明性を形より優先した結果』であり、
#       §4.3 の採否比較順(①意味透明性 → ② → ③ → ④)そのままの帰結である。
# ================================================================
print("\n" + "=" * 100)
print("■ 7. [F] 修復可能性の上界 — 形の弁別性は割り当て基準に後付けできるか")
print("=" * 100)
free = [c for c in pool if c not in used]
usedset = set(UC)
safe = []
for c in free:
    i = PIDX[c]
    if not any(ROB[i, PIDX[u]] for u in usedset):
        safe.append(c)
print("   一级3500 の在庫: 使用済 %d / 未使用 %d" % (len(UC), len(free)))
print("   未使用のうち『使用済のどの字とも形が近くない』= %d 字 (%.1f%%)"
      % (len(safe), 100.0 * len(safe) / max(1, len(free))))
print("   ★ただし交換先は同時に R4(意味の透明性=最重要)を満たさねばならない。")
print("     形だけで選べる在庫があっても、意味が合わなければ使えない。")
print("     実例: ripoz=休 の代替を探すと 歇=paŭz が使用済 / 息=spir 使用済 / 憩は一级外(R2違反) /")
print("           闲=sinekur 使用済 / 卧・逸 は空きだが「休息」ほど透明でない。")
print("     = 形の弁別性を基準に足すと、有限な3500字の中で必ず R2 と R4 に衝突する。")

# ================================================================
# 8. TSV 出力
# ================================================================
with io.open("_lens31_glyph_pairs.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("語根A\t面A\t層A\tFA\t語根B\t面B\t層B\tFB\t字A\t字B\tIoU\tblur\tマーク差\n")
    for d1, d2, a, b in collisions:
        i, j = PIDX[a], PIDX[b]
        f.write("%s\t%s\t%s\t%d\t%s\t%s\t%s\t%d\t%s\t%s\t%.3f\t%.3f\t%s\n"
                % (d1['root'], d1['disp'], d1['tier'], d1['F'], d2['root'], d2['disp'], d2['tier'],
                   d2['F'], a, b, IOU[i, j], BLR[i, j], 'あり' if d1['sup'] != d2['sup'] else 'なし'))
with io.open("_lens31_glyph_neighbors.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("字A\t字B\tIoU\tblur\t画数A\t画数B\t使用回数A\t使用回数B\n")
    for i, j in zip(*np.nonzero(np.triu(ROB, 1))):
        a, b = pool[i], pool[j]
        if a in used and b in used:
            f.write("%s\t%s\t%.3f\t%.3f\t%d\t%d\t%d\t%d\n"
                    % (a, b, IOU[i, j], BLR[i, j], stroke[a], stroke[b], used[a], used[b]))
print("\n出力: _lens31_glyph_pairs.tsv / _lens31_glyph_neighbors.tsv")
