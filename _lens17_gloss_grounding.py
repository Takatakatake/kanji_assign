# -*- coding: utf-8 -*-
# 第17レンズ「訳語グラウンディング検査」 2026-07-27
#
#   これまでの16レンズは全て【内部整合】(被覆/構造/一意性/round-trip/ROI…)を測っていた。
#   本レンズだけは【外部グラウンドトゥルース】で測る:
#     「割り当てた漢字は、その語根の“公式の訳語”に実際に現れる字か?」
#   判断に私(AI)の語感を一切使わない。照合するのは
#     (Z) CSV2890 の Chinese_Trans 列 … 簡体字。割り当て字と【全く同じ字種】(通用规范汉字表)
#     (J) 学術版原本の日本語訳     … 全44,000語超で利用可。ただし日本漢字なので簡体字とズレる
#   (Z)は字種が一致するので真値、(J)は字体差で過小評価。同じCSV2890語で両方測れば
#   その比 = 字体差による目減り係数 が求まり、(J)しか無い PEJVO/PIV 層の実測値を較正できる。
#
#   さらに chance level(偶然一致率)を、割り当て表を固定オフセットで巡回シフトして実測する。
#   接地率が chance と変わらなければ「意味が合っている」とは言えない。
#
# 出力: _lens17_grounding_ledger.tsv (全語根の判定) + _lens17_candidates.tsv (是正候補) + stdout要約
import io, os, sys, csv as _csv, collections

os.chdir(os.path.dirname(os.path.abspath(__file__)))
ACAD = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n']
# CSV2890中核+機能形態素+曜日月名。同綴が競合したときに「上位層側の解釈」を選ぶための集合。
CORE = {'basic', 'suf', 'pref', 'prep', 'correl', 'num', 'func', 'cal'}
FUNC = {'suf', 'pref', 'prep', 'correl', 'num', 'func'}


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def concat_root(head):
    if ' ' in head:
        return None
    parts = head.split('/')
    if len(parts) >= 2 and parts[-1] in set(ENDINGS):
        parts = parts[:-1]
    return ''.join(parts) if parts else None


def is_cjk(ch):
    return '一' <= ch <= '鿿'


_TAG = __import__('re').compile('【[^】]*】')


def strip_tags(s):
    """分野タグ【動】【植】【医】…を除去。PIV層の語釈はエスペラント文なので、
    タグを残すと『aden→腺』が【解】に当たるような偶然衝突を接地と誤認する(実測 tier2 で 1.8%)。"""
    return _TAG.sub('', s or '')


# ---------- 1. 学術版原本: 語根 -> (行番号, PIVタグ, 裸形の日本語訳, 語族の訳語全体) ----------
root_line, root_piv, root_gloss = {}, {}, {}
fam_gloss = collections.defaultdict(list)          # 語族(その語根を含む全見出し)の訳語
with io.open(ACAD, encoding='utf-8') as f:
    for n, line in enumerate(f, 1):
        line = line.rstrip('\n')
        if ':' not in line:
            continue
        head, gloss = line.split(':', 1)
        head = head.strip()
        if not head or head.startswith('#'):
            continue
        r = concat_root(head)
        if r and r not in root_line:
            root_line[r] = n
            root_piv[r] = ('【PIV】' in gloss)
            root_gloss[r] = gloss
        for seg in head.replace(' ', '/').split('/'):
            if seg and seg not in ENDINGS:
                fam_gloss[seg].append(gloss)

# ---------- 2. sidecar: 語根 -> 漢字 / band ----------
rows = []
with io.open("_identifier_sidecar.tsv", encoding='utf-8') as f:
    hdr = f.readline().rstrip('\n').split('\t')
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) < 8:
            continue
        rows.append({'root': p[0], 'kanji': p[1], 'disp': p[4], 'band': p[5], 'gk': p[7]})
print("sidecar header = %s" % '|'.join(hdr))
bandByRoot = {r['root']: r['band'] for r in rows}
kanjiByRoot = {r['root']: r['kanji'] for r in rows}
allroots = set(kanjiByRoot)
hs2root = {}
for r in allroots:
    hs2root.setdefault(to_hsys(r), r)
hsroots = set(hs2root)

# ---------- 3. CSV2890 -> 語根 -> (日本語訳, 中国語訳, Unified_Level) ----------
csv_ja, csv_zh, csv_level = {}, {}, {}
csv_rows = 0
with io.open(CSVF, encoding='utf-8') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        csv_rows += 1
        ja = rec[1] if len(rec) > 1 else ''
        zh = rec[2] if len(rec) > 2 else ''
        try:
            lvl = float(rec[3])
        except Exception:
            lvl = None
        for term in rec[0].split(','):
            t = to_hsys(term.strip()).replace('/', '').replace(' ', '')
            if not t:
                continue
            cands = []
            if t.startswith('-') or t.endswith('-'):
                stem = t.strip('-')
                cands = [stem]
                if len(stem) > 1 and stem[-1] in 'aio':
                    cands.append(stem[:-1])
            else:
                stripped = None
                for e in ENDINGS:
                    if t.endswith(e) and len(t) > len(e):
                        stripped = t[:-len(e)]
                        break
                # ★2026-07-27 第17レンズで是正。既存監査の「剥がし優先」だけだと
                #   kvin→kvi(=静/kvieta) / tamen→tam(=草) と誤照合し、
                #   逆に「剥がさない優先」にすると ami→伞(PIV植物) / fermi→金(fermio元素) /
                #   studi→室(studio) / taksi→车(taksio) / teni→条虫(tenio) と PIV同綴語に流れる。
                #   CSV2890行は【最上位層の語】なので、中核band側の解釈を優先する。
                cl = []
                if stripped and stripped in hsroots:
                    cl.append(stripped)
                if t in hsroots and t not in cl:
                    cl.append(t)
                if cl:
                    cl.sort(key=lambda c: 0 if bandByRoot.get(hs2root[c]) in CORE else 1)
                    cands = [cl[0]]
                elif stripped:
                    cands = [stripped]
            for c in cands:
                if c in hsroots:
                    r0 = hs2root[c]
                    csv_ja.setdefault(r0, ja)
                    csv_zh.setdefault(r0, zh)
                    if lvl is not None and (r0 not in csv_level or lvl < csv_level[r0]):
                        csv_level[r0] = lvl


def tier(root):
    """ユーザーの優先順位定義そのままで層を決める(band ラベルには依存しない)。
       tier0 = CSV2890 に実際に載っている語 / tier1 = PEJVO本体・追補 / tier2 = PIV。
       ただし機能形態素(接辞・相関詞・数詞…)は訳語が「[词尾]副词」等の文法説明で
       内容漢字を持たないため、tier0 の内数として別掲する。"""
    if root in csv_zh or root in csv_ja:
        return 9 if bandByRoot.get(root) in FUNC else 0
    hs = to_hsys(root)
    ln = root_line.get(hs)
    if ln is None:
        return 3                                   # 原本に裸形なし
    if ln >= 44441 or root_piv.get(hs):
        return 2
    return 1


TIERNAME = {0: 'tier0_CSV2890内容語', 1: 'tier1_PEJVO', 2: 'tier2_PIV',
            3: 'tier3_裸形なし', 9: 'tier0b_機能形態素'}

# ---------- 4. 接地判定 ----------
# 対象 = 漢字が割り当てられている語根のみ(ラテンのままの語根は対象外)
targets = []
for r in sorted(allroots):
    k = ''.join(ch for ch in kanjiByRoot[r] if is_cjk(ch))
    if not k:
        continue
    targets.append((r, k))

# chance level 用: 割り当て字を固定オフセットで巡回シフト(決定的)
OFFSET = 499
shifted = {}
for i, (r, k) in enumerate(targets):
    shifted[r] = targets[(i + OFFSET) % len(targets)][1]


def hit(k, text):
    """割り当て字のいずれかの字が訳語に出現するか。
    ★訳語に漢字が1字も無い場合は判定不能(None)。PIV層の語釈はエスペラント文なので
      これを分母に入れると『接地率1.3%』という測定アーチファクトが出る(2026-07-27 実測)。"""
    if not text or not any(is_cjk(ch) for ch in text):
        return None
    return any(ch in text for ch in k)


def hit_all(k, text):
    if not text:
        return None
    return all(ch in text for ch in k)


stat = collections.defaultdict(lambda: collections.Counter())
ledger = []
for r, k in targets:
    t = tier(r)
    hs = to_hsys(r)
    gj = strip_tags(root_gloss.get(hs, ''))        # 裸形の日本語訳(全層共通の物差し)
    gz = strip_tags(csv_zh.get(r, ''))             # 中国語訳(CSV2890のみ)
    famtxt = strip_tags(''.join(fam_gloss.get(hs, [])[:40]))   # 語族の訳語(裸形が簡素な場合の救済)

    hJ = hit(k, gj)
    hZ = hit(k, gz)
    hF = hit(k, famtxt)
    rJ = hit(shifted[r], gj)
    rZ = hit(shifted[r], gz)

    s = stat[t]
    if hJ is not None:
        s['J_n'] += 1
        s['J_hit'] += 1 if hJ else 0
    if rJ is not None:
        s['Jr_n'] += 1
        s['Jr_hit'] += 1 if rJ else 0
    if hZ is not None:
        s['Z_n'] += 1
        s['Z_hit'] += 1 if hZ else 0
    if rZ is not None:
        s['Zr_n'] += 1
        s['Zr_hit'] += 1 if rZ else 0
    if hF is not None:
        s['F_n'] += 1
        s['F_hit'] += 1 if hF else 0
    s['all'] += 1
    if hJ is None and hF is None:
        s['no_cjk'] += 1                           # 訳語がエスペラント文=接地を測れない

    ledger.append((r, k, TIERNAME[t], bandByRoot.get(r, ''),
                   ('%.2f' % csv_level[r]) if r in csv_level else '',
                   'Y' if hJ else ('N' if hJ is not None else '-'),
                   'Y' if hZ else ('N' if hZ is not None else '-'),
                   'Y' if hF else ('N' if hF is not None else '-'),
                   gj[:70].replace('\t', ' '), gz[:50].replace('\t', ' ')))

with io.open("_lens17_grounding_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("root\tkanji\ttier\tband\tlevel\thit_ja裸形\thit_zh中国語\thit_語族\tgloss_ja\tgloss_zh\n")
    for row in ledger:
        f.write('\t'.join(row) + '\n')


def pct(a, b):
    return (100.0 * a / b) if b else 0.0


print("")
print("== 第17レンズ: 訳語グラウンディング(外部ground-truth照合) ==")
print("CSV2890行=%d / 漢字割当のある語根=%d" % (csv_rows, len(targets)))
print("")
print("%-18s %6s %6s   %6s %7s %6s   %6s %7s %6s   %7s" %
      ("層", "語根数", "測定不能", "J_n", "J接地%", "偶然%", "Z_n", "Z接地%", "偶然%", "語族接地%"))
tot = collections.Counter()
for t in (0, 9, 1, 2, 3):
    s = stat[t]
    if not s['all']:
        continue
    print("%-18s %6d %6d   %6d %6.1f%% %5.1f%%   %6d %6.1f%% %5.1f%%   %6.1f%%" %
          (TIERNAME[t], s['all'], s['no_cjk'],
           s['J_n'], pct(s['J_hit'], s['J_n']), pct(s['Jr_hit'], s['Jr_n']),
           s['Z_n'], pct(s['Z_hit'], s['Z_n']), pct(s['Zr_hit'], s['Zr_n']),
           pct(s['F_hit'], s['F_n'])))
    for kk in s:
        tot[kk] += s[kk]
print("%-18s %6d %6d   %6d %6.1f%% %5.1f%%   %6d %6.1f%% %5.1f%%   %6.1f%%" %
      ("全体", tot['all'], tot['no_cjk'],
       tot['J_n'], pct(tot['J_hit'], tot['J_n']), pct(tot['Jr_hit'], tot['Jr_n']),
       tot['Z_n'], pct(tot['Z_hit'], tot['Z_n']), pct(tot['Zr_hit'], tot['Zr_n']),
       pct(tot['F_hit'], tot['F_n'])))

s0 = stat[0]
rz, rj = pct(s0['Z_hit'], s0['Z_n']), pct(s0['J_hit'], s0['J_n'])
print("")
print("字体差の目減り係数(同一CSV2890語での Z/J) = %.3f  (Z=簡体字で字種一致 / J=日本漢字)" % ((rz / rj) if rj else 0))

# ---------- 5. 是正候補: 外部2ソースとも支持しない ＆ 訳語に【既存字】がある ----------
used = set()
for r, k in targets:
    for ch in k:
        used.add(ch)

cand = []
for r, k in targets:
    if r not in csv_zh:
        continue                                    # 最優先層のみ精査(角を矯めて牛を殺さない)
    gz, gj = strip_tags(csv_zh[r]), strip_tags(csv_ja.get(r, ''))
    hs = to_hsys(r)
    famtxt = strip_tags(''.join(fam_gloss.get(hs, [])[:40]))
    if hit(k, gz) or hit(k, gj) or hit(k, strip_tags(root_gloss.get(hs, ''))) or hit(k, famtxt):
        continue                                    # どこかで接地していれば候補外
    alt = [ch for ch in gz if is_cjk(ch) and ch in used]
    if not alt:
        continue                                    # 新字が要るなら候補外(新字ゼロ)
    cand.append((csv_level.get(r, 99.0), r, k, ''.join(sorted(set(alt))), gz[:40], gj[:40]))

cand.sort()
with io.open("_lens17_candidates.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("level\troot\t現割当\t訳語中の既存字\tgloss_zh\tgloss_ja\n")
    for c in cand:
        f.write("%.2f\t%s\t%s\t%s\t%s\t%s\n" % c)
print("")
print("是正候補(CSV2890層・外部2ソースとも非接地・訳語に既存字あり) = %d件 -> _lens17_candidates.tsv" % len(cand))
print("  ※ hub合流/抽象語/evocative選字は正当な非接地。候補は【機械的な要点検リスト】であって是正指示ではない。")

# ---------- 6. 誤友検出 ----------
# 「割り当てトークンKが、自分の訳語には現れないのに、他の語根の訳語そのものになっている」
#   実例(2026-07-27 発見): limak/o(ナメクジ)=蜗牛 だが 蜗牛 は helik/o(カタツムリ)の訳語。
#   学習者は 蜗牛 を見て heliko だと読む -> 語根識別が壊れる。1字トークンは共有が正当なので
#   2字以上のトークンだけを対象にする(1字は hub合流・汎用字集中が設計どおり)。
own = {}
for r, k in targets:
    hs = to_hsys(r)
    own[r] = strip_tags(root_gloss.get(hs, '')) + strip_tags(csv_ja.get(r, '')) + \
        strip_tags(csv_zh.get(r, '')) + strip_tags(''.join(fam_gloss.get(hs, [])[:40]))

SEP = '\u0001'
order = [r for r, k in targets]
bare = {}
for r, k in targets:
    hs = to_hsys(r)
    bare[r] = strip_tags(root_gloss.get(hs, '')) + '/' + strip_tags(csv_ja.get(r, '')) + \
        '/' + strip_tags(csv_zh.get(r, ''))
corpus = SEP.join(bare[r] for r in order)
starts, pos = [], 0
for r in order:
    starts.append(pos)
    pos += len(bare[r]) + 1
import bisect

ff = []
for r, k in targets:
    if len(k) < 2:
        continue
    # ★1字でも自分の訳語に接地していれば除外。これが無いと arkitekt=建筑 が
    #   自分の訳語「建築家」に対し 筑≠築 の字体差だけで誤検出される(実測222→大幅減)。
    if hit(k, own[r]) is not False:
        continue
    i = corpus.find(k)
    others = []
    while i >= 0 and len(others) < 4:
        j = bisect.bisect_right(starts, i) - 1
        r2 = order[j]
        if r2 != r and r2 not in others:
            others.append(r2)
        i = corpus.find(k, i + 1)
    if others:
        ff.append((r, k, others))

with io.open("_lens17_falsefriend.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("語根\t割当トークン\t同トークンを訳語に持つ別語根\t別語根の訳語\n")
    for r, k, o in ff:
        f.write("%s\t%s\t%s\t%s\n" % (r, k, ','.join(o), bare[o[0]][:60].replace('\t', ' ')))
print("")
print("★誤友候補(2字以上のトークンが他語根の訳語と一致・自分の訳語には非出現) = %d件 -> _lens17_falsefriend.tsv" % len(ff))
for r, k, o in ff[:30]:
    print("   %-14s %-6s <- %s の訳語: %s" % (r, k, o[0], bare[o[0]][:44]))

# ---------- 7. ★群をまたぐ優先順位逆転 ----------
# 既存の[I]監査は【同じ漢字を共有する群の中】で基本形が上位層かを見る。
# しかし「具体的トークンTが下位層の語根に付き、Tを訳語に持つ上位層の語根は汎用字に回された」
# という逆転は、両者が別群なので[I]では原理的に検出できない。
#   実例: limon(PEJVO層,【果】レモン)=柠檬 / citron(CSV2890層,《般》レモン)=果ᶜ
# 判定: Tが上位層語根Aの訳語に出現 かつ Tは下位層語根Bに割り当て かつ Aの割当は1字(=汎用寄り)。
_re = __import__('re')


def senses(text):
    """訳語を語義単位に割る。括弧内の補足は落とす。
    『トークンが語釈に言及として現れる』だけでは弱すぎる(dom の中国語訳
    「房屋，住宅；建筑物」に 建筑 が含まれる等でノイズ279件)。
    語義まるごと一致に絞ると、その語根の【訳語そのもの】であることを要求できる。"""
    t = strip_tags(text)
    t = _re.sub('[（(][^）)]*[）)]', '', t)
    t = _re.sub('[《》＝=>\\[\\]{}]', '', t)
    return [s.strip() for s in _re.split('[,，;；、/\n]', t) if s.strip()]


tokOf = dict(targets)
senseOf = {r: set(senses(bare[r])) for r, k in targets}
inv = []
for r, k in targets:
    if len(k) < 2:
        continue
    tr = tier(r)
    if tr in (0, 9):
        continue                                   # 保持者が既に最上位層なら逆転ではない
    i, seen = corpus.find(k), []
    while i >= 0 and len(seen) < 8:
        j = bisect.bisect_right(starts, i) - 1
        a = order[j]
        if a != r and a not in seen:
            seen.append(a)
        i = corpus.find(k, i + 1)
    for a in seen:
        ta = tier(a)
        ka = tokOf.get(a, '')
        if ta < tr and len(ka) == 1 and k in senseOf.get(a, ()):
            inv.append((a, ka, TIERNAME[ta], r, k, TIERNAME[tr]))

with io.open("_lens17_tier_inversion.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("上位層語根\tその割当\t上位層\t下位層語根\t具体トークン\t下位層\t上位層語根の訳語\n")
    for a, ka, ta, r, k, tr in inv:
        f.write("%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (a, ka, ta, r, k, tr, bare[a][:70].replace('\t', ' ')))
comp = sum(1 for a, ka, ta, r, k, tr in inv if ka in k)
print("")
print("群をまたぐトークン競合 = %d件 -> _lens17_tier_inversion.tsv" % len(inv))
print("  うち上位層の字が下位層トークンの構成要素(=hub合流/合成トークン=設計どおり) = %d件 (%.0f%%)"
      % (comp, pct(comp, len(inv))))
for a, ka, ta, r, k, tr in inv[:8]:
    print("   上位%s %-11s=%-3s  <-- %-5s を 下位%s %-12s が保持%s"
          % (ta[:9], a, ka, k, tr[:9], r, '  [構成要素]' if ka in k else ''))

# ---------- 8. ★短いトークンという希少資源が上位層に配分されているか ----------
# 7. の120件を目視すると全て「上位層=短い汎用字 / 下位層=長い具体トークン」で、逆転ではなく
# 設計どおりの配分だった。ならば直接それを測るべき: トークン長は有限の希少資源であり、
# 優先順位が効いていれば【上位層ほど1字トークンを占める】はず。
print("")
print("%-20s %7s %9s %9s %9s" % ("層", "語根数", "平均字数", "1字率", "3字以上率"))
for t in (0, 9, 1, 2, 3):
    g = [k for r, k in targets if tier(r) == t]
    if not g:
        continue
    print("%-20s %7d %8.2f字 %8.1f%% %8.1f%%" %
          (TIERNAME[t], len(g), sum(len(x) for x in g) / float(len(g)),
           pct(sum(1 for x in g if len(x) == 1), len(g)),
           pct(sum(1 for x in g if len(x) >= 3), len(g))))
