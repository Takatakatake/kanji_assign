# -*- coding: utf-8 -*-
# 第29レンズ「PIV層の定義文接地」 (第27回続66)
#
#   ★第17レンズ(訳語グラウンディング)は「PIV層は3154語根中3099(98.3%)が測定不能。
#     PIV項目の語釈はエスペラント文で日本語訳も中国語訳も無く、外部照合の手段が
#     原理的に存在しない」と明記して脱落させた。第20レンズも同じ理由でPIV層を落としている。
#     つまり **辞書の約35%を占める最下位層の割り当ては一度も内容検証されていない**。
#
#   本レンズはその領域に別の真値を当てる: **エスペラント定義文そのもの**。
#   PIVの定義は genus-differentia 形式(例 flebit=「Inflamo de vejno」)なので、
#   割り当てが合成的なら **定義文に出てくる語根の漢字が、当の語根の漢字に現れる** はずである。
#     flebit=脉炎 ← vejn=脉 + inflam=炎     abrazi=磨蚀 ← frot=磨 + eroz=蚀
#
#   ★重要な留保(先に書く): これは第17レンズのような【独立】な外部真値ではない。
#     PIV語根に字を当てた人間は、当然この定義文を読んで字を選んでいる。
#     したがって本レンズが測るのは「割り当ての正しさ」ではなく
#     **『合成的に読める』という約束が実際に守られているか(内部整合)** である。
#     ただし対照(無作為割り当て)との lift は意味を持ち、
#     **接地しない語根の一覧**は実際の点検対象として価値がある。
import io, os, re, sys, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))

INJ = "漢字注入_学術版_20260620.txt"
INJ_L = "漢字注入_学習者版_20260620.txt"
SIDE = "_identifier_sidecar.tsv"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
# 文法語尾。★語末からのみ剥がす。an/en/on は接尾辞/前置詞と同綴なので剥がさない(既知の罠)
ENDS = ['ojn', 'ajn', 'oj', 'aj', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n']
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
# §4.6 生物救済字(科・属でまとめる汎用字)。定義文接地では原理的に落ちるので別勘定にする
BIO_TAGS = ('【動】', '【植】', '【菌】', '【魚】', '【鳥】', '【虫】')


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def cjk(s):
    return set(c for c in s if '一' <= c <= '鿿')


# ---------------------------------------------------------------- 語根表
roots = {}
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    d = {'root': p[0], 'kanji': p[1], 'disp': p[4], 'band': p[5],
         'F': int(p[6]) if p[6].isdigit() else 0}
    # ★表記混在の罠: sidecar は Unicode298/h-system508 が混在。両表記で索引する
    for key in {p[0], to_hsys(p[0]), to_hsys(p[0]).lower(), p[0].lower()}:
        roots.setdefault(key, d)


def lookup(w):
    """定義文中の語 → 語根。語末からのみ語尾を剥がす。"""
    w = to_hsys(w).lower()
    if not w:
        return None
    if w in roots:
        return roots[w]
    for e in ENDS:
        if w.endswith(e) and len(w) > len(e) + 1:
            s = w[:-len(e)]
            if s in roots:
                return roots[s]
    return None


# ---------------------------------------------------------------- CSV2890語根(層判定用)
bare2segs = {}
for path in (INJ, INJ_L):
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')] if '⟦' in head else head
        if ' ' in raw:
            continue
        cs = [s for s in raw.split('/') if s]
        while len(cs) > 1 and cs[-1] in ENDS:
            cs.pop()
        if cs:
            bare2segs.setdefault(raw.replace('/', '').replace('-', '').lower(), [c.strip('-') for c in cs])
csv_roots = set()
if os.path.exists(CSVF):
    with io.open(CSVF, encoding='utf-8-sig') as f:
        rd = _csv.reader(f)
        next(rd, None)
        for rec in rd:
            if not rec or not rec[0].strip():
                continue
            for tok in rec[0].split(','):
                w0 = to_hsys(tok.strip())
                segs = bare2segs.get(w0.replace('/', '').replace('-', '').lower())
                if segs and len(segs) == 1:
                    csv_roots.add(segs[0])
                    csv_roots.add(to_hsys(segs[0]).lower())


def tier_of(d):
    if d['band'] in GRAMMAR:
        return '文法層'
    if d['root'] in csv_roots or to_hsys(d['root']).lower() in csv_roots:
        return 'CSV2890'
    if d['band'] == 'piv':
        return 'PIV'
    return 'PEJVO'


# ---------------------------------------------------------------- 母集団の構築
# 内容形態素1個 + 漢字あり + エスペラント散文の定義 を持つ見出し
items = {}
for line in io.open(INJ, encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
        continue
    head, gl = line.split(':', 1)
    tags = re.findall(r'【[^】]*】', gl)
    g = re.sub(r'【[^】]*】', '', gl).strip()
    if not g or re.search(r'[ぁ-んァ-ヶ一-鿿]', g):
        continue                                   # 日本語/漢字を含む語釈は対象外
    if g.startswith('=') or g.startswith('>>') or len(g.split()) < 3:
        continue                                   # 相互参照は情報を持たない
    raw = head[:head.index('⟦')]
    box = head[head.index('⟦') + 1:head.rindex('⟧')]
    rs = [x for x in raw.split('/') if x]
    bs = [x for x in box.split('/') if x]
    if len(rs) != len(bs):
        continue
    cont = [(r.strip('-'), b) for r, b in zip(rs, bs) if r not in ENDS]
    if len(cont) != 1 or not cjk(cont[0][1]):
        continue
    r, b = cont[0]
    d = lookup(r)
    if not d:
        continue
    # ★定義の本体だけを使う。':' 以降は用例文であり、定義ではない。
    #   これを入れないと「Per la elektro: horlog^o elektre funkcianta」の用例側と
    #   偶然一致するかどうかを測ることになる(初版のバグ)。
    core = g.split(':')[0].strip()
    if len(core.split()) < 2:
        continue
    it = items.setdefault(d['root'], {'d': d, 'box': b, 'defs': [], 'tags': set()})
    it['defs'].append(core)
    it['tags'].update(tags)

print("=" * 100)
print("■ 母集団 — 第17レンズが『測定不能』とした領域")
print("=" * 100)
print("   内容形態素1個 + 漢字描画あり + エスペラント散文の定義 を持つ語根 = %d" % len(items))
tc = collections.Counter(tier_of(v['d']) for v in items.values())
print("   層別: " + ' / '.join('%s=%d' % (t, tc[t]) for t in ('CSV2890', 'PEJVO', 'PIV', '文法層') if tc[t]))


# ---------------------------------------------------------------- 接地判定
def infl_forms(root):
    """定義文が語根自身を使っている(循環定義)場合に除外するための語形集合"""
    r = to_hsys(root).lower()
    return {r} | {r + e for e in ENDS} | {r + x for x in ('ad', 'ec', 'aj', 'ist', 'an')}


WORD = re.compile(r"[A-Za-zĉĝĥĵŝŭĈĜĤĴŜŬ^']+")


def ground(it, kmap):
    """定義文の語根の漢字と、当の語根の漢字が字を共有するか。
       kmap: root -> kanji (対照実験では巡回シフトした表を渡す)"""
    mine = cjk(kmap.get(it['d']['root'], ''))
    if not mine:
        return None, 0, []
    skip = infl_forms(it['d']['root'])
    hit = []
    seen = 0
    for g in it['defs']:
        for w in WORD.findall(g):
            wl = to_hsys(w).lower()
            if wl in skip or len(wl) < 3:
                continue
            dd = lookup(wl)
            if not dd or dd['band'] in GRAMMAR:
                continue
            seen += 1
            k = cjk(kmap.get(dd['root'], ''))
            if k & mine:
                hit.append((dd['root'], kmap.get(dd['root'], '')))
    return (len(hit) > 0), seen, hit


kmap = {v['d']['root']: v['box'] for v in items.values()}
for k, d in roots.items():
    kmap.setdefault(d['root'], d['kanji'])

# ★文法層(接辞・前置詞)は母集団から外す。定義がメタ記述(「Pref. montranta...」)で
#   内容語の接地とは別物であり、放置すると非接地リストの上位を占めて点検を汚す。
for r in [r for r, it in items.items() if tier_of(it['d']) == '文法層']:
    del items[r]

# 対照A: 割り当て表を固定オフセットで巡回シフト(第17レンズと同じ手法)
keys = sorted(kmap)
OFF = 499
shifted = {keys[i]: kmap[keys[(i + OFF) % len(keys)]] for i in range(len(keys))}
# 対照B: ★字数を保存したシフト。本指標は「漢字が複数字なら当たりやすい」ので、
#   字数を揃えないと層差が字数の交絡になる(PIVは合成描画・CSV2890は原子字)。
bylen = collections.defaultdict(list)
for k in keys:
    bylen[len(cjk(kmap[k]))].append(k)
shifted_len = {}
for L, ks in bylen.items():
    for i, k in enumerate(ks):
        shifted_len[k] = kmap[ks[(i + OFF) % len(ks)]]


def is_bio(it):
    return bool(it['tags'] & set(BIO_TAGS))


print("\n" + "=" * 100)
print("■ 定義文接地率 — 『定義に出てくる語根の漢字が、当の語根の漢字に現れるか』")
print("=" * 100)
print("   ※対照は割り当て表を固定オフセット%dで巡回シフトした偽の割り当て(第17レンズと同手法)。" % OFF)
rows = []
for r, it in items.items():
    ok, seen, hit = ground(it, kmap)
    ok2, _, _ = ground(it, shifted)
    ok3, _, _ = ground(it, shifted_len)
    if ok is None or seen == 0:
        continue
    rows.append({'root': r, 'tier': tier_of(it['d']), 'box': it['box'], 'ok': ok, 'ctl': ok2,
                 'ctlL': ok3, 'nk': len(cjk(it['box'])),
                 'bio': is_bio(it), 'hit': hit, 'def': it['defs'][0][:90], 'F': it['d']['F']})
print("   判定できた語根 = %d (定義本体に自己以外の既知語根が1つも無い行は除外)" % len(rows))
selfref = collections.Counter()
tot_t = collections.Counter()
for r, it in items.items():
    t = tier_of(it['d'])
    tot_t[t] += 1
    _, seen, _ = ground(it, kmap)
    if seen == 0:
        selfref[t] += 1
print("\n   ★層別の『定義が自己参照のみ(Rilata al X 型)で測定不能』な割合:")
for t in ('CSV2890', 'PEJVO', 'PIV'):
    if tot_t[t]:
        print("      %-9s %4d/%4d = %.1f%%" % (t, selfref[t], tot_t[t], 100.0 * selfref[t] / tot_t[t]))
print("      → この率が層で大きく違うなら、層間の接地率を直接比べてはいけない(定義スタイルの差)。")

for label, sel in (("全体", lambda x: True),
                   ("生物名を除く", lambda x: not x['bio']),
                   ("生物名のみ", lambda x: x['bio'])):
    ss = [x for x in rows if sel(x)]
    if not ss:
        continue
    print("\n   [%s] n=%d" % (label, len(ss)))
    print("   %-9s %7s %9s %9s %8s" % ("層", "語根", "接地", "接地率", "対照(偶然)"))
    for t in ('CSV2890', 'PEJVO', 'PIV'):
        g = [x for x in ss if x['tier'] == t]
        if not g:
            continue
        n = len(g)
        o = sum(1 for x in g if x['ok'])
        c = sum(1 for x in g if x['ctl'])
        print("   %-9s %7d %9d %8.1f%% %7.1f%%" % (t, n, o, 100.0 * o / n, 100.0 * c / n))
    n = len(ss)
    o = sum(1 for x in ss if x['ok'])
    c = sum(1 for x in ss if x['ctl'])
    print("   %-9s %7d %9d %8.1f%% %7.1f%%   lift=%.1f倍" %
          ('計', n, o, 100.0 * o / n, 100.0 * c / n, (o / max(1, c))))

# ---------------------------------------------------------------- 字数の交絡を潰す
print("\n" + "=" * 100)
print("■ ★交絡の検査 — 層差は『下位層の描画が複数字だから』ではないか")
print("=" * 100)
print("   本指標は漢字が多いほど当たりやすい。層別の平均字数を見てから、字数で層化して比べる。")
for t in ('CSV2890', 'PEJVO', 'PIV'):
    g = [x for x in rows if x['tier'] == t]
    if g:
        print("   %-9s 平均字数=%.2f  1字率=%.1f%%" %
              (t, sum(x['nk'] for x in g) / len(g),
               100.0 * sum(1 for x in g if x['nk'] == 1) / len(g)))
print("\n   [字数で層化した接地率] 括弧内は字数を保存した対照(偶然)")
print("   %-7s %-22s %-22s %s" % ("字数", "CSV2890", "PEJVO", "PIV"))
for L in (1, 2, 3):
    cells = []
    for t in ('CSV2890', 'PEJVO', 'PIV'):
        g = [x for x in rows if x['tier'] == t and (x['nk'] == L if L < 3 else x['nk'] >= 3)]
        if len(g) < 15:
            cells.append("%-22s" % ("n=%d(小)" % len(g)))
            continue
        o = 100.0 * sum(1 for x in g if x['ok']) / len(g)
        c = 100.0 * sum(1 for x in g if x['ctlL']) / len(g)
        cells.append("%-22s" % ("%5.1f%% (%.1f%%) n=%d" % (o, c, len(g))))
    print("   %-7s %s %s %s" % ('3字以上' if L == 3 else '%d字' % L, cells[0], cells[1], cells[2]))
print("\n   ★同じ字数で比べても PIV が上なら層差は本物。1字どうしで差が消えるなら字数の交絡。")

# ---------------------------------------------------------------- 接地の【機構】を分ける
# ★1字描画は原理的に「合成」できない(2語根の字を並べる余地が無い)ので、
#   1字での接地は必ず『定義文が同義語を名指しし、その同義語と同じ字群に合流している』ことを意味する。
#   両者を混ぜて「合成的」と呼ぶのは誤り。分けて数える。
print("\n" + "=" * 100)
print("■ ★接地の機構は2つある — 混ぜてはいけない")
print("=" * 100)
print("   (a) 同義語合流: 定義文が指す語根が【同じ裸漢字群】に属する(mikologi=菌学 ← 定義『Fungologio』=菌学ᶠ)")
print("       → 字種を増やさず既存群へ吸収した、というユーザー原則の直接の実行")
print("   (b) 合成: 定義文の複数語根の【異なる字】が並んで描画を作る(flebit=脉炎 ← vejn=脉 + inflam=炎)")
print("       → 偽分解を超えた分解の実行")
bare = {}
for k, d in roots.items():
    bare[d['root']] = d['kanji']


def mech(x):
    mine = cjk(x['box'])
    syn = comp = False
    for r, kk in x['hit']:
        hk = cjk(bare.get(r, kk))
        if hk and hk == mine:
            syn = True                      # 裸漢字が完全一致=同じ群=同義語合流
        elif hk & mine and hk != mine:
            comp = True                     # 一部を共有=構成要素
    return syn, comp


print("\n   %-9s %7s %10s %10s %10s" % ("層", "接地", "(a)同義語合流", "(b)合成", "両方/不明"))
for t in ('CSV2890', 'PEJVO', 'PIV'):
    g = [x for x in rows if x['tier'] == t and x['ok']]
    if not g:
        continue
    s = c = b = 0
    for x in g:
        sy, co = mech(x)
        if sy and co:
            b += 1
        elif sy:
            s += 1
        elif co:
            c += 1
        else:
            b += 1
    print("   %-9s %7d %10d %10d %10d" % (t, len(g), s, c, b))
print("\n   [字数別に見た機構] 1字描画は定義上(b)が不可能なので、そこは全て(a)のはず")
for L in (1, 2, 3):
    g = [x for x in rows if x['ok'] and (x['nk'] == L if L < 3 else x['nk'] >= 3)]
    if not g:
        continue
    s = sum(1 for x in g if mech(x)[0])
    c = sum(1 for x in g if mech(x)[1])
    print("   %-7s 接地%4d件 → (a)同義語合流 %4d件 (%.0f%%) / (b)合成 %4d件 (%.0f%%)" %
          ('3字以上' if L == 3 else '%d字' % L, len(g), s, 100.0 * s / len(g), c, 100.0 * c / len(g)))

# ---------------------------------------------------------------- 非接地の検分
print("\n" + "=" * 100)
print("■ 接地しなかった語根 — ★『誤り』ではない。本指標は正しさの検出器として再現率が低い")
print("=" * 100)
print("   非接地は『定義文が別の語彙で概念を説明しており、字の重なりが無い』だけのことが多い。")
print("   実際に上位を目視すると: petr=岩ᴾ(terkrusto の材料)・sapr=腐ˢᴿ(Neviva organika materio)・")
print("   blink=闪ᴮ(Intermita lumo)・sukur=急救(unuan helpon al vunditoj)・anabol=合成(konstruo de")
print("   protoplasmo)・erot=色ᴱᴿ(La seksa impulso) — いずれも割り当ては正しい。")
print("   したがってこの一覧は『是正候補』ではなく『本指標で捕まえられなかった集合』である。")
bad = [x for x in rows if not x['ok'] and not x['bio']]
bad.sort(key=lambda x: -x['F'])
print("   生物名を除く非接地 = %d件 (生物名の非接地 %d件は §4.6 の科・属別汎用字なので設計どおり)" %
      (len(bad), sum(1 for x in rows if not x['ok'] and x['bio'])))
print("   F降順の上位30件:")
print("   %-16s %-8s %-8s %s" % ("root", "漢字", "層", "定義文(先頭)"))
for x in bad[:30]:
    print("   %-16s %-8s %-8s %s" % (x['root'], x['box'], x['tier'], x['def'][:64]))

with io.open("_lens29_definition_grounding.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("root\t層\t漢字\t接地\t生物名\tF\t接地した定義語根\t定義文\n")
    for x in sorted(rows, key=lambda y: (y['ok'], y['tier'], -y['F'])):
        f.write("%s\t%s\t%s\t%s\t%s\t%d\t%s\t%s\n" %
                (x['root'], x['tier'], x['box'], 'Y' if x['ok'] else 'N',
                 'Y' if x['bio'] else '', x['F'],
                 ','.join('%s=%s' % h for h in x['hit'][:5]), x['def']))
print("\n出力: _lens29_definition_grounding.tsv")
