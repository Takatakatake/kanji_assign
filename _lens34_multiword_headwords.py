# -*- coding: utf-8 -*-
# 第34レンズ「空白入り見出し = 歴代スクリプトが自分のフィルタで捨ててきた 9.8%」 (第27回続77)
#
#   ★空白の所在:
#     第33レンズを書いている最中に、複数語見出し `angl/a lingv/o⟦英/a 语/o⟧` の
#     分節の内側に空白が入るため 6,002 分節が静かに脱落するバグを踏んだ。
#     直したあとに気づいたのは、そのバグの原因である
#         if ' ' in raw: continue
#     という一行を【17本のスクリプトが書いている】ことだった:
#       _lens17 _lens18 _lens19 _lens21 _lens22 _lens23 _lens24 _lens24b _lens24c
#       _lens27 _lens29 _lens31 _lens32 _lens33
#       _audit_display_collisions.py _audit_mirror_gaps.py _audit_priority_tiers.py
#     語根同定の手続きとしては正しい(複数語見出しから語根を一意に取れない)が、
#     結果として **辞書の 9.8%(6,075 見出し) が全レンズから構造的に不可視** だった。
#     第31が第23の「定義による死角」を突いたのと同じ型の穴が、今度は測定側にあった。
#
#   測る量:
#     [A] 規模と、除外していた根拠
#     [B] 描画の完全性の分類(§7全大文字 / 完全 / 部分 / ゼロ)
#     [C] ★層別の完読率 — 第4レンズの指標を除外クラスで再現し、単調性が保たれるか
#     [D] ★固定形態素描画の破れ — 単語見出しで漢字が付く形態素が、複数語見出しで付かない箇所
#     [E] ZERO と PART の欠落成分の悉皆分類(§7固有名 / R4音訳禁止 / 真の穴)
#     [F] 先行レンズの結論への影響評価
import io, os, sys, csv as _csv, collections, unicodedata

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))

SIDE = "_identifier_sidecar.tsv"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
INJ = {'学習者版': "漢字注入_学習者版_20260620.txt", '学術版': "漢字注入_学術版_20260620.txt"}
# ★語尾は「その語の最後の分節」に限って文法語尾とみなす。
#   met/an/o の an は接尾辞(内容形態素)で、teren/on の on は対格語尾。位置で分かれる。
END = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn',
       'on', 'en', 'an', 'un'}
# 方針上ラテンが正しく、固定描画を持たない形態素
NOFIX = {'um', 'la', 'je', "l'", 'k'}
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
TIERS = ['文法層', 'CSV2890', 'PEJVO', 'PIV']


def is_cjk(c):
    return '一' <= c <= '鿿'


def strip_marks(s):
    return ''.join(c for c in s if unicodedata.category(c) not in ('Lm', 'Mn', 'Sk'))


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


# ================================================================
# 0. データ読み込み
# ================================================================
roots = {}
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    d = {'root': p[0], 'disp': p[4], 'band': p[5], 'F': int(p[6]) if p[6].isdigit() else 0}
    for k in {p[0], to_hsys(p[0]), to_hsys(p[0]).lower()}:
        roots.setdefault(k, d)

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
        while len(cs) > 1 and cs[-1] in END:
            cs.pop()
        if cs:
            bare2segs.setdefault(raw.replace('/', '').replace('-', '').lower(),
                                 [c.strip('-') for c in cs])
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


def tier_of_root(a):
    d = roots.get(a) or roots.get(to_hsys(a)) or roots.get(to_hsys(a).lower())
    if not d:
        return None
    if d['band'] in GRAMMAR:
        return '文法層'
    if d['root'] in csv_roots or to_hsys(d['root']).lower() in csv_roots:
        return 'CSV2890'
    if d['band'] == 'piv':
        return 'PIV'
    return 'PEJVO'


def parse(line):
    """見出しを (語, 大文字か, [(綴り, 描画)]) に割る。★語の内側の空白と分節を両方扱う"""
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')] if '⟦' in head else head
    box = head[head.index('⟦') + 1:head.rindex('⟧')] if '⟦' in head else raw
    rw, bw = raw.split(' '), box.split(' ')
    if len(rw) != len(bw):
        return None
    items = []
    for r, b in zip(rw, bw):
        cap = r[:1].isupper()
        rs = [x for x in r.split('/') if x]
        bs = [x for x in b.split('/') if x]
        if len(rs) != len(bs):
            return None
        for k, (a, c) in enumerate(zip(rs, bs)):
            if k == len(rs) - 1 and a in END:
                continue           # 語末の文法語尾
            items.append((a, c, cap))
    return raw, items


multi, single = [], []
for line in io.open(INJ['学習者版'], encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        continue
    pr = parse(line)
    if not pr:
        continue
    raw, items = pr
    if not items:
        continue
    (multi if ' ' in raw else single).append((line, raw, items))

# ★§7(固有名ラテン維持)の機械判定は語釈からは作れなかった(素朴な正規表現は 2,998 種を拾い
#   全語根の3割を「固有名」にしてしまう)。そこで【全体の控除には使わず】、
#   最後に残った未割当語根の分類にだけ、根拠の確かな一次判定として使う:
#     「同じ語根で大文字始まりの見出しが辞書に別に存在するか」(c^in→C^in/o, japan→Japan/uj/o)。
base_gloss, capheads = {}, set()
for line, raw, items in single:
    segs = [a for a, c, cap in items]
    if raw[:1].isupper() and segs:
        capheads.add(segs[0].lower())
    if len(segs) == 1:
        base_gloss.setdefault(segs[0], line.split(':', 1)[1])
        base_gloss.setdefault(segs[0].lower(), line.split(':', 1)[1])
PROPER7 = set()      # 全体控除には使わない(空のまま)

print("=" * 108)
print("■ 第34レンズ  空白入り見出し — 歴代スクリプトが自分のフィルタで捨ててきた層")
print("=" * 108)
print("学習者版 見出し %d / 単語見出し %d / ★空白入り見出し %d (%.1f%%)"
      % (len(multi) + len(single), len(single), len(multi),
         100.0 * len(multi) / (len(multi) + len(single))))
print("除外していたスクリプト: `if ' ' in raw: continue` を書いている 17 本")
print("  _lens17 _lens18 _lens19 _lens21 _lens22 _lens23 _lens24 _lens24b _lens24c")
print("  _lens27 _lens29 _lens31 _lens32 _lens33 / _audit_display_collisions"
      " _audit_mirror_gaps _audit_priority_tiers")
print("  ※語根同定の手続きとしては正しい。だが【評価】まで同じフィルタを通していた")

# ================================================================
# 1. [B] 描画の完全性
# ================================================================
print("\n" + "=" * 108)
print("■ [B] 描画の完全性 — 空白入り見出しはきちんと漢字化されているか")
print("=" * 108)


VOW = set('aeiou')


def policy_latin(a):
    """方針上ラテンが正しい成分。控除しないと『穴』を過大に数える"""
    s = a.rstrip('!?-')
    if not s or s in NOFIX or s in END:
        return True
    if len(s) == 1 and s in VOW:
        return True             # 連結母音(land/o/mez/o の o)
    if not any(ch.isalpha() for ch in s):
        return True             # 句読点だけの分節
    return s in PROPER7


def content_low(items, deduct=True):
    """§7判定=語頭大文字の語は丸ごとラテンが正。評価対象は小文字語の内容形態素だけ。
    deduct=True なら方針上ラテンが正しい成分(連結母音・§7小文字固有名)も控除する"""
    out = [(a, c) for a, c, cap in items if not cap and a not in NOFIX]
    if deduct:
        out = [(a, c) for a, c in out if not policy_latin(a)]
    return out


def classify(items):
    low = content_low(items)
    if not low:
        return 'ALLCAP'
    hit = sum(1 for a, c in low if any(is_cjk(x) for x in c))
    if hit == len(low):
        return 'OK'
    if hit == 0:
        return 'ZERO'
    return 'PART'


cc = collections.Counter()
byc = collections.defaultdict(list)
for line, raw, items in multi:
    k = classify(items)
    cc[k] += 1
    byc[k].append((line, raw, items))
n = len(multi)
print("  ALLCAP  全語が大文字始まり = §7固有名で丸ごとラテンが正   %5d (%.1f%%)" % (cc['ALLCAP'], 100.0 * cc['ALLCAP'] / n))
print("  OK      小文字語の内容形態素が全て漢字                    %5d (%.1f%%)" % (cc['OK'], 100.0 * cc['OK'] / n))
print("  PART    一部だけ漢字                                     %5d (%.1f%%)" % (cc['PART'], 100.0 * cc['PART'] / n))
print("  ZERO    小文字語なのに漢字ゼロ                            %5d (%.1f%%)" % (cc['ZERO'], 100.0 * cc['ZERO'] / n))
sc = collections.Counter(classify(it) for l, r, it in single)
print("\n  比較: 単語見出し %d では OK %.1f%% / PART %.1f%% / ZERO %.1f%% / ALLCAP %.1f%%"
      % (len(single), 100.0 * sc['OK'] / len(single), 100.0 * sc['PART'] / len(single),
         100.0 * sc['ZERO'] / len(single), 100.0 * sc['ALLCAP'] / len(single)))

# ================================================================
# 2. [C] ★層別の完読率 — 第4レンズの指標を除外クラスで再現する
# ================================================================
print("\n" + "=" * 108)
print("■ [C] ★層別の完読率 — 除外クラスと、歴代レンズが測ってきたクラスを【同一定義】で比べる")
print("       ※第4レンズの数値(CSV2890 98.8%>PEJVO 93.2%>PIV 79.5%)とは方針控除の規則が違うので")
print("         絶対値は比較しない。主張するのは同一定義での両クラスの相対差だけ")
print("=" * 108)


def entry_tier(items):
    """見出しの層 = 内容語根のうち最も下位(=稀)の層。未割当語根は層不明として無視"""
    ts = [tier_of_root(a) for a, c in content_low(items)]
    ts = [t for t in ts if t]
    if not ts:
        return None
    for t in reversed(TIERS):
        if t in ts:
            return t
    return None


def rate_table(rows, label):
    agg = collections.defaultdict(lambda: [0, 0])
    for line, raw, items in rows:
        if classify(items) == 'ALLCAP':
            continue                       # §7 は評価対象外
        t = entry_tier(items)
        if not t:
            continue
        agg[t][0] += 1
        if classify(items) == 'OK':
            agg[t][1] += 1
    print("  %s" % label)
    for t in TIERS:
        a, b = agg[t]
        if a:
            print("    %-8s %6d 見出し / 完読 %6d = %6.2f%%" % (t, a, b, 100.0 * b / a))
    tot = sum(v[0] for v in agg.values())
    hit = sum(v[1] for v in agg.values())
    print("    %-8s %6d 見出し / 完読 %6d = %6.2f%%" % ('全体', tot, hit, 100.0 * hit / max(tot, 1)))
    return agg


am = rate_table(multi, "★空白入り見出し(これまで不可視だった層):")
print()
asg = rate_table(single, "参考: 単語見出し(歴代レンズが測ってきた層):")

# ================================================================
# 3. [D] ★固定形態素描画の破れ
# ================================================================
print("\n" + "=" * 108)
print("■ [D] ★固定形態素描画の破れ — 単語見出しでは漢字が付く形態素が、複数語見出しで付かないか")
print("=" * 108)
sing_hit = collections.defaultdict(lambda: [0, 0])
for line, raw, items in single:
    for a, c in content_low(items):
        sing_hit[a][0 if any(is_cjk(x) for x in c) else 1] += 1
mult_hit = collections.defaultdict(lambda: [0, 0])
where = collections.defaultdict(list)
for line, raw, items in multi:
    for a, c in content_low(items):
        ok = any(is_cjk(x) for x in c)
        mult_hit[a][0 if ok else 1] += 1
        if not ok:
            where[a].append(line)
brk = [(m[1], a, m[0], sing_hit[a][0]) for a, m in mult_hit.items()
       if m[1] > 0 and sing_hit.get(a, [0, 0])[0] > 0]
brk.sort(reverse=True)
print("破れ候補 %d 形態素 / 延べ %d 箇所 — ★全件を目視する" % (len(brk), sum(b[0] for b in brk)))
# 人手判定(再現可能なようにスクリプトへ焼き込む)
DVERDICT = {
    'a': '○語中の形容詞語尾(dau^r/a/foli/a=続a叶a)。語末でないだけで文法語尾',
    'log': '○homo/log/aj は ##偽分解 で 同ᴴ が意味を担う。log は偽分解の残余',
    'in': '○tuberkul/in・fibr/in の -in- は化学の接尾辞。女ᴺ(-in-)と同綴の別物で、ラテン維持が正しい',
    'al': '○ton/al/o は ##偽分解。调 が意味を担う',
    'an': '○met/an/o・okt/an/o は ##偽分解(PIV正式分解)。甲・辛 が意味を担う',
    'en': '○lau^/en/spez/a の en は enspez(収入)の一部',
    'roman': '○roman/a cifer/o は [O]監査で是正済(小说→ラテン維持)。ローマ数字を「小説の数字」と描かないため',
    'tio': '○相関詞 tio は単語見出しでも 15/16 がラテン。一貫している',
    'pro': '○pro/cent/o は 百 が意味を担う。§14.2.1 の promil 裁定と同じ扱い',
    'or': '○konvert/or/o は ##過細分解。转ᴷ が意味を担う',
    'pol': '○pol/a=ポーランド。§7 固有名由来の小文字形容詞',
}
print("  %-10s %6s %6s %6s  判定" % ("形態素", "複数:無", "複数:有", "単語:有"))
vc = collections.Counter()
for m, a, h, sh in brk:
    v = DVERDICT.get(a, '(未判定)')
    vc['○' if v.startswith('○') else '★'] += m
    print("  %-10s %6d %6d %6d  %s" % (a, m, h, sh, v))
print("\n  → 判定: 正当 %d 箇所 / 要是正 %d 箇所" % (vc['○'], vc['★']))

# ================================================================
# 4. [E] ZERO / PART の欠落成分の悉皆分類
# ================================================================
print("\n" + "=" * 108)
print("■ [E] 漢字が付かない成分の悉皆分類")
print("=" * 108)
print("★ZERO %d 件(全件):" % cc['ZERO'])
for line, raw, items in byc['ZERO']:
    miss = [a for a, c in content_low(items) if not any(is_cjk(x) for x in c)]
    print("   %-32s 落=%-20s %s" % (raw, ','.join(miss), line.split(':', 1)[1][:42]))
unassigned = collections.Counter()
for a, ws in where.items():
    if sing_hit.get(a, [0, 0])[0] == 0:
        unassigned[a] += len(ws)
print("\n★PART/ZERO で落ちている『どこでも漢字が付かない語根』= %d 種 / 延べ %d 箇所"
      % (len(unassigned), sum(unassigned.values())))
# ★一次分類は【辞書のデータ】で行う: 同じ語根の大文字始まり見出しが別に在れば §7 固有名。
#   c^in→C^in/o・japan→Japan/uj/o・zulu→Zul/o・sovet→Sovet/uni/o。手作業リストは使わない。
pr = sum(v for a, v in unassigned.items() if a.lower() in capheads)
prk = sorted((a for a in unassigned if a.lower() in capheads))
rest = [(v, a) for a, v in unassigned.items() if a.lower() not in capheads]
rest.sort(reverse=True)
print("   §7固有名(同じ語根の大文字見出しが辞書に在る) : %3d 箇所 / %d 種" % (pr, len(prk)))
print("      " + ' '.join(prk[:40]))
print("   ★その他(=要目視)                            : %3d 箇所 / %d 種"
      % (sum(v for v, a in rest), len(rest)))
print("   ★その他 全件(語釈つき):")
for v, a in rest:
    g = base_gloss.get(a) or base_gloss.get(a.lower()) or '(単独見出し無し)'
    print("      %-14s %2d回  %s" % (a, v, g[:62]))
with io.open("_lens34_multiword_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("分類\t見出し\t落ちている成分\t語釈\n")
    for k in ('ZERO', 'PART'):
        for line, raw, items in byc[k]:
            miss = [a for a, c in content_low(items) if not any(is_cjk(x) for x in c)]
            f.write("%s\t%s\t%s\t%s\n" % (k, raw, ','.join(miss), line.split(':', 1)[1][:80]))
print("\n  ZERO/PART 全 %d 件を _lens34_multiword_ledger.tsv に出力" % (cc['ZERO'] + cc['PART']))

# ================================================================
# 5. [F] 先行レンズの結論への影響
# ================================================================
print("\n" + "=" * 108)
print("■ [F] 除外は先行レンズの結論を変えたか")
print("=" * 108)
mo = sum(1 for l, r, it in multi if classify(it) == 'OK')
ma = sum(1 for l, r, it in multi if classify(it) != 'ALLCAP')
so = sum(1 for l, r, it in single if classify(it) == 'OK')
sa = sum(1 for l, r, it in single if classify(it) != 'ALLCAP')
# ★[C]と母集団を必ず揃える(第25/第32と同型の分子分母バグを避ける)。
# [C] は entry_tier が取れない見出し(内容語根が全て未割当)を落としていたので、
# ここでも同じ母集団を使い、落とした件数を明示する。
mt = sum(v[0] for v in am.values())
mh = sum(v[1] for v in am.values())
st = sum(v[0] for v in asg.values())
sh = sum(v[1] for v in asg.values())
drop_m = ma - mt
drop_s = sa - st
print("完読率(=[C]と同一母集団)  空白入り %.2f%% (%d/%d)  vs  単語見出し %.2f%% (%d/%d)"
      % (100.0 * mh / mt, mh, mt, 100.0 * sh / st, sh, st))
print("  ※母集団から外した『内容語根が全て未割当で層が定まらない見出し』= 空白入り %d 件 / 単語 %d 件"
      % (drop_m, drop_s))
print("  これを全て不完読として足し戻すと 空白入り %.2f%% / 単語見出し %.2f%%"
      % (100.0 * mh / (mt + drop_m), 100.0 * sh / (st + drop_s)))
print("両方を合わせた辞書全体の完読率 = %.2f%% (%d/%d)"
      % (100.0 * (mh + sh) / (mt + st), mh + sh, mt + st))

# ★[C]で CSV2890 層だけ 4pt 低かった理由の分解
bad = [(l, r, it) for l, r, it in multi
       if classify(it) != 'ALLCAP' and entry_tier(it) == 'CSV2890' and classify(it) != 'OK']
only7 = sum(1 for l, r, it in bad
            if all(a.lower() in capheads for a, c in content_low(it) if not any(is_cjk(x) for x in c)))
print("\n★[C]で CSV2890 層の空白入りが単語見出しより低かった差の分解:")
print("   完読でない CSV2890 の空白入り見出し %d 件のうち、落ちているのが §7固有名だけ = %d 件 (%.1f%%)"
      % (len(bad), only7, 100.0 * only7 / max(len(bad), 1)))
print("   → §7 を控除すれば CSV2890 の完読率は %.2f%% (=%d/%d) で単語見出しと同水準になる"
      % (100.0 * (am['CSV2890'][1] + only7) / am['CSV2890'][0],
         am['CSV2890'][1] + only7, am['CSV2890'][0]))

# ★除外は「完読率」以外の指標にも効いたか = 空白入りにしか現れない配信面はあるか
sw = set()
for line, raw, items in single:
    head = line.split(':', 1)[0]
    if '⟦' in head:
        sw.add(strip_marks(head[head.index('⟦') + 1:head.rindex('⟧')]).replace('/', ''))
mw, only_m = set(), set()
for line, raw, items in multi:
    head = line.split(':', 1)[0]
    if '⟦' not in head:
        continue
    for w in strip_marks(head[head.index('⟦') + 1:head.rindex('⟧')]).split(' '):
        w = w.replace('/', '')
        if not any(is_cjk(c) for c in w):
            continue
        mw.add(w)
        if w not in sw:
            only_m.add(w)
print("\n★除外が『完読率以外』にも効いたか = 空白入り見出しにしか現れない語面(配信面)の数")
print("   空白入りに現れる漢字入り語面 %d 種 / ★うち単語見出しに一度も現れない = %d 種 (%.1f%%)"
      % (len(mw), len(only_m), 100.0 * len(only_m) / max(len(mw), 1)))
print("   例: " + ' '.join(sorted(only_m)[:20]))
print("   → これは無視できる数ではない。第23(近傍衝突)・第26(分節一意性)は【語面】を単位に")
print("      しているので、この 1,000 超の語面は一度も衝突検査を受けていない。実際に検査する:")
# ★新規語面どうしの衝突を実測する。
#   ここで識別子(上付き)を剥がしてはいけない——衝突を解消しているのが識別子そのものなので、
#   剥がしてから数えると自分で作った衝突を数えることになる(第9レンズ=識別子が同形異義の99.9%を解消)。
def wsurf(head, strip):
    rws = head[:head.index('⟦')].split(' ')
    inner = head[head.index('⟦') + 1:head.rindex('⟧')]
    bws = (strip_marks(inner) if strip else inner).split(' ')
    return list(zip(rws, bws)) if len(rws) == len(bws) else []


for strip, lab in ((False, '識別子つき=実際の配信面'), (True, '識別子を剥がした面(参考)')):
    s2r = collections.defaultdict(set)
    for line, raw, items in multi:
        head = line.split(':', 1)[0]
        if '⟦' not in head:
            continue
        for rr, bb in wsurf(head, strip):
            s = bb.replace('/', '')
            if any(is_cjk(c) for c in s):
                s2r[s].add(rr.replace('/', ''))
    novel = {s for s in s2r if strip_marks(s) in only_m} if strip else \
            {s for s in s2r if strip_marks(s) in only_m}
    col = [(s, v) for s, v in s2r.items() if s in novel and len(v) > 1]
    print("      [%s] 新規語面のうち、綴りの違う2語以上が同じ面になるもの = %d 種" % (lab, len(col)))
    if not strip:
        for s, v in sorted(col)[:16]:
            print("        %-16s ← %s" % (s, ' / '.join(sorted(v))))

print("\n" + "=" * 108)
print("■ 総括")
print("=" * 108)
print("""1. 穴は実在した。辞書の 9.8%(6,075 見出し)が 17 本のスクリプトの
   `if ' ' in raw: continue` によって全レンズから構造的に不可視だった。
   語根同定の手続きとしては正しい一行が、【評価】の母集団まで削っていた。

2. ★だが中身は健全だった。小文字語の内容形態素が全て漢字 = 89.8%、
   一部だけ = 4.3%、ゼロ = 6 件(0.1%)。ゼロ 6 件は全て §7 固有名 + 未割当語根の組合せ。

3. ★固定形態素描画の破れはゼロ。単語見出しでは漢字が付く形態素が複数語見出しで
   付かない箇所は 8 形態素 14 箇所しかなく、全件目視した結果すべて正当だった:
   ##偽分解(homo/log・ton/al・met/an・okt/an)、##過細分解(konvert/or)、
   化学の -in-(tuberkul/in は女ᴺ と同綴の別物でラテン維持が正しい)、
   §14.2.1 の既存裁定(pro/cent の pro)、[O]監査で是正済(roman/a cifer/o)、§7(pol/a)。

4. ★層別の完読率は、同一定義で測ると 空白入り 95.40% / 単語見出し 97.28%。
   CSV2890 層だけ 4.0pt 低い(94.81% vs 98.79%)が、その差の実体は
   `c^in/a lingv/o` 型の【§7 国名・言語名形容詞】で、控除すれば同水準になる。

5. ★残差の『真の穴』候補 66 種を全件出したが、自然な字が一级3500 に無い:
   颚(顎)・腭・鳃(えら)・楔(くさび)・醚(エーテル)・酯・醛・轭(共役)・疝(ヘルニア)
   はいずれも一级3500 の外。makzel/brank/kojn/eter/konjug/herni が未割当なのは
   優先順位の怠りではなく【方針 R2 の字表制約】で、第33レンズと同じ構造。
   (化学の 醚/酯/醛 が使えないことが、甲乙丙基システムを採る理由そのものでもある)

6. ★除外は「完読率」以外にも効いていた。空白入り見出しにしか現れない配信語面が
   1,071 種(この層の語面の 24.3%)あり、第23(近傍衝突)・第26(分節一意性)は
   これらを一度も検査していない。そこで本レンズで実際に検査したところ、
   【識別子つきの実際の配信面では衝突 0 種】。識別子を剥がすと 16 種(战on←batalon/militon,
   数oj←ciferoj/nombroj, 议on←konsilon/parlamenton …)出るので、
   この層でも §9 識別子機構が現に効いていることが確認できた。

★是正 0 件。データは一切変更していない。""")
print("=" * 108)
print("■ この測定の限界(先に開示する)")
print("=" * 108)
print("""a. §7 の一次判定「同じ語根の大文字始まり見出しが辞書に在るか」は辞書の収録方針に
   依存する近似。語釈からの機械抽出も試したが、素朴な正規表現は 2,998 種(全語根の約3割)を
   拾ってしまい使えなかったので、全体の控除には一切使わず残差の分類にだけ使った。
b. 完読率の絶対値は第4レンズと控除規則が違うので直接比較しない。
   本レンズは【同一定義で両クラスを測った相対比較】だけを主張する。
c. PIV 層の空白入り見出しは 5 件しかなく、層間比較に耐えない(参考値)。
d. 測ったのは学習者版のみ。学術版の空白入り見出しは別途。
e. 除外の影響は「完読率」と「語面の新規性」の 2 指標でしか評価していない。""")
