# -*- coding: utf-8 -*-
# 第22レンズ「コーパスを変えた再現性」 2026-07-28
#
#   第6レンズは「実文コーパスの延べトークン被覆」を測り、
#   『CSV2890層は辞書の約5%しか占めないのに実文トークンの53.2%を占める』という
#   優先順位の直接証明を得た。しかしそれは **1つのコーパスでの1回の測定** だった。
#   コーパスを変えても同じ結論が出るかは検証していない。
#   再現しなければ、あの53.2%はコーパス固有の性質だったことになる。
#
#   本レンズは **辞書と完全に独立した2つの実文コーパス** で測り直す:
#     コーパスA = ユーザー自身が書いたエスペラント原文(随想4本＋日記21日分)
#                 …実際の使用場面そのもの。辞書の見出し語選定とは無関係
#     コーパスB = PIV2020 の用例文(_斜体_ で示された例文を抽出)
#                 …辞書編纂者が「その語の典型的用法」として選んだ文。登録語彙に偏る
#   2つは文体も出自も全く違うので、両方で同じ順序が出れば再現性は強い。
#
#   ★測る量は第6レンズと同じ:
#     (1) 辞書シェア   … その層の語根が辞書全体の何%か
#     (2) 実文シェア   … その層の形態素が実文の延べ内容トークンの何%か
#     (3) てこ比 = (2)/(1) … 1あたりの実文での働き。優先順位が効いていれば上位層ほど大きい
#
# 出力: _lens22_corpus_replication.tsv + stdout要約
import io, os, re, sys, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass

os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = "漢字注入_学習者版_20260620.txt"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
SIDE = "_identifier_sidecar.tsv"
LEARN = "20_PEJVO語彙リスト_原本・生成版_2024-2026/世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
DIARY = os.path.join("..", "漢字化エスペラント日記")
PIVF = "10_PIV2020参照データ/PIV2020_structured.txt"
PEJVO_END, SUPL_END = 44104, 44440
FUNC = {'suf', 'pref', 'prep', 'correl', 'num', 'func'}
ENDINGS = ['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n']


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    # x-system も吸収(cx→c^ 等)。日記側の表記ゆれ対策
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


def is_cjk(c):
    return '一' <= c <= '鿿'


# ---------- 1. 語根の層 ----------
band = {}
with io.open(SIDE, encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 6:
            band[to_hsys(p[0])] = p[5]

csv_words = set()
with io.open(CSVF, encoding='utf-8-sig') as f:
    import csv as _csv
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if rec and rec[0].strip():
            for t in rec[0].split(','):
                t = to_hsys(t.strip())
                if t:
                    csv_words.add(t)

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

# ---------- 2. 見出し語 → (内容形態素, 漢字化されているか) ----------
SEP = re.compile(r'[/ ]')
stem2info = {}
seg_csv = set()
for line in io.open(INJ, encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        continue
    head = line.split(':', 1)[0]
    raw = head[:head.index('⟦')] if '⟦' in head else head
    disp = head[head.index('⟦') + 1:head.rindex('⟧')] if '⟦' in head else raw
    segs, disps = SEP.split(raw), SEP.split(disp)
    if len(segs) != len(disps):
        disps = segs
    # ★2026-07-28: 1分節だけの見出しで、かつ接尾辞見出し(-で始まる)でないものは、
    #   その分節が ENDINGS に載っていても **実在の語** として扱う。
    #   ENDINGS には副詞+対格の融合形 'en' が入っているため、初版は
    #   **前置詞 en(=内) を語尾と誤判定して丸ごと落としていた**(PIV例文で6,851回・全語の1.6%)。
    #   en は最もてこ比の高い機能形態素層なので、落とすと最優先層を過少評価する(結論は保守側)。
    solo = (len(segs) == 1 and not raw.startswith('-'))
    toks = []
    for s, d in zip(segs, disps):
        if not s or (s in set(ENDINGS) and not solo):
            continue
        toks.append((s, any(is_cjk(c) for c in d)))
    if not toks:
        continue
    bare = raw.replace('/', '').replace(' ', '')
    if ' ' in raw:            # 句見出しは単語照合に使わない
        continue
    # ★2026-07-28: 見出し語は「裸形そのもの」と「語尾を剥がした語幹」の両方をキーにする。
    #   語幹だけにすると、相関詞 kiu→ki・前置詞 en→(空) のように **機能語が消える**。
    #   初版はこれで en(PIV例文6,851回)・kiuj・tiuj 等を取りこぼし、
    #   最も てこ比の高い機能形態素層を系統的に過少計上していた(結論の向きは保守側だったが数値が誤り)。
    if bare and bare not in stem2info:
        stem2info[bare] = toks
    st = bare
    for e in ENDINGS:
        if st.endswith(e) and len(st) > len(e):
            st = st[:-len(e)]
            break
    if st and st not in stem2info:
        stem2info[st] = toks
    if bare in csv_words:
        for s, _ in toks:
            seg_csv.add(s)


def tier(seg):
    if band.get(seg, '') in FUNC:
        return 0            # 機能形態素(§5/§6の確定層)
    if seg in seg_csv:
        return 1            # CSV2890
    ln = root_line.get(seg)
    if ln is None:
        return 4
    return 2 if ln <= PEJVO_END else (2 if ln <= SUPL_END else 3)


TN = {0: 'tier0b_機能形態素', 1: 'tier0_CSV2890', 2: 'tier1_PEJVO', 3: 'tier2_PIV', 4: 'tier3_辞書外'}

# ---------- 3. コーパス読み込み ----------
def load_diary():
    txt = []
    if not os.path.isdir(DIARY):
        return ''
    for f in os.listdir(DIARY):
        if f.endswith('.md') and '原文エスペラント' in f:
            txt.append(io.open(os.path.join(DIARY, f), encoding='utf-8', errors='replace').read())
    return '\n'.join(txt)


def load_piv():
    if not os.path.exists(PIVF):
        return ''
    t = io.open(PIVF, encoding='utf-8', errors='replace').read()
    return '\n'.join(re.findall(r'_([^_\n]{6,})_', t))      # 斜体=用例文


WORD = re.compile(r"[A-Za-zĉĝĥĵŝŭĈĜĤĴŜŬ]{2,}")


def analyze(name, text):
    toks = [to_hsys(w.lower()) for w in WORD.findall(text)]
    stat = collections.Counter()
    kanji = collections.Counter()
    hit = miss = 0
    for w in toks:
        st = w
        info = stem2info.get(st)
        if info is None:
            for e in ENDINGS:
                if st.endswith(e) and len(st) > len(e):
                    info = stem2info.get(st[:-len(e)])
                    if info:
                        break
        if info is None:
            miss += 1
            continue
        hit += 1
        for s, k in info:
            t = tier(s)
            stat[t] += 1
            if k:
                kanji[t] += 1
    return name, len(toks), hit, miss, stat, kanji


# ---------- 4. 辞書側のシェア(比較の分母) ----------
dict_share = collections.Counter()
for st, toks in stem2info.items():
    for s, _ in toks:
        pass
seen = set()
for st, toks in stem2info.items():
    for s, _ in toks:
        if s not in seen:
            seen.add(s)
            dict_share[tier(s)] += 1
DT = sum(dict_share.values())

results = [analyze('A_日記・随想(ユーザー原文)', load_diary()),
           analyze('B_PIV用例文', load_piv())]

print("=" * 96)
print("第22レンズ「コーパスを変えた再現性」 — 辞書側の語根 %d 種を分母に" % DT)
print("=" * 96)
print("\n■ 辞書シェア(語根の種類数ベース)")
for t in (0, 1, 2, 3, 4):
    if dict_share[t]:
        print("   %-18s %6d 種 (%5.1f%%)" % (TN[t], dict_share[t], 100.0 * dict_share[t] / DT))

rows = []
for name, ntok, hit, miss, stat, kanji in results:
    S = sum(stat.values())
    print("\n" + "=" * 96)
    print("■ %s  総語数 %s / 辞書照合できた語 %s (%.1f%%) / 延べ内容形態素 %s"
          % (name, format(ntok, ','), format(hit, ','), 100.0 * hit / max(1, ntok), format(S, ',')))
    print("   %-18s %10s %10s %10s   %s" % ("層", "実文シェア", "辞書シェア", "★てこ比", "漢字化率"))
    for t in (0, 1, 2, 3, 4):
        if not stat[t]:
            continue
        rs = 100.0 * stat[t] / S
        ds = 100.0 * dict_share[t] / DT
        lev = rs / ds if ds else 0
        print("   %-18s %9.1f%% %9.1f%% %9.2f倍   %5.1f%%"
              % (TN[t], rs, ds, lev, 100.0 * kanji[t] / stat[t]))
        rows.append((name, TN[t], stat[t], '%.2f' % rs, '%.2f' % ds, '%.2f' % lev,
                     '%.1f' % (100.0 * kanji[t] / stat[t])))
    top = stat[0] + stat[1]
    print("   ── 最優先層(機能形態素+CSV2890)の合計 実文シェア = %.1f%% / 辞書シェア = %.1f%% / てこ比 %.2f倍"
          % (100.0 * top / S, 100.0 * (dict_share[0] + dict_share[1]) / DT,
             (100.0 * top / S) / (100.0 * (dict_share[0] + dict_share[1]) / DT)))
    print("   ── 実文の内容形態素が漢字で描画される率 = %.1f%%"
          % (100.0 * sum(kanji.values()) / S))

with io.open("_lens22_corpus_replication.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("コーパス\t層\t延べ数\t実文シェア%\t辞書シェア%\tてこ比\t漢字化率%\n")
    for r in rows:
        f.write('\t'.join(str(x) for x in r) + '\n')
