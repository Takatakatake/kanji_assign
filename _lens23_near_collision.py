# -*- coding: utf-8 -*-
# 第23レンズ「近傍衝突 — 最重要語ほど見分けやすいか」 2026-07-28
#
#   これまでの22レンズは「読めるか(被覆・完読・接地・実文シェア)」を測ってきた。
#   しかし読字には第二の失敗様式がある: **読めるが、別の語と取り違える**。
#   第9レンズ「一意性」は語根の *割り当ての一意性* を測ったが、
#   **語の描画面どうしがどれだけ近いか** は一度も測っていない。
#
#   ★優先順位との関係:
#     優先順位が効いているなら、**最重要語ほどよく分離されている** はずである。
#     最優先層に混同対が集中しているなら、優先順位は「割り当ての順序」には
#     効いていても「割り当ての質」には効いていないことになる。
#
#   ★測る単位 = 内容形態素列(レキシーム)。abism/a と abism/o は同一レキシーム。
#     語尾(o/a/e/i/as…)は全語共通で識別に寄与しないため面から除く
#     (=語尾を含めれば衝突は減るので、本レンズの評価は **保守側**)。
#
#   ★初版の誤りと訂正(2026-07-28):
#     初版は素の編集距離1で近傍を定義し、**識別子(ᴬ ᵀ ˢ …)を1文字として数えて**
#     いたため「厌ᴬ ⇔ 订ᴬ」のような、共有しているのが識別子だけの対を
#     近傍と誤判定していた。識別子は内容文字ではなく曖昧性解消の付加情報なので、
#     **編集距離は識別子を外した漢字列の上で測り、識別子は属性として扱う**。
#     また2字語どうしの1字違い(共有率50%)は CJK では実用上区別できるため、
#     危険とはみなさず参考値に留める(電車/電話 を混同する読者はいない)。
#
#   ★CJKの読み面に即した3つの混同類型で測る:
#     類型1 完全衝突  … 漢字列が完全に一致する別レキシーム(1字面も含む)。
#                       識別子で解決済みか否かを分け、さらに未解決分を
#                       **同義(=衝突しても害が無い)** と **異義(=真の曖昧)** に分ける。
#                       同義対(fontano/s^prucfonto→喷泉)を欠陥に数えると誤警報になる
#     類型2 転置衝突  … 同じ文字の集合で並びだけ違う(学科/科学型)。CJKでは実際に混同される
#     類型3 高重複近傍… 1字違いで長さ3以上(=2/3以上を共有)。重なりが実質的に高い対
#
#   ★対照群を2つ置く(第21レンズの方法論を継承):
#     対照A = 同じ語集合の **ラテン綴り面**。漢字化が新たに生んだ衝突だけを取り出す
#     対照B = 形態素→漢字列 の割り当てを **長さを保って無作為に入れ替えた** 面(5回平均)
#             実際の割り当てが偶然より良いか悪いかを測る
#
# 出力: _lens23_near_collision.tsv / _lens23_risk_pairs.tsv + stdout要約
import io, os, re, sys, csv as _csv, collections, random

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = "漢字注入_学習者版_20260620.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
LEARN = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
PEJVO_END, SUPL_END = 44104, 44440
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us',
           'o', 'a', 'e', 'i', 'u', 'j', 'n']
ENDSET = set(ENDINGS)
# ★語末から剥がしてよい語尾。an/en/on は接尾辞 -an-(員)・-on-(分数)・前置詞 en(内) と
#   同綴りなので **除外する**。含めると met/an/o(甲=メタン) が met(置) と同一視され、
#   「meti と kirasi がどちらも 甲 で衝突」のような偽の衝突が出る。
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
SEP = re.compile(r'[/ ]')


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def is_cjk(c):
    return '一' <= c <= '鿿'


def strip_id(s):
    """識別子(CJK以外の上付き記号)を落として漢字列だけにする"""
    return ''.join(c for c in s if is_cjk(c))


# ---------- 1. 層の判定材料 ----------
csv_words = set()
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if rec and rec[0].strip():
            for t in rec[0].split(','):
                t = to_hsys(t.strip())
                if t:
                    csv_words.add(t)

word_line = {}
with io.open(LEARN, encoding='utf-8-sig') as f:
    for n, line in enumerate(f, 1):
        if ':' not in line:
            continue
        head = line.split(':', 1)[0].strip()
        if not head or head.startswith('#'):
            continue
        bare = head.replace('/', '').replace(' ', '')
        if bare and bare not in word_line:
            word_line[bare] = n


def word_tier(bare):
    if bare in csv_words:
        return 0                      # CSV2890(最優先)
    n = word_line.get(bare)
    if n is None:
        return 3
    return 1 if n <= SUPL_END else 2  # PEJVO本体+追補 / PIV


TN = {0: 'CSV2890', 1: 'PEJVO', 2: 'PIV', 3: '辞書外'}

# ---------- 2. レキシーム(内容形態素列) → 漢字面 / ラテン面 / 層 ----------
lex = {}
morph_kanji = {}
for line in io.open(INJ, encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        continue
    head, gloss = line.split(':', 1)
    if '⟦' in head:
        raw = head[:head.index('⟦')]
        disp = head[head.index('⟦') + 1:head.rindex('⟧')]
    else:
        raw, disp = head, head
    if ' ' in raw:                       # 句見出しは除外
        continue
    segs, disps = SEP.split(raw), SEP.split(disp)
    if len(segs) != len(disps):
        continue
    bare = raw.replace('/', '')
    # ★2026-07-28: 語尾は **語末にしか現れない**。集合判定で全位置から落とすと
    #   en/ig/i の en(内)・an/ar/o の an(員)・ajn/ist/o の ajn が語尾と誤判定されて消え、
    #   「enigi と -ig- がどちらも 使 で衝突」のような偽の衝突が量産される。
    #   (第22レンズで前置詞 en を落としていたのと同じ種類の誤り)
    #   → 末尾から連続する語尾だけを剥がす。全部剥がれる語(en など)は原形を残す。
    cs, cd = list(segs), list(disps)
    while len(cs) > 1 and cs[-1] in ENDPOP:
        cs.pop()
        cd.pop()
    cs2, cd2 = [], []
    for s, d in zip(cs, cd):
        if s:
            cs2.append(s)
            cd2.append(d)
    cs, cd = cs2, cd2
    if not cs:
        continue
    key = tuple(cs)
    t = word_tier(bare)
    if key in lex:
        lex[key]['gloss'] += ' ' + gloss
        if t < lex[key]['tier']:
            lex[key]['tier'] = t
            lex[key]['sample'] = bare
        continue
    lex[key] = {'disp': ''.join(cd), 'latin': ''.join(cs), 'tier': t, 'sample': bare,
                'gloss': gloss,
                'kanji': all(any(is_cjk(c) for c in d) for d in cd)}
    for s, d in zip(cs, cd):
        if s not in morph_kanji and any(is_cjk(c) for c in d):
            morph_kanji[s] = strip_id(d)

pure = {k: v for k, v in lex.items() if v['kanji']}
keys_all = list(pure.keys())
surf = {k: strip_id(pure[k]['disp']) for k in keys_all}      # ★漢字列のみ(識別子は外す)
surf_full = {k: pure[k]['disp'] for k in keys_all}           # 識別子つきの正式な面
surf_lat = {k: pure[k]['latin'] for k in keys_all}           # 対照A
keys = [k for k in keys_all if len(surf[k]) >= 2]            # 類型2/3の母集団

print("=" * 100)
print("第23レンズ「近傍衝突 — 最重要語ほど見分けやすいか」")
print("=" * 100)
print("  レキシーム(内容形態素列) 総数 = %s / 全内容形態素が漢字描画 = %s (%.1f%%)"
      % (format(len(lex), ','), format(len(pure), ','), 100.0 * len(pure) / len(lex)))
print("  類型1(完全衝突)の母集団 = %s 全件 / 類型2・3の母集団 = %s (漢字2字以上)"
      % (format(len(keys_all), ','), format(len(keys), ',')))

# ---------- 面の長さの層別分布 ----------
print("\n■ 描画面の長さは層ごとにどう違うか(短いほど日常語として good)")
print("   %-10s %9s %8s %8s %8s %8s %8s" % ("層", "レキシーム", "平均字数", "1字", "2字", "3字", "4字以上"))
_len_by_tier = collections.defaultdict(list)
for k in keys_all:
    _len_by_tier[pure[k]['tier']].append(len(surf[k]))
for t in (0, 1, 2, 3):
    v = _len_by_tier[t]
    if not v:
        continue
    n = len(v)
    print("   %-10s %9s %8.2f %7.1f%% %7.1f%% %7.1f%% %7.1f%%"
          % (TN[t], format(n, ','), sum(v) / n,
             100.0 * sum(1 for x in v if x == 1) / n, 100.0 * sum(1 for x in v if x == 2) / n,
             100.0 * sum(1 for x in v if x == 3) / n, 100.0 * sum(1 for x in v if x >= 4) / n))


# ---------- 3. 3つの混同類型を列挙 ----------
def analyze_surface(keys, S, keys_exact=None):
    """類型1 完全衝突 / 類型2 転置衝突 / 類型3 高重複近傍(1字違い・長さ3以上) を数える"""
    exact, transp, near = [], [], []
    bykey = collections.defaultdict(list)
    for k in (keys_exact if keys_exact is not None else keys):
        bykey[S[k]].append(k)
    for s, ks in bykey.items():
        if len(ks) > 1000:             # 病的に大きい群は総当たりを避ける(実測では発生しない)
            print("   [警告] 完全一致群が %d 件と巨大なため対の列挙を省略: %s" % (len(ks), s))
            continue
        for i in range(len(ks)):
            for j in range(i + 1, len(ks)):
                exact.append((ks[i], ks[j]))
    byset = collections.defaultdict(list)
    for k in keys:
        byset[''.join(sorted(S[k]))].append(k)
    for _, ks in byset.items():
        if len(ks) < 2 or len(ks) > 200:
            continue
        for i in range(len(ks)):
            for j in range(i + 1, len(ks)):
                if S[ks[i]] != S[ks[j]]:
                    transp.append((ks[i], ks[j]))
    # 類型3: 長さ3以上に限定した削除近傍法
    buckets = collections.defaultdict(list)
    for k in keys:
        s = S[k]
        if len(s) < 3:
            continue
        buckets[s].append(k)
        for i in range(len(s)):
            buckets[s[:i] + s[i + 1:]].append(k)
    seen = set()
    for _, ks in buckets.items():
        if len(ks) < 2 or len(ks) > 400:
            continue
        for i in range(len(ks)):
            for j in range(i + 1, len(ks)):
                a, b = ks[i], ks[j]
                pk = (a, b) if a < b else (b, a)
                if pk in seen:
                    continue
                sa, sb = S[a], S[b]
                if sa == sb or abs(len(sa) - len(sb)) > 1:
                    continue
                if len(sa) == len(sb):
                    if sum(1 for x, y in zip(sa, sb) if x != y) != 1:
                        continue
                else:
                    lo, hi = (sa, sb) if len(sa) < len(sb) else (sb, sa)
                    if len(lo) < 3 or not any(hi[:i] + hi[i + 1:] == lo for i in range(len(hi))):
                        continue
                seen.add(pk)
                near.append((a, b))
    return exact, transp, near


def _lcs(x, y):
    """最長共通部分文字列の長さ"""
    if not x or not y:
        return 0
    prev = [0] * (len(y) + 1)
    best = 0
    for i in range(1, len(x) + 1):
        cur = [0] * (len(y) + 1)
        xi = x[i - 1]
        for j in range(1, len(y) + 1):
            if xi == y[j - 1]:
                cur[j] = prev[j - 1] + 1
                if cur[j] > best:
                    best = cur[j]
        prev = cur
    return best


def share_morph(a, b):
    """形態論的に関係があるか。
    ★2026-07-28: 形態素の一致だけで判定すると **偽分解(未分解)の見出し** を取りこぼす。
      imperialismo は 1分節のまま 帝主义 と描かれるので、femin/ism/o と 主义 を
      共有していても『形態素を共有しない＝恣意的』と誤分類されていた。
      decembro/novembro(十二月/十一月) も同様。
      → ラテン綴りどうしが4文字以上の共通部分文字列を持てば(=ismo, -embro など)
        隠れた接辞を共有しているとみなし、系統的に分類する。"""
    if set(a) & set(b):
        return True
    return _lcs(''.join(a), ''.join(b)) >= 4


E, T, N = analyze_surface(keys, surf, keys_exact=keys_all)
# 識別子で解決されているか
E_unres = [(a, b) for a, b in E if surf_full[a] == surf_full[b]]
T_arb = [(a, b) for a, b in T if not share_morph(a, b)]
N_arb = [(a, b) for a, b in N if not share_morph(a, b)]


# ---------- 未解決の完全衝突を 同義 / 異義 に分ける ----------
CJKRUN = re.compile(r'[一-鿿ぁ-ゖァ-ヺー]+')
XREF = re.compile(r'[=＝>＞]{1,2}\s*([A-Za-z^]+)')


def gloss_terms(g):
    g = re.sub(r'【[^】]*】', '', g)
    return set(t for t in CJKRUN.findall(g) if len(t) >= 2)


def syn_kind(a, b):
    """同義と判定できる根拠を返す。'' なら異義の可能性あり(要確認)"""
    sa, sb = pure[a]['sample'], pure[b]['sample']
    # ① 同一形態素の別見出し。接辞見出しは -ec- のようにハイフン付きで書かれるので、
    #    ハイフンを外して比べないと -ec- と eco が別物に見えてしまう。
    #    固定形態素描画の原則により、この対が同じ面を持つのは **設計どおり** で衝突ではない。
    na = tuple(sorted(x.strip('-') for x in a))
    nb = tuple(sorted(x.strip('-') for x in b))
    if na == nb or sa.strip('-') == sb.strip('-'):
        return '同一形態素の別見出し'
    # ② 相互参照(=X / >>X)
    ga, gb = pure[a]['gloss'], pure[b]['gloss']
    ra = set(x.lower() for x in XREF.findall(ga))
    rb = set(x.lower() for x in XREF.findall(gb))
    for s, r in ((sb, ra), (sa, rb)):
        for x in r:
            if x.startswith(s[:max(4, len(s) - 2)]) or s.startswith(x[:max(4, len(x) - 2)]):
                return '相互参照(=/>>)'
    # ③ 訳語の重なり
    ta, tb = gloss_terms(ga), gloss_terms(gb)
    if ta and tb and len(ta & tb) / min(len(ta), len(tb)) >= 0.34:
        return '訳語が重複'
    return ''


E_syn, E_amb = [], []
for a, b in E_unres:
    kind = syn_kind(a, b)
    (E_syn if kind else E_amb).append((a, b, kind))

print("\n" + "=" * 100)
print("■ 3つの混同類型(全体)")
print("   類型1 完全衝突      %6d 対  → 識別子で解決済み %d 対 / 未解決 %d 対"
      % (len(E), len(E) - len(E_unres), len(E_unres)))
print("        ★識別子層は完全衝突の %.1f%% を解消している" % (100.0 * (len(E) - len(E_unres)) / max(1, len(E))))
_c1 = collections.Counter(surf[k] for k in keys_all)
_c2 = collections.Counter(surf_full[k] for k in keys_all)
_b1 = sum(1 for k in keys_all if _c1[surf[k]] > 1)
_b2 = sum(1 for k in keys_all if _c2[surf_full[k]] > 1)
print("        レキシーム単位で見ると: 漢字列だけでは %s 件(%.1f%%)が他と同一面 →"
      % (format(_b1, ','), 100.0 * _b1 / len(keys_all)))
print("        識別子を付けた正式な面では %s 件(%.2f%%)だけが残る" % (format(_b2, ','), 100.0 * _b2 / len(keys_all)))
print("        未解決 %d 対の内訳: 同義で無害 %d 対 / **異義の可能性 %d 対**"
      % (len(E_unres), len(E_syn), len(E_amb)))
print("   類型2 転置衝突      %6d 対  うち形態素を共有しない(恣意的) %d 対" % (len(T), len(T_arb)))
print("   類型3 高重複近傍    %6d 対  うち形態素を共有しない(恣意的) %d 対" % (len(N), len(N_arb)))
print("        (1字違い・長さ3以上=2/3以上共有。2字語どうしの1字違いは共有率50%で")
print("         CJKでは実用上区別できるため危険とみなさない。参考値は後段)")

# ---------- 4. 層別 ----------
nA = collections.Counter()   # 類型1の分母(全レキシーム)
n2 = collections.Counter()   # 類型2/3の分母(2字以上)
for k in keys_all:
    nA[pure[k]['tier']] += 1
for k in keys:
    n2[pure[k]['tier']] += 1
hit = {'amb': collections.defaultdict(set), 'transp': collections.defaultdict(set),
       'near': collections.defaultdict(set)}
for nm, pairs in (('amb', [(a, b) for a, b, _ in E_amb]), ('transp', T_arb), ('near', N_arb)):
    for a, b in pairs:
        hit[nm][pure[a]['tier']].add(a)
        hit[nm][pure[b]['tier']].add(b)

print("\n■ ★層別の危険度(その層のレキシーム全件を分母に。1字面は転置も高重複も構造的に起こり得ない")
print("     ＝『短い面をもらえること』自体が保護なので、分母から外さず一緒に数えるのが正しい)")
print("   %-9s %8s %16s %16s %16s"
      % ("層", "全件", "異義の完全衝突", "恣意的な転置", "恣意的な高重複"))
for t in (0, 1, 2, 3):
    if not nA[t]:
        continue
    n = nA[t]
    print("   %-9s %8s  %4d (%5.2f%%)  %4d (%5.2f%%)  %4d (%5.2f%%)"
          % (TN[t], format(n, ','),
             len(hit['amb'][t]), 100.0 * len(hit['amb'][t]) / n,
             len(hit['transp'][t]), 100.0 * len(hit['transp'][t]) / n,
             len(hit['near'][t]), 100.0 * len(hit['near'][t]) / n))
print("\n   (参考)漢字2字以上のレキシームだけに絞った条件付き率 — 効果が『面の短さ』を")
print("          経由していることを見るための副次表。CSV2890 は 2字以上が %d 件しか無く小標本" % n2[0])
print("   %-9s %8s %16s %16s" % ("層", "2字以上", "恣意的な転置", "恣意的な高重複"))
for t in (0, 1, 2, 3):
    if not n2[t]:
        continue
    m = n2[t]
    print("   %-9s %8s  %4d (%5.2f%%)  %4d (%5.2f%%)"
          % (TN[t], format(m, ','),
             len(hit['transp'][t]), 100.0 * len(hit['transp'][t]) / m,
             len(hit['near'][t]), 100.0 * len(hit['near'][t]) / m))

# ---------- 5. 対照A: ラテン綴り面 ----------
lE, lT, lN = analyze_surface(keys, surf_lat, keys_exact=keys_all)
print("\n■【対照A】同じ語集合のラテン綴り面(漢字化前の状態)")
print("   完全衝突 %d 対 / 転置衝突 %d 対 / 高重複近傍 %d 対"
      % (len(lE), len(lT), len(lN)))
print("   → 漢字化で **新たに生じた** 完全衝突 = %d 対(うち識別子未解決 %d 対)"
      % (len(E) - len(lE), len(E_unres)))
print("   ※ ラテン面は平均 %.1f 文字、漢字面は平均 %.1f 文字。面が短いほど衝突しやすいのは"
      % (sum(len(surf_lat[k]) for k in keys) / len(keys), sum(len(surf[k]) for k in keys) / len(keys)))
print("      構造的な性質であり、この比較は『漢字化が衝突を増やすか』ではなく")
print("      『増えた分が識別子で処理されているか』を見るためのものである")

# ---------- 6. 対照B: 無作為割り当て ----------
bylen = collections.defaultdict(list)
for m, s in morph_kanji.items():
    bylen[len(s)].append(s)
rnd = random.Random(20260728)
acc = collections.Counter()
TRIALS = 5
for _ in range(TRIALS):
    pool = {L: v[:] for L, v in bylen.items()}
    for L in pool:
        rnd.shuffle(pool[L])
    idx = collections.Counter()
    shuf = {}
    for m, s in morph_kanji.items():
        L = len(s)
        shuf[m] = pool[L][idx[L]]
        idx[L] += 1
    sf, ok, okA = {}, [], []
    for k in keys_all:
        try:
            sf[k] = ''.join(shuf[s] for s in k)
        except KeyError:
            continue
        okA.append(k)
        if len(sf[k]) >= 2:
            ok.append(k)
    rE, rT, rN = analyze_surface(ok, sf, keys_exact=okA)
    acc['E'] += len(rE)
    acc['T'] += len([p for p in rT if not share_morph(*p)])
    acc['N'] += len([p for p in rN if not share_morph(*p)])
print("\n■【対照B】形態素→漢字列を長さ保存で無作為に入れ替えた面(%d回平均・識別子なし)" % TRIALS)
print("   %-16s %12s %12s" % ("", "実際", "無作為"))
print("   %-16s %12d %12.0f  → 実際は %.2f 倍" % ("完全衝突", len(E), acc['E'] / TRIALS,
                                                len(E) / max(1.0, acc['E'] / TRIALS)))
print("   %-16s %12d %12.0f  → 実際は %.2f 倍" % ("恣意的な転置", len(T_arb), acc['T'] / TRIALS,
                                                len(T_arb) / max(1.0, acc['T'] / TRIALS)))
print("   %-16s %12d %12.0f  → 実際は %.2f 倍" % ("恣意的な高重複", len(N_arb), acc['N'] / TRIALS,
                                                len(N_arb) / max(1.0, acc['N'] / TRIALS)))

# ---------- 7. 参考値: 2字語どうしの1字違い ----------
two = [k for k in keys if len(surf[k]) == 2]
b2 = collections.defaultdict(list)
for k in two:
    s = surf[k]
    b2[s[0] + '*'].append(k)
    b2['*' + s[1]].append(k)
c2 = 0
for _, ks in b2.items():
    c2 += len(ks) * (len(ks) - 1) // 2
print("\n■ 参考: 2字面どうしで1字を共有する対 = %s 対(2字面 %s 個)" % (format(c2, ','), format(len(two), ',')))
print("   共有率50%%にすぎず、電車/電話 を混同しないのと同様、危険とはみなさない。")
print("   これを危険に数えると数値が10万対規模に膨らむが、実質を反映しない(初版の誤り)。")

# ---------- 8. 書き出し ----------
rows = []
for nm, pairs in (('完全衝突(異義)', [(a, b) for a, b, _ in E_amb]),
                  ('転置(恣意的)', T_arb), ('高重複(恣意的)', N_arb)):
    for a, b in pairs:
        ta, tb = pure[a]['tier'], pure[b]['tier']
        rows.append((max(ta, tb), min(ta, tb), nm, TN[ta], pure[a]['sample'], surf_full[a],
                     TN[tb], pure[b]['sample'], surf_full[b]))
rows.sort()
with io.open("_lens23_risk_pairs.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("類型\t層A\t語A\t面A\t層B\t語B\t面B\n")
    for r in rows:
        f.write("\t".join(r[2:]) + "\n")
with io.open("_lens23_exact_unresolved.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("判定\t根拠\t層A\t語A\t層B\t語B\t面\n")
    for tag, lst in (('同義(無害)', E_syn), ('異義の可能性', [(a, b, '') for a, b, _ in E_amb])):
        for a, b, kind in lst:
            f.write("\t".join((tag, kind, TN[pure[a]['tier']], pure[a]['sample'],
                               TN[pure[b]['tier']], pure[b]['sample'], surf_full[a])) + "\n")

print("\n" + "=" * 100)
print("■ ★両方とも最優先層(CSV2890)の混同対 = %d 対" % len([r for r in rows if r[0] == 0]))
for r in [r for r in rows if r[0] == 0][:60]:
    print("   [%s] %-16s %-8s ⇔ %-16s %-8s" % (r[2], r[4], r[5], r[7], r[8]))

print("\n■ 未解決の完全衝突のうち【異義の可能性】= %d 対(全件・目視確認用)" % len(E_amb))
for a, b, _ in sorted(E_amb, key=lambda p: (pure[p[0]]['tier'], pure[p[0]]['sample'])):
    print("   %-8s %-18s ⇔ %-8s %-18s 面=%-6s  %s ／ %s"
          % (TN[pure[a]['tier']], pure[a]['sample'], TN[pure[b]['tier']], pure[b]['sample'],
             surf_full[a], pure[a]['gloss'][:34].replace('\t', ' '), pure[b]['gloss'][:34].replace('\t', ' ')))

print("\n■ 未解決だが同義と判定した %d 対の根拠内訳" % len(E_syn))
for kind, c in collections.Counter(k for _, _, k in E_syn).most_common():
    print("     %-16s %d 対" % (kind, c))

with io.open("_lens23_near_collision.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("区分\t指標\t値\n")
    f.write("全体\t母集団_全レキシーム\t%d\n" % len(keys_all))
    f.write("全体\t母集団_漢字2字以上\t%d\n" % len(keys))
    f.write("全体\t類型1_完全衝突_対\t%d\n" % len(E))
    f.write("全体\t類型1_識別子未解決_対\t%d\n" % len(E_unres))
    f.write("全体\t類型1_未解決かつ同義_対\t%d\n" % len(E_syn))
    f.write("全体\t類型1_未解決かつ異義_対\t%d\n" % len(E_amb))
    f.write("全体\t類型2_転置衝突_対\t%d\n" % len(T))
    f.write("全体\t類型2_恣意的_対\t%d\n" % len(T_arb))
    f.write("全体\t類型3_高重複近傍_対\t%d\n" % len(N))
    f.write("全体\t類型3_恣意的_対\t%d\n" % len(N_arb))
    for t in (0, 1, 2, 3):
        if nA[t]:
            m = max(1, n2[t])
            f.write("層別\t%s_全件\t%d\n" % (TN[t], nA[t]))
            f.write("層別\t%s_2字以上\t%d\n" % (TN[t], n2[t]))
            f.write("層別\t%s_異義完全衝突率%%\t%.2f\n" % (TN[t], 100.0 * len(hit['amb'][t]) / nA[t]))
            f.write("層別\t%s_恣意的転置率%%\t%.2f\n" % (TN[t], 100.0 * len(hit['transp'][t]) / nA[t]))
            f.write("層別\t%s_恣意的高重複率%%\t%.2f\n" % (TN[t], 100.0 * len(hit['near'][t]) / nA[t]))
            f.write("層別\t%s_恣意的高重複率_2字以上条件付%%\t%.2f\n" % (TN[t], 100.0 * len(hit['near'][t]) / m))
            v = _len_by_tier[t]
            f.write("層別\t%s_面の平均字数\t%.2f\n" % (TN[t], sum(v) / len(v)))
    f.write("対照A_ラテン\t完全衝突_対\t%d\n" % len(lE))
    f.write("対照A_ラテン\t転置衝突_対\t%d\n" % len(lT))
    f.write("対照A_ラテン\t高重複近傍_対\t%d\n" % len(lN))
    f.write("対照B_無作為\t完全衝突_対\t%.0f\n" % (acc['E'] / TRIALS))
    f.write("対照B_無作為\t恣意的転置_対\t%.0f\n" % (acc['T'] / TRIALS))
    f.write("対照B_無作為\t恣意的高重複_対\t%.0f\n" % (acc['N'] / TRIALS))
print("\n出力: _lens23_near_collision.tsv / _lens23_risk_pairs.tsv")
