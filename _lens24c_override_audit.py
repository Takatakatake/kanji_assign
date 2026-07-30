# -*- coding: utf-8 -*-
# 第24レンズ 補遺2: 規範(Unified_Level)は、実装されている場所で守られているか
#
#   方針書 §13 は「層内の基本語彙の順序は Unified_Level(低いほど優先)を規範とする。
#   ただし **実装上は機械的ソートキーとしては使わない**(純難易度ソートは曜日等を
#   過剰修正するため)。実現手段は _base_override.tsv(110行)」と定めている。
#
#   つまり Unified_Level は「規範」であって「ソートキー」ではない。
#   補遺1までで規範そのものの妥当性(頻度をよく予測する)は示した。
#   ここでは **規範が実装されている唯一の場所=_base_override.tsv の110件** が
#   規範に沿っているかを検査する。
#
#   検査: 各 override 行(漢字→語根)について、その漢字を共有する語根群の中で
#     ・選ばれた語根の Unified_Level は最小か(=最も易しいか)
#     ・選ばれた語根の実文頻度は最大か
#   を見る。両方に反する行があれば、規範から外れた curation の候補である。
import io, os, re, sys, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
OV = "_base_override.tsv"
SIDE = "_identifier_sidecar.tsv"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
INJ = "漢字注入_学習者版_20260620.txt"
DIARY = os.path.join("..", "漢字化エスペラント日記")
PIVF = "10_PIV2020参照データ/PIV2020_structured.txt"
SEP = re.compile(r'[/ ]')
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us',
           'o', 'a', 'e', 'i', 'u', 'j', 'n']
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


def is_cjk(c):
    return '一' <= c <= '鿿'


def strip_id(s):
    return ''.join(c for c in s if is_cjk(c))


# ---------- Unified_Level (語根単位に落とす) ----------
bare2segs = {}
for line in io.open(INJ, encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        continue
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')] if '⟦' in head else head
    if ' ' in raw:
        continue
    cs = [s for s in SEP.split(raw) if s]
    while len(cs) > 1 and cs[-1] in ENDPOP:
        cs.pop()
    if cs:
        bare2segs.setdefault(raw.replace('/', ''), [c.strip('-') for c in cs])

root_lv = {}
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
            segs = bare2segs.get(w) or [w.strip('-')]
            if len(segs) == 1:
                r = segs[0]
                if r not in root_lv or lv < root_lv[r]:
                    root_lv[r] = lv

# ---------- 実文頻度 ----------
def load_diary():
    if not os.path.isdir(DIARY):
        return ''
    return '\n'.join(io.open(os.path.join(DIARY, f), encoding='utf-8', errors='replace').read()
                     for f in os.listdir(DIARY) if f.endswith('.md') and '原文エスペラント' in f)


def load_piv():
    if not os.path.exists(PIVF):
        return ''
    return '\n'.join(re.findall(r'_([^_\n]{6,})_',
                                io.open(PIVF, encoding='utf-8', errors='replace').read()))


WORD = re.compile(r"[A-Za-zĉĝĥĵŝŭĈĜĤĴŜŬ]{1,}")
freq = collections.Counter()
for text in (load_diary(), load_piv()):
    for w in WORD.findall(text):
        w = to_hsys(w.lower())
        segs = bare2segs.get(w)
        if segs is None:
            st = w
            for e in ENDINGS:
                if st.endswith(e) and len(st) > len(e):
                    segs = bare2segs.get(st[:-len(e)])
                    if segs:
                        break
        if segs:
            for s in segs:
                freq[s] += 1

# ---------- sidecar: 漢字 -> その字を持つ語根群 ----------
group = collections.defaultdict(list)
with io.open(SIDE, encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 2:
            group[strip_id(p[1])].append(to_hsys(p[0]))

# ---------- override 行を検査 ----------
rows = []
for line in io.open(OV, encoding='utf-8'):
    line = line.rstrip('\n')
    if not line or line.startswith('#'):
        continue
    p = line.split('\t')
    if len(p) < 2:
        continue
    kan, root = p[0].strip(), to_hsys(p[1].strip())
    cands = group.get(strip_id(kan), [])
    if root not in cands:
        rows.append((kan, root, 'sidecarに群が無い', '', '', len(cands)))
        continue
    lvs = {c: root_lv.get(c) for c in cands}
    fqs = {c: freq.get(c, 0) for c in cands}
    have_lv = [c for c in cands if lvs[c] is not None]
    lv_ok = (root in have_lv and lvs[root] == min(lvs[c] for c in have_lv)) if have_lv else None
    fq_ok = fqs[root] == max(fqs.values()) if cands else None
    best_lv = min(have_lv, key=lambda c: lvs[c]) if have_lv else ''
    best_fq = max(cands, key=lambda c: fqs[c]) if cands else ''
    rows.append((kan, root,
                 ('最易' if lv_ok else ('—' if lv_ok is None else '×:' + best_lv)),
                 ('最頻' if fq_ok else '×:' + best_fq),
                 '%d' % fqs[root], len(cands)))

print("=" * 100)
print("■ _base_override.tsv の110件は規範(Unified_Level / 実文頻度)に沿っているか")
print("=" * 100)
n = len(rows)
lv_ng = [r for r in rows if r[2].startswith('×')]
fq_ng = [r for r in rows if r[3].startswith('×')]
both = [r for r in rows if r[2].startswith('×') and r[3].startswith('×')]
noside = [r for r in rows if r[2] == 'sidecarに群が無い']
print("   検査した override 行 = %d" % n)
print("   Unified_Level が群内最易でない = %d 件" % len(lv_ng))
print("   実文頻度が群内最大でない       = %d 件" % len(fq_ng))
print("   ★両方に反する(=規範から外れた候補) = %d 件" % len(both))
print("   sidecarに対応する群が見つからない = %d 件" % len(noside))
print("\n   ★両方に反する行(全件):")
print("   %-4s %-14s %-16s %-16s %8s %6s" % ("漢字", "選ばれた語根", "Unified_Level", "実文頻度", "その頻度", "群の大きさ"))
for r in sorted(both, key=lambda x: -int(x[4])):
    print("   %-4s %-14s %-16s %-16s %8s %6d" % r)
if not both:
    print("      (0件)")
with io.open("_lens24c_override_audit.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("漢字\t選ばれた語根\tUnified_Level判定\t実文頻度判定\t選ばれた語根の頻度\t群の大きさ\n")
    for r in rows:
        f.write('\t'.join(str(x) for x in r) + '\n')
print("\n出力: _lens24c_override_audit.tsv")
