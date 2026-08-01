# -*- coding: utf-8 -*-
# 第30レンズ「外部語彙との偽友 — 描画列が中国語の実在語として別義に読めるか」 (第27回続67)
#
#   第1〜29は全て【体系の内側】を測ってきた。第23(近傍衝突)・第26(分節一意性)ですら
#   「体系内の別のエスペラント語と取り違えるか」であり、第17の誤友検出も
#   【語根単位】(その語根の割当トークンが他語根の訳語と一致するか)だった。
#
#   ★未測定の失敗様式: **複数の形態素が連結した結果、意図せず中国語の実在語ができてしまう**。
#     配信面には分節境界が無い(§ `/` は内部表現)ので、読者はその実在語として読んでしまう。
#       al/ir/i ⟦向/往/i⟧ → 面は「向往i」。向往 は中国語で「あこがれる」であって
#                            al+ir(近づく)ではない。しかも派生形6語すべてに伝播する。
#   これは語根単位の検査では原理的に見えない(向 も 往 も単体では正しい)。
#
#   ★測り方の注意(初版の probe で実際に踏んだ罠):
#     ・空白は【見える語境界】なので跨いではいけない(蜂/a 蜜/o は「蜂a 蜜o」で 蜂蜜 にならない)
#     ・ラテン語尾が字の間に入ると連続が切れる(蜂/a は「蜂a」)
#     → 面を実際に組み立て、CJKの極大連続の中だけを見る。
import io, os, re, sys, csv as _csv, collections, unicodedata

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))

INJ = {'学習者版': "漢字注入_学習者版_20260620.txt", '学術版': "漢字注入_学術版_20260620.txt"}
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
SIDE = "_identifier_sidecar.tsv"
CORPUS = [os.path.join("..", "漢字化エスペラント日記", f) for f in (
    "エスペラント随想_日記_漢字化エスペラント集成_20260705.md",
    "漢字化エスペラント日記_第2集_漢字化エスペラント集成_20260721.md")]
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
ENDS = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}


def ismark(c):
    return unicodedata.category(c) in ('Lm', 'Mn', 'Sk')


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('ĝ', 'g^'), ('ĥ', 'h^'), ('ĵ', 'j^'), ('ŝ', 's^'), ('ŭ', 'u^')):
        s = s.replace(u, x).replace(u.upper(), x.upper())
    return s


# ---------------------------------------------------------------- 語根表(層判定用)
roots = {}
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    d = {'root': p[0], 'band': p[5], 'F': int(p[6]) if p[6].isdigit() else 0}
    for k in {p[0], to_hsys(p[0]), to_hsys(p[0]).lower()}:
        roots.setdefault(k, d)

# ---------------------------------------------------------------- 外部語彙(中国語の実在語)
# CSV2890 の Chinese_Trans = 簡体字=割り当てと同字種。★パイプラインはこの列を読まない。
zh_src = collections.defaultdict(set)      # 中国語の実在語 -> その語を訳語に持つエス語(出所)
csv_rows = 0
with io.open(CSVF, encoding='utf-8-sig') as f:
    for rec in _csv.DictReader(f):
        csv_rows += 1
        eo = (rec.get('Esperanto') or '').strip()
        for w in re.split(r'[，,;；、（）()／/\s]+', rec.get('Chinese_Trans') or ''):
            w = ''.join(c for c in w if '一' <= c <= '鿿')
            if len(w) >= 2:
                zh_src[w].add(eo)
print("外部語彙: CSV2890(%d行)の中国語訳から得た実在語(2字以上) = %d語" % (csv_rows, len(zh_src)))
ZH = set(zh_src)


# ---------------------------------------------------------------- 面の組み立て
def surfaces(path):
    """見出しごとに (語, 面, 境界集合, 形態素列, マーク位置) を返す。
       ★空白で切る=見える語境界。/ は不可視。上付きは『剥がした面』と『残した面』の両方を作る。"""
    out = []
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')]
        box = head[head.index('⟦') + 1:head.rindex('⟧')]
        rw, bw = raw.split(' '), box.split(' ')
        if len(rw) != len(bw):
            continue
        for rword, bword in zip(rw, bw):
            rs = [x for x in rword.split('/') if x]
            bs = [x for x in bword.split('/') if x]
            if len(rs) != len(bs) or len(bs) < 2:
                continue
            surf = ''
            bnd = set()
            marked = set()          # マークが直後に入る位置(=字の隣接が視覚的に切れる)
            for r, b in zip(rs, bs):
                t = ''.join(c for c in b if not ismark(c))
                if any(ismark(c) for c in b):
                    marked.add(len(surf) + len(t))
                surf += t
                bnd.add(len(surf))
            bnd.discard(len(surf))
            out.append({'head': head, 'word': rword, 'surf': surf, 'bnd': bnd,
                        'segs': list(zip(rs, bs)), 'marked': marked})
    return out


def find_hits(items, vocab):
    """CJKの極大連続の中で、境界を跨ぐ実在語を拾う"""
    res = []
    for it in items:
        for m in re.finditer(r'[一-鿿]+', it['surf']):
            run, off = m.group(0), m.start()
            for i in range(len(run)):
                for L in (2, 3, 4):
                    if i + L > len(run):
                        break
                    w = run[i:i + L]
                    a, b = off + i, off + i + L
                    if w in vocab and any(a < x < b for x in it['bnd']):
                        res.append({'it': it, 'w': w, 'a': a, 'b': b,
                                    'brk': any(a < x < b for x in it['marked'])})
    return res


print("\n" + "=" * 100)
print("■ A. 境界を跨いで意図せず中国語の実在語ができている箇所")
print("=" * 100)
print("   ※空白(見える語境界)は跨がない。ラテン語尾で切れた字は隣接しない。CJK極大連続の中だけを見る。")
allhits = {}
for ver, path in INJ.items():
    items = surfaces(path)
    hits = find_hits(items, ZH)
    allhits[ver] = (items, hits)
    print("   [%s] 複数形態素の語 %d / ★境界跨ぎの実在語 %d箇所 (%d種)" %
          (ver, len(items), len(hits), len(set(h['w'] for h in hits))))

items, hits = allhits['学習者版']


# ---------------------------------------------------------------- 幸運か有害か
def morphs_of(it):
    s = set()
    for r, b in it['segs']:
        s.add(r.strip('-'))
        s.add(to_hsys(r.strip('-')).lower())
    return s


# ★見出し語そのものの中国語訳(同字種=真値)。これが最も信頼できる幸運判定。
#   出所(zh_src)経由の判定は当てにならない: 铁路 の出所が klasifiki と出るなど帰属が雑で、
#   fer/voj/o=铁路(正しい鉄道)や elektr/on/a=电子(正しい電子)を偽友と誤判定していた(初版のバグ)。
word_zh = {}
with io.open(CSVF, encoding='utf-8-sig') as f:
    for rec in _csv.DictReader(f):
        zt = ''.join(c if '一' <= c <= '鿿' else ' ' for c in (rec.get('Chinese_Trans') or ''))
        for tok in (rec.get('Esperanto') or '').split(','):
            t = to_hsys(tok.strip()).replace('/', '').replace('-', '').lower()
            if t:
                word_zh.setdefault(t, '')
                word_zh[t] += ' ' + zt


# ★見出し語自身の【日本語語釈】。面と同じ字が語釈に出れば「偶然できた語が正しい意味」=幸運。
#   日本語語釈と簡体字の間には字体差があるので取りこぼすが、**当たれば高精度**(偽陽性が出にくい)。
#   これを入れないと reg^/id/o→王子・logik/ec/o→理性・rekt/angul/a→直角・mang^/aj^/o→食物 が
#   すべて「偽友候補」に落ちる(初版の汚染)。
word_ja = {}
for _p in INJ.values():
    for line in io.open(_p, encoding='utf-8-sig'):
        if ':' not in line or line.startswith('#') or '⟦' not in line:
            continue
        _h, _g = line.split(':', 1)
        _raw = _h[:_h.index('⟦')]
        if ' ' in _raw:
            continue                      # 複数語見出しは語釈が語に対応しないので使わない
        word_ja[_raw] = word_ja.get(_raw, '') + re.sub(r'【[^】]*】', '', _g)


def classify(h):
    """幸運 = 偶然できた中国語が、まさにその見出しの意味になっている。
       判定は ①見出し語自身の中国語訳(同字種=真値) ②自分の日本語語釈に面が現れる
       ③出所のエス語が見出しの形態素と一致(弱い証拠) の順。"""
    ja = word_ja.get(h['it']['word'], '')
    if ja and h['w'] in ja:
        return 'felicitous'
    key = to_hsys(h['it']['word']).replace('/', '').replace('-', '').lower()
    zt = word_zh.get(key)
    if zt is None:
        for e in ENDS:                      # 語尾違いの見出しを拾う
            if key.endswith(e):
                zt = word_zh.get(key[:-len(e)] + 'o') or word_zh.get(key[:-len(e)] + 'i')
                if zt:
                    break
    if zt and h['w'] in zt:
        return 'felicitous'
    if zt:
        return 'suspect'                    # 真値があって載っていない=確度の高い偽友
    ms = morphs_of(h['it'])
    for eo in zh_src[h['w']]:
        for tok in re.split(r'[,\s]+', eo):
            t = to_hsys(tok.strip()).replace('/', '').lower()
            if not t:
                continue
            for mm in ms:
                if not mm or len(mm) < 3:
                    continue
                if t.startswith(mm) or mm.startswith(t[:max(3, len(t) - 2)]):
                    return 'felicitous'
    return 'unknown'                        # 真値が無く出所も無関係 = 要目視


for h in hits:
    h['cls'] = classify(h)
fel = [h for h in hits if h['cls'] == 'felicitous']
sus = [h for h in hits if h['cls'] in ('suspect', 'unknown')]
print("\n   分類(学習者版 %d箇所): 幸運=%d / 偽友候補=%d (うち中国語訳という真値で確定=%d / 真値が無く要目視=%d)" %
      (len(hits), len(fel), len(sus),
       sum(1 for h in hits if h['cls'] == 'suspect'), sum(1 for h in hits if h['cls'] == 'unknown')))
print("   ★幸運 = 偶然できた中国語が、まさにその意味になっている(出所のエス語が見出しの形態素と一致)")
print("      例: " + ' / '.join(sorted(set('%s→%s' % (h['it']['word'], h['w']) for h in fel))[:6]))

# マークによる分断
brk = sum(1 for h in sus if h['brk'])
print("\n   ★マークによる分断: 偽友候補 %d箇所のうち %d箇所(%.1f%%)は間に上付きが入って字が隣接しない" %
      (len(sus), brk, 100.0 * brk / max(1, len(sus))))
print("      = 識別子機構が外部偽友に対しても副次的な防護になっている(第27レンズの副次効果)")

# ---------------------------------------------------------------- 層別
print("\n" + "=" * 100)
print("■ B. 偽友候補は優先順位のどの層に出るか")
print("=" * 100)


def tier_of_word(it):
    ts = []
    for r, b in it['segs']:
        d = roots.get(r.strip('-')) or roots.get(to_hsys(r.strip('-')).lower())
        if d and d['band'] not in GRAMMAR:
            ts.append('PIV' if d['band'] == 'piv' else ('PEJVO' if d['band'] == 'pejvo' else 'CSV2890側'))
    if not ts:
        return '文法のみ'
    for t in ('CSV2890側', 'PEJVO', 'PIV'):
        if t in ts:
            return t
    return '文法のみ'


tc = collections.Counter(tier_of_word(h['it']) for h in sus)
bc = collections.Counter(tier_of_word(it) for it in items)
print("   偽友候補の語を『最上位の構成層』で分類。★基準率(複数形態素語全体)と並べる:")
print("      %-10s %8s %10s %10s %8s" % ("層", "偽友", "偽友%", "基準%", "比"))
for t, n in tc.most_common():
    p = 100.0 * n / max(1, len(sus))
    q = 100.0 * bc[t] / max(1, len(items))
    print("      %-10s %8d %9.1f%% %9.1f%% %7.2f倍" % (t, n, p, q, p / max(1e-9, q)))
print("      → 比が1に近い層は『そもそもその層の語が多いから』であって集中ではない。")

# ★構造の同定: どの形態素の対が偽友を生んでいるか
print("\n" + "=" * 100)
print("■ B2. ★偽友を生んでいるのは何か — 境界を挟む形態素の対")
print("=" * 100)
pair = collections.Counter()
affix_side = collections.Counter()
for h in sus:
    it = h['it']
    pos = 0
    spans = []
    for r, b in it['segs']:
        t = ''.join(c for c in b if not ismark(c))
        spans.append((pos, pos + len(t), r.strip('-'), t))
        pos += len(t)
    inv = [(r, t) for (s, e, r, t) in spans if s < h['b'] and e > h['a']]
    if len(inv) >= 2:
        pair[' + '.join('%s(%s)' % (r, t) for r, t in inv[:2])] += 1
        for r, t in inv:
            d = roots.get(r) or roots.get(to_hsys(r).lower())
            if d and d['band'] in GRAMMAR:
                affix_side['%s(%s)' % (r, t)] += 1
n_affix = sum(1 for h in sus
              if any((roots.get(r.strip('-')) or roots.get(to_hsys(r.strip('-')).lower()) or {}).get('band') in GRAMMAR
                     for r, b in h['it']['segs']))
# ★基準率で正規化: 接辞は高頻度なので「81.6%が接辞絡み」だけでは過剰かどうか言えない。
#   全ての形態素境界のうち、一方が接辞である割合を分母に取る。
base_tot = base_affix = 0
for it in items:
    segs = it['segs']
    for i in range(len(segs) - 1):
        base_tot += 1
        for r, b in (segs[i], segs[i + 1]):
            d = roots.get(r.strip('-')) or roots.get(to_hsys(r.strip('-')).lower())
            if d and d['band'] in GRAMMAR:
                base_affix += 1
                break
print("   偽友候補 %d箇所のうち、境界の少なくとも一方が【接辞・機能形態素】= %d箇所 (%.1f%%)" %
      (len(sus), n_affix, 100.0 * n_affix / max(1, len(sus))))
print("   ★基準率での正規化: 全形態素境界 %d のうち一方が接辞なのは %d (%.1f%%)。" %
      (base_tot, base_affix, 100.0 * base_affix / max(1, base_tot)))
print("      → 偽友側 %.1f%% vs 基準 %.1f%% = %.2f倍。1に近ければ『接辞が高頻度だから当然』であって"
      % (100.0 * n_affix / max(1, len(sus)), 100.0 * base_affix / max(1, base_tot),
         (n_affix / max(1, len(sus))) / max(1e-9, base_affix / max(1, base_tot))))
print("        接辞が偽友を過剰に生んでいるわけではない。")
print("   ★第20レンズは『接辞トークンは別勘定』として接辞を測定から明示的に除外していた。")
print("     本レンズはその除外領域に別方向から入っている。")
print("\n   偽友を生んでいる接辞(上位12):")
for a, n in affix_side.most_common(12):
    print("      %-14s ×%d" % (a, n))
print("\n   境界を挟む形態素の対(上位12):")
for p, n in pair.most_common(12):
    print("      %-34s ×%d" % (p, n))

byword = collections.Counter(h['w'] for h in sus)
# ★上位語型の人手判定。自動分類は真値(中国語訳)を持つ10件しか確定できないので、
#   頻度上位を目視で確定させる。判定基準=『その面を中国語として読んだ意味が、
#   エスペラント語の意味と一致するか』。
MANUAL = {
    # 幸運 = 中国語として読んでも正しい意味になる(むしろ理想的)
    '铁路': ('幸運', 'fervojo=鉄道。铁路 は中国語でまさに鉄道'),
    '电子': ('幸運', 'elektrono=電子。电子 は中国語でまさに電子'),
    '食物': ('幸運', 'manĝaĵo=食物。食物 は中国語でまさに食べ物'),
    '主义者': ('幸運', '-ismulo=主義者。主义者 は中国語でまさに-ist'),
    '织物': ('幸運', 'teksaĵo=織物。织物 は中国語でまさに織物'),
    '滑行': ('幸運', 'skiado=滑走。滑行 は中国語で滑走'),
    '矿物': ('幸運', 'mineraĵo=鉱物。矿物 は中国語でまさに鉱物'),
    '生物': ('幸運', 'biologia系=生物。生物 は中国語でまさに生物'),
    '变成': ('準幸運', 'ŝanĝiĝo=変化。变成=「〜になる」で近いがずれる'),
    '人群': ('準幸運', 'homaro=人類。人群=群衆でややずれる'),
    '场所': ('準幸運', 'scenejo=舞台。场所=場所でややずれる'),
    '上面': ('準幸運', 'surfaco=表面。上面=上側で近いがずれる(表面が正しい中国語)'),
    # 有害 = 中国語として読むと全く別の意味になる
    '男女': ('★有害', 'virino=女性。男女 は中国語で「男と女」= 数と意味が壊れる'),
    '大使': ('★有害', 'grandigi=拡大する。大使 は中国語で「大使(外交官)」'),
    '强使': ('★有害', 'fortigi=強める。强使 は中国語で「強制する」'),
    '向往': ('★有害', 'aliri=近づく。向往 は中国語で「あこがれる」'),
    '同意': ('★有害', 'sam+signif=同義。同意 は中国語で「同意する」'),
    '不理': ('★有害', 'nelogika=非論理的。不理 は中国語で「無視する」'),
    '反响': ('★有害', 'mallaŭta=静かな。反响 は中国語で「反響・反応」'),
    '不满': ('★有害', 'nekontentiga=不満足な。不满=不満 で品詞と主体がずれる'),
    '不再': ('準有害', 'ne+re=再び〜ない。不再 は中国語で「もはや〜しない」で近い'),
    '再见': ('★有害', 'revido=再会。再见 は中国語で「さようなら」(第23レンズで既知・正当と裁定済)'),
}
print("\n   ★頻出語型の人手判定(自動分類は真値を持つ%d件しか確定できないため):" %
      sum(1 for h in hits if h['cls'] == 'suspect'))
mc = collections.Counter()
for w, n in byword.most_common(40):
    if w in MANUAL:
        mc[MANUAL[w][0]] += n
for k in ('幸運', '準幸運', '準有害', '★有害'):
    if mc[k]:
        print("      %-6s %3d箇所" % (k, mc[k]))
print("      ※上位40語型のうち人手判定済 %d語型 / 未判定の残りは低頻度(各≤4箇所)" %
      sum(1 for w, n in byword.most_common(40) if w in MANUAL))
print("\n   ★有害と判定したもの(中国語として読むと全く別の意味になる):")
for w, n in byword.most_common(60):
    if w in MANUAL and MANUAL[w][0].startswith('★'):
        print("      %-6s ×%-3d %s" % (w, n, MANUAL[w][1]))

print("\n   頻出する偽友候補(語型・上位20):")
seen = {}
for h in sus:
    seen.setdefault(h['w'], []).append(h['it']['word'])
for w, n in byword.most_common(20):
    src = ' '.join(sorted(zh_src[w])[:2])
    print("      %-6s ×%-3d 例=%-26s 中国語での意味の出所=%s" % (w, n, seen[w][0][:26], src[:34]))

# ---------------------------------------------------------------- 実配信テキスト
print("\n" + "=" * 100)
print("■ C. ユーザー自身の配信テキストに実際に出ているか")
print("=" * 100)
body = []
for cp in CORPUS:
    if os.path.exists(cp):
        for line in io.open(cp, encoding='utf-8', errors='replace'):
            if line.startswith('#') or re.search(r'[ぁ-んァ-ヶ]', line):
                continue
            body.append(line)
text = ''.join(body)
plain = ''.join(c for c in text if not ismark(c))
found = collections.Counter()
for w in set(h['w'] for h in sus):
    n = plain.count(w)
    if n:
        found[w] = n
print("   本文中に現れた偽友候補の語型 = %d種 / 延べ %d回" % (len(found), sum(found.values())))
for w, n in found.most_common(15):
    print("      %-6s ×%-3d  (中国語の意味の出所: %s)" % (w, n, ' '.join(sorted(zh_src[w])[:2])[:40]))

# ---------------------------------------------------------------- 対照
print("\n" + "=" * 100)
print("■ D. 対照 — この程度の一致は偶然でも起きるのではないか")
print("=" * 100)
import random
allc = [c for it in items for c in it['surf'] if '一' <= c <= '鿿']
# ★set の反復順は実行ごとに変わる(文字列ハッシュのランダム化)。sorted で固定しないと
#   対照の値が再現しない(初版は 38 と 25 の間で揺れた)。さらに複数試行の平均を取る。
pool = sorted(set(allc))          # 対照A: 字種から一様抽出
freq_pool = sorted(allc)          # 対照B: ★出現頻度を保存(汎用字が出やすい=より厳しい対照)


def run_ctl(p, label):
    tr = []
    for seed in range(5):
        random.seed(20260801 + seed)
        shuf = [{'surf': ''.join(random.choice(p) if '一' <= c <= '鿿' else c for c in it['surf']),
                 'bnd': it['bnd'], 'marked': it['marked'], 'segs': it['segs'],
                 'head': it['head'], 'word': it['word']} for it in items]
        tr.append(len(find_hits(shuf, ZH)))
    a = sum(tr) / len(tr)
    print("   %-28s 平均%6.1f箇所 (5試行: %s) → lift %5.1f倍" %
          (label, a, tr, len(hits) / max(1.0, a)))
    return a


print("   実際 = %d箇所" % len(hits))
run_ctl(pool, "対照A 字種から一様抽出")
run_ctl(freq_pool, "対照B ★出現頻度を保存")
# 対照C: 第17レンズ方式=語根→漢字の割当表を巡回シフト(境界も語構造もそのまま)
kk = sorted(set(b for it in items for r, b in it['segs']))
OFF = 499
sub = {kk[i]: kk[(i + OFF) % len(kk)] for i in range(len(kk))}
shuf = []
for it in items:
    segs2 = [(r, sub.get(b, b)) for r, b in it['segs']]
    s = ''
    bnd = set()
    mk = set()
    for r, b in segs2:
        t = ''.join(c for c in b if not ismark(c))
        if any(ismark(c) for c in b):
            mk.add(len(s) + len(t))
        s += t
        bnd.add(len(s))
    bnd.discard(len(s))
    shuf.append({'surf': s, 'bnd': bnd, 'marked': mk, 'segs': segs2,
                 'head': it['head'], 'word': it['word']})
nc = len(find_hits(shuf, ZH))
print("   %-28s %6d箇所            → lift %5.1f倍" %
      ("対照C 割当表を巡回シフト", nc, len(hits) / max(1.0, nc)))
print("   ※liftが1に近いなら『漢字化したらこの程度は必ず起きる』構造的現象、")
print("     大きいなら割り当ての選び方が実在語を作りやすい方向に効いている。")

with io.open("_lens30_external_false_friends.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("種別\t実在語\t見出し語\t面\t最上位層\tマークで分断\t中国語の出所\n")
    for h in sorted(sus, key=lambda x: x['w']):
        f.write("偽友候補\t%s\t%s\t%s\t%s\t%s\t%s\n" %
                (h['w'], h['it']['word'], h['it']['surf'], tier_of_word(h['it']),
                 'Y' if h['brk'] else '', ' '.join(sorted(zh_src[h['w']])[:3])))
    for h in sorted(fel, key=lambda x: x['w']):
        f.write("幸運\t%s\t%s\t%s\t%s\t%s\t%s\n" %
                (h['w'], h['it']['word'], h['it']['surf'], tier_of_word(h['it']),
                 'Y' if h['brk'] else '', ' '.join(sorted(zh_src[h['w']])[:3])))
print("\n出力: _lens30_external_false_friends.tsv")
