# -*- coding: utf-8 -*-
# 第19レンズ「割り当ての履歴安定性」 2026-07-28
#
#   第1〜18レンズは全て【現在のスナップショット】を測っていた。
#   本レンズは一度も使っていないデータ源＝**git履歴そのもの**で測る。
#
#   優先順位が本当に効いているなら、最優先層(CSV2890)は
#     ・最も早く割り当たり
#     ・最も少ない回数しか動かず
#     ・最後に動いてから最も長く経っている
#   はずである。学習者が最初に覚える層が一番よく揺れるなら、それは優先順位が
#   効いていないのと同じ意味を持つ(覚え直しのコストが最上位層に集中する)。
#
#   さらに【フリップフロップ】(A→B→A と元の字に戻った語根)を検出する。
#   これは「決着していない論点」の化石であり、件数がそのまま未解決の争点の数になる。
#
# 出力: _lens19_stability_ledger.tsv + stdout要約
import io, os, re, csv as _csv, collections, subprocess

os.chdir(os.path.dirname(os.path.abspath(__file__)))
SRC = "_p_work.csv"
LEARN = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n']
FUNC = {'suf', 'pref', 'prep', 'correl', 'num', 'func'}
CORE = {'basic', 'suf', 'pref', 'prep', 'correl', 'num', 'func', 'cal'}


def sh(args):
    return subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL).stdout


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


def parse_pwork(blob):
    """_p_work.csv の1リビジョン分を root->kanji に。列= root,k,band,br,..."""
    out = {}
    try:
        txt = blob.decode('utf-8-sig')
    except Exception:
        return out
    for rec in _csv.reader(io.StringIO(txt)):
        if len(rec) < 2:
            continue
        r, k = rec[0].strip().strip('"'), rec[1].strip().strip('"')
        if not r or r == 'root':
            continue
        out[r] = k
    return out


# ---------- 1. 履歴を古い順に復元 ----------
revs = sh(['git', 'log', '--format=%H\t%ad\t%s', '--date=short', '--reverse',
           '--', SRC]).decode('utf-8', 'replace').strip().split('\n')
revs = [r.split('\t', 2) for r in revs if r.strip()]
print("履歴: %d リビジョン (%s 〜 %s)" % (len(revs), revs[0][1], revs[-1][1]))

hist = collections.defaultdict(list)     # root -> [(i, kanji)] 変化点のみ
prev = {}
first_seen, last_change = {}, {}
for i, (h, d, s) in enumerate(revs):
    cur = parse_pwork(sh(['git', 'show', h + ':' + SRC]))
    if not cur:
        continue
    for r, k in cur.items():
        if r not in prev:
            first_seen[r] = i
            hist[r].append((i, k))
        elif prev[r] != k:
            hist[r].append((i, k))
            last_change[r] = i
    prev = cur
NREV = len(revs)

# ---------- 2. 層判定(現在のsidecar/原本/CSVで決める) ----------
band, kan = {}, {}
with io.open("_identifier_sidecar.tsv", encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 8:
            kan[p[0]] = p[1]
            band[p[0]] = p[5]
hs2root = {}
for r in kan:
    hs2root.setdefault(to_hsys(r), r)

root_line, root_piv = {}, {}
with io.open(LEARN, encoding='utf-8') as f:
    for n, line in enumerate(f, 1):
        if ':' not in line:
            continue
        head, gl = line.split(':', 1)
        head = head.strip()
        if not head or head.startswith('#') or ' ' in head:
            continue
        p = head.split('/')
        if len(p) >= 2 and p[-1] in set(ENDINGS):
            p = p[:-1]
        r = ''.join(p)
        if r and r not in root_line:
            root_line[r] = n
            root_piv[r] = ('【PIV】' in gl)

csv_roots = set()
with io.open(CSVF, encoding='utf-8') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        for term in rec[0].split(','):
            t = to_hsys(term.strip()).replace('/', '').replace(' ', '')
            if not t:
                continue
            st = None
            for e in ENDINGS:
                if t.endswith(e) and len(t) > len(e):
                    st = t[:-len(e)]
                    break
            cl = [c for c in (st, t) if c and c in hs2root]
            if cl:
                cl.sort(key=lambda c: 0 if band.get(hs2root[c]) in CORE else 1)
                csv_roots.add(hs2root[cl[0]])


def tier(r):
    if r in csv_roots:
        return 9 if band.get(r) in FUNC else 0
    hs = to_hsys(r)
    ln = root_line.get(hs)
    if ln is None:
        return 3
    return 2 if (ln >= 44441 or root_piv.get(hs)) else 1


TIERNAME = {0: 'tier0_CSV2890内容語', 1: 'tier1_PEJVO', 2: 'tier2_PIV',
            3: 'tier3_裸形なし', 9: 'tier0b_機能形態素'}

# ---------- 3. 集計 ----------
stat = collections.defaultdict(collections.Counter)
rows, flips = [], []
for r, h in hist.items():
    if r not in kan:
        continue                                    # 現存しない語根(綴り変更等)は対象外
    t = tier(r)
    seq = [k for _, k in h]
    nch = len(seq) - 1                              # 初出後に変わった回数
    s = stat[t]
    s['roots'] += 1
    s['changes'] += nch
    if nch == 0:
        s['stable'] += 1
    s['first_sum'] += first_seen.get(r, 0)
    s['last_sum'] += last_change.get(r, first_seen.get(r, 0))
    seen = {}
    flip = False
    for j, k in enumerate(seq):
        if k in seen and j - seen[k] >= 2:
            flip = True
        seen[k] = j
    if flip:
        s['flip'] += 1
        flips.append((TIERNAME[t], r, kan.get(r, ''), ' → '.join(seq),
                      revs[h[-1][0]][1], revs[h[-1][0]][2][:44]))
    rows.append((r, kan.get(r, ''), TIERNAME[t], str(nch),
                 revs[first_seen.get(r, 0)][1],
                 revs[last_change.get(r, first_seen.get(r, 0))][1],
                 ' → '.join(seq)))

with io.open("_lens19_stability_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("語根\t現在の字\t層\t変更回数\t初出日\t最終変更日\t変遷\n")
    for row in sorted(rows, key=lambda x: (-int(x[3]), x[0])):
        f.write('\t'.join(row) + '\n')


def pct(a, b):
    return 100.0 * a / b if b else 0.0


print("")
print("%-20s %7s %8s %9s %11s %11s" %
      ("層", "語根数", "変更総数", "無変更率", "平均初出rev", "平均最終変更rev"))
tot = collections.Counter()
for t in (0, 9, 1, 2, 3):
    s = stat[t]
    if not s['roots']:
        continue
    print("%-20s %7d %8d %8.1f%% %10.1f %10.1f" %
          (TIERNAME[t], s['roots'], s['changes'], pct(s['stable'], s['roots']),
           s['first_sum'] / float(s['roots']), s['last_sum'] / float(s['roots'])))
    for kk in s:
        tot[kk] += s[kk]
print("%-20s %7d %8d %8.1f%% %10.1f %10.1f" %
      ("全体", tot['roots'], tot['changes'], pct(tot['stable'], tot['roots']),
       tot['first_sum'] / float(tot['roots']), tot['last_sum'] / float(tot['roots'])))
print("  ※ rev番号は0(2026-06-16)〜%d(最新)。小さいほど早く決まり、小さいほど早く動かなくなった。" % (NREV - 1))

print("")
print("★フリップフロップ(一度離れた字に戻った語根) = %d件" % len(flips))
for f_ in sorted(flips):
    print("   %-18s %-12s 現在=%-5s  %s" % (f_[0][:18], f_[1], f_[2], f_[3]))
    print("        最終変更 %s  %s" % (f_[4], f_[5]))
