# -*- coding: utf-8 -*-
# 第18レンズ「語義単位の被覆（多義の取りこぼし）」 2026-07-27
#
#   ユーザーが毎回添える原則:
#     「一つの語根に複数の全く異なる意味が存在する場合は、基本的には、可能な限り解釈を
#       頑張って、割り当て漢字の種類を増やさないように努めてほしいが、
#       全く意味が異なる場合は、新たな割り当ての検討も致し方ないと考えている。」
#
#   第15レンズは前半を測った = 「字種を増やした語根 = 138/10,643 = 1.30%」。
#   本レンズは【後半】を測る = 「増やすべきなのに増やしていない取りこぼしはどれだけあるか」。
#
#   測り方: 語根の裸形の語釈を【語義単位】に割り(この辞書は ; が語義境界、, が同義語列挙)、
#           各語義に割り当て字が接地するかを個別に判定する。
#           ・全語義に接地            = 多義を1字でまとめ切れている(理想)
#           ・第1義のみ接地・他は非接地 = 学習者はその語を体系的に読み違える
#   さらに【分野タグが異なる】語義間の非接地だけを強い信号として拾う。
#   同じ分野内の語義違い(比喩・転義)は1字でまとめるのが方針どおりだからである。
#
#   ★重み付け: 非接地語義が語族の何見出しに及ぶかを数える。1見出しだけなら実害は小さく、
#     数十見出しに及ぶなら配信データ全体が読み違いを起こす。
#
#   ★既裁定の除外: 方針書§14.2.1の確定裁定と台帳(_homonym.tsv)の sep/amb 行は
#     「検討済み」として別掲する。続39の事故(据置記録を見落として7件覆した)の再発防止。
#
# 出力: _lens18_sense_ledger.tsv / _lens18_candidates.tsv / stdout要約
import io, os, re, collections

os.chdir(os.path.dirname(os.path.abspath(__file__)))
LEARN = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n']
FUNC = {'suf', 'pref', 'prep', 'correl', 'num', 'func'}
CORE = {'basic', 'suf', 'pref', 'prep', 'correl', 'num', 'func', 'cal'}

# 方針書§14.2.1 で確定済み(再提案しない)。続39の再発防止。
SETTLED = {'plum', 'sinus', 'mat', 'kanon', 'sol', 'kuri', 'orkid', 'panikl', 'arke',
           'klement', 'bo', 'do', 'ho', 'po', 'ro', 'zo'}

TAG = re.compile('【([^】]*)】')
# 実在の分野タグだけを信号にする。出典タグ(PIV)や語法タグ(般/転/俗/カ)は分野ではない。
NOTDOMAIN = {'PIV', 'Ｏ', 'Ｂ', '般', '転', '俗', '古', '詩', '稀', 'ark'}


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def concat_root(head):
    if ' ' in head:
        return None
    p = head.split('/')
    if len(p) >= 2 and p[-1] in set(ENDINGS):
        p = p[:-1]
    return ''.join(p) if p else None


def is_cjk(ch):
    return '一' <= ch <= '鿿'


def clean(s):
    """語義本文から漢字判定の邪魔になる要素を落とす。
    >>xxx / =xxx はエスペラントの参照、{Ｂ}{Ｏ}は頻度マーカ、［他］等は品詞。"""
    s = re.sub('>>[^,;，；]*', '', s)
    s = re.sub('=[A-Za-z^\\-]+', '', s)
    s = re.sub('[{｛][^}｝]*[}｝]', '', s)
    s = re.sub('[［\\[][^］\\]]*[］\\]]', '', s)
    return s


# ---------- 1. 原本 ----------
root_gloss, root_line = {}, {}
fam = collections.defaultdict(list)
with io.open(LEARN, encoding='utf-8') as f:
    for n, line in enumerate(f, 1):
        line = line.rstrip('\n')
        if ':' not in line:
            continue
        head, gl = line.split(':', 1)
        head = head.strip()
        if not head or head.startswith('#'):
            continue
        r = concat_root(head)
        if r and r not in root_gloss:
            root_gloss[r] = gl
            root_line[r] = n
        for seg in head.replace(' ', '/').split('/'):
            if seg and seg not in ENDINGS:
                fam[seg].append(gl)

# ---------- 2. sidecar ----------
kanjiByRoot, bandByRoot, dispByRoot = {}, {}, {}
with io.open("_identifier_sidecar.tsv", encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) < 8:
            continue
        kanjiByRoot[p[0]] = p[1]
        dispByRoot[p[0]] = p[4]
        bandByRoot[p[0]] = p[5]
hs2root = {}
for r in kanjiByRoot:
    hs2root.setdefault(to_hsys(r), r)

# ---------- 3. 台帳(検討済みの語根) ----------
ledger_seg = set()
for fn in ("_homonym.tsv", "_homonym_disp.tsv"):
    if not os.path.exists(fn):
        continue
    with io.open(fn, encoding='utf-8') as f:
        for line in f:
            p = line.rstrip('\n').split('\t')
            if p and p[0] and not p[0].startswith('#'):
                ledger_seg.add(p[0].strip().strip('"'))

# ---------- 4. CSV2890 ----------
csv_roots, csv_level = set(), {}
import csv as _csv
with io.open(CSVF, encoding='utf-8') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        try:
            lvl = float(rec[3])
        except Exception:
            lvl = None
        for term in rec[0].split(','):
            t = to_hsys(term.strip()).replace('/', '').replace(' ', '')
            if not t:
                continue
            st = None
            for e in ENDINGS:
                if t.endswith(e) and len(t) > len(e):
                    st = t[:-len(e)]
                    break
            cl = []
            if st and st in hs2root:
                cl.append(st)
            if t in hs2root and t not in cl:
                cl.append(t)
            if cl:
                cl.sort(key=lambda c: 0 if bandByRoot.get(hs2root[c]) in CORE else 1)
                r0 = hs2root[cl[0]]
                csv_roots.add(r0)
                if lvl is not None and (r0 not in csv_level or lvl < csv_level[r0]):
                    csv_level[r0] = lvl


def tier(root):
    if root in csv_roots:
        return 9 if bandByRoot.get(root) in FUNC else 0
    hs = to_hsys(root)
    ln = root_line.get(hs)
    if ln is None:
        return 3
    return 2 if (ln >= 44441 or '【PIV】' in root_gloss.get(hs, '')) else 1


TIERNAME = {0: 'tier0_CSV2890内容語', 1: 'tier1_PEJVO', 2: 'tier2_PIV',
            3: 'tier3_裸形なし', 9: 'tier0b_機能形態素'}

# ---------- 5. 語義単位の接地判定 ----------
stat = collections.defaultdict(collections.Counter)
cand, ledger = [], []
for r in sorted(kanjiByRoot):
    k = ''.join(ch for ch in kanjiByRoot[r] if is_cjk(ch))
    if not k:
        continue
    hs = to_hsys(r)
    gl = root_gloss.get(hs)
    if not gl:
        continue
    senses = [s for s in gl.split(';') if s.strip()]
    if len(senses) < 2:
        continue
    t = tier(r)
    info = []
    for s in senses:
        tags = [x for x in TAG.findall(s) if x not in NOTDOMAIN]
        body = clean(TAG.sub('', s))
        if not any(is_cjk(c) for c in body):
            info.append(None)                       # 漢字を含まない語義=判定不能
            continue
        info.append((any(c in body for c in k), tuple(tags), body.strip()))
    live = [x for x in info if x]
    if len(live) < 2:
        continue
    nH = sum(1 for x in live if x[0])
    nM = len(live) - nH
    stat[t]['roots'] += 1
    stat[t]['senses'] += len(live)
    stat[t]['sense_hit'] += nH
    if nM == 0:
        stat[t]['all_ok'] += 1
    elif nH == 0:
        stat[t]['none'] += 1
    else:
        stat[t]['partial'] += 1

    ledger.append((r, dispByRoot.get(r, k), TIERNAME[t], str(len(live)), str(nH),
                   ' | '.join(('○' if x[0] else '×') + (('【' + '/'.join(x[1]) + '】') if x[1] else '') + x[2][:22]
                              for x in live)))

    # 候補: 一部の語義だけ非接地 かつ 分野タグが接地側と異なる = 体系的な読み違いを生む
    if nH and nM:
        hitTags = set()
        for x in live:
            if x[0]:
                hitTags |= set(x[1])
        for x in live:
            if x[0] or not x[1]:
                continue
            if set(x[1]) & hitTags:
                continue                            # 同分野の語義違いは1字でまとめるのが方針
            tg = x[1][0]
            weight = sum(1 for g in fam.get(hs, []) if ('【' + tg + '】') in g)
            cand.append((0 if r in SETTLED or r in ledger_seg else 1, t, -weight,
                         r, dispByRoot.get(r, k), TIERNAME[t], tg, weight,
                         x[2][:34], ' / '.join(y[2][:22] for y in live if y[0])))

with io.open("_lens18_sense_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("語根\t描画\t層\t語義数\t接地語義数\t語義ごとの判定\n")
    for row in ledger:
        f.write('\t'.join(row) + '\n')

cand.sort()
with io.open("_lens18_candidates.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("既検討\t層\t語根\t描画\t非接地語義の分野\t及ぶ見出し数\t非接地語義\t接地している語義\n")
    for c in cand:
        f.write("%s\t%s\t%s\t%s\t%s\t%d\t%s\t%s\n"
                % ('既裁定/台帳' if c[0] == 0 else '新規', c[5], c[3], c[4], c[6], c[7], c[8], c[9]))


def pct(a, b):
    return 100.0 * a / b if b else 0.0


print("== 第18レンズ: 語義単位の被覆(多義の取りこぼし) ==")
print("")
print("%-20s %7s %8s %9s %9s %9s" % ("層", "多義語根", "総語義", "全語義接地", "一部のみ", "語義接地率"))
tot = collections.Counter()
for t in (0, 9, 1, 2, 3):
    s = stat[t]
    if not s['roots']:
        continue
    print("%-20s %7d %8d %8.1f%% %8.1f%% %8.1f%%" %
          (TIERNAME[t], s['roots'], s['senses'], pct(s['all_ok'], s['roots']),
           pct(s['partial'], s['roots']), pct(s['sense_hit'], s['senses'])))
    for kk in s:
        tot[kk] += s[kk]
print("%-20s %7d %8d %8.1f%% %8.1f%% %8.1f%%" %
      ("全体", tot['roots'], tot['senses'], pct(tot['all_ok'], tot['roots']),
       pct(tot['partial'], tot['roots']), pct(tot['sense_hit'], tot['senses'])))
known = sum(1 for c in cand if c[0] == 0)
print("")
print("分野が異なる非接地語義 = %d件 (うち既裁定/台帳=%d / 新規=%d) -> _lens18_candidates.tsv"
      % (len(cand), known, len(cand) - known))

# ---------- 6. ★CSV2890層は中国語訳(字種一致)で測り直す ----------
# 日本語訳での語義接地率は字体差で約2.2倍過小評価される(第17レンズ実測)。
# 最優先層だけは中国語訳が使えるので、こちらが真値。語義境界は全角セミコロン。
zh_stat = collections.Counter()
zh_det = []
with io.open(CSVF, encoding='utf-8') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        zh = rec[2] if len(rec) > 2 else ''
        t = to_hsys(rec[0].split(',')[0].strip()).replace('/', '').replace(' ', '')
        st = None
        for e in ENDINGS:
            if t.endswith(e) and len(t) > len(e):
                st = t[:-len(e)]
                break
        cl = [c for c in (st, t) if c and c in hs2root]
        if not cl:
            continue
        cl.sort(key=lambda c: 0 if bandByRoot.get(hs2root[c]) in CORE else 1)
        r = hs2root[cl[0]]
        k = ''.join(c for c in kanjiByRoot[r] if is_cjk(c))
        if not k:
            continue
        sen = [re.sub('[（(][^）)]*[）)]', '', s) for s in zh.split('；') if s.strip()]
        sen = [s for s in sen if any(is_cjk(c) for c in s)]
        if len(sen) < 2:
            continue
        nh = sum(1 for s in sen if any(c in s for c in k))
        zh_stat['roots'] += 1
        zh_stat['sen'] += len(sen)
        zh_stat['hit'] += nh
        zh_stat['all' if nh == len(sen) else ('none' if nh == 0 else 'part')] += 1
        if nh and nh < len(sen):
            zh_det.append((len(sen) - nh, r, dispByRoot.get(r, k), zh[:58]))

print("")
print("== CSV2890層を中国語訳(字種一致=真値)で測り直す ==")
print("多義語根=%d / 総語義=%d / 1字が背負う語義=%.2f"
      % (zh_stat['roots'], zh_stat['sen'], zh_stat['sen'] / float(zh_stat['roots'])))
print("  全語義に接地       = %4d (%.1f%%)" % (zh_stat['all'], pct(zh_stat['all'], zh_stat['roots'])))
print("  一部の語義のみ接地 = %4d (%.1f%%)" % (zh_stat['part'], pct(zh_stat['part'], zh_stat['roots'])))
print("  どの語義にも非接地 = %4d (%.1f%%)" % (zh_stat['none'], pct(zh_stat['none'], zh_stat['roots'])))
print("  語義接地率         = %.1f%%" % pct(zh_stat['hit'], zh_stat['sen']))
zh_det.sort(reverse=True)
print("  -- 1字が最も多くの語義を背負っている例 --")
for d in zh_det[:8]:
    print("     %-10s %-6s %s" % (d[1], d[2], d[3]))
