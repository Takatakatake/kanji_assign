# -*- coding: utf-8 -*-
# 第33レンズ「日本人読者が払う費用 = 字種選択の非対称性」 (第27回続76)
#
#   ★空白の所在:
#     方針書 L14/L228 は読者を「日本人・中国人**双方**+非漢字圏学習者」と明示し、
#     字種を《通用规范汉字表》一级3500(简体字)に限定している。
#     ところが第1〜32の全レンズは「その字が意味を担えているか」だけを測り、
#     **字体差は一貫して【測定の邪魔】として相殺・除外**されてきた:
#       ・第17: 真値に中国語訳を選んだ理由がまさに「割り当てと同じ字種だから」
#       ・第20: 同じ字を二条件で測って比を取り、字体差を分子分母で相殺する設計
#       ・落とし穴台帳: 「日本語訳との照合は字体差で必ず過小評価(実測2.21倍)」
#     = 字体差は**一度も【読者が払う費用】として測られていない**。
#     中国人読者の字形費用はゼロだが、日本人読者は同じ体系に別の費用を払う。
#     この非対称性が優先順位を守っているか(上位層ほど安いか)は未検証である。
#
#   測る量:
#     [A] 字種の所属階梯 — JIS X 0208 / X 0212(補助漢字) / 圏外 × 日本語コーパス出現
#     [B] ★層別の延べ出現重み(配信面)。単調か逆転か。対照は頻度保存・画数保存の2種。
#     [C] 機構の分解 — 「简化は高頻度字を襲った」仮説の直接検定
#     [D] 简→日 の透明性 — 対応字を手で与え第31の字形機械で「見て分かる」かを測る
#     [E] 費用B = 同形異義(字形はJISにあるが日本語の語感と違う)の検出と全件目視
#     [F] 実配信テキスト(ユーザーの漢字化日記)での1文あたりの実費用
#
#   ★判定軸を2本立てる理由: 「日本語コーパスに出ない」は 147k字のコーパスに対する
#     出現有無なので、稀な日本漢字を偽陽性で拾う。そこで**規格による客観判定**
#     (JIS X 0208 = shift_jis で符号化できるか)を主軸に置き、コーパス出現は
#     「規格内だが実際には馴染みが薄い」を分ける第2軸として使う。
import io, os, re, sys, csv as _csv, collections, random, unicodedata

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
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
SUPCAT = ('Lm', 'Mn', 'Sk')
TIERS = ['文法層', 'CSV2890', 'PEJVO', 'PIV']
SEED = 20260802


def is_mark(c):
    return unicodedata.category(c) in SUPCAT


def strip_marks(s):
    return ''.join(c for c in s if not is_mark(c))


def is_cjk(c):
    return '一' <= c <= '鿿'


def has_kana(s):
    return any(('぀' <= c <= 'ゟ') or ('゠' <= c <= 'ヿ') for c in s)


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


def in_jis0208(c):
    try:
        c.encode('shift_jis')
        return True
    except Exception:
        return False


def in_jis0212(c):
    try:
        c.encode('euc_jp')
        return True
    except Exception:
        return False


def klass(c):
    """字形の所属階梯。J0=JIS X 0208(日本の常用的な字種) / J2=補助漢字のみ / OUT=日本語表記圏外"""
    if in_jis0208(c):
        return 'J0'
    if in_jis0212(c):
        return 'J2'
    return 'OUT'


# ================================================================
# 0. データ読み込み
# ================================================================
stroke, pool = {}, []
for i, l in enumerate(io.open(STROKE, encoding='utf-8-sig')):
    p = l.rstrip('\n').split('\t')
    if i == 0 or len(p) < 4:
        continue
    stroke[p[1]] = int(p[3])
    pool.append(p[1])

roots, rows = {}, []
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    d = {'root': p[0], 'kanji': p[1], 'id': p[2], 'sup': p[3], 'disp': p[4], 'band': p[5],
         'F': int(p[6]) if p[6].isdigit() else 0, 'gk': p[7]}
    rows.append(d)
    for key in {p[0], to_hsys(p[0]), to_hsys(p[0]).lower()}:
        roots.setdefault(key, d)

# CSV2890 語根の同定(第31/第27レンズと同一手順)
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
csv_rows = []
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.DictReader(f)
    for rec in rd:
        csv_rows.append(rec)
        w = (rec.get('Esperanto') or '').strip()
        if not w:
            continue
        for tok in w.split(','):
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

# 日本語コーパス = 学習者版の語釈のうち仮名を含む行(=確実に日本語)
jpfreq = collections.Counter()
n_gloss = n_jp = 0
for line in io.open(INJ['学習者版'], encoding='utf-8-sig'):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        continue
    n_gloss += 1
    g = line.split(':', 1)[1]
    if not has_kana(g):
        continue
    n_jp += 1
    for c in g:
        if is_cjk(c):
            jpfreq[c] += 1
# 中国語コーパス(CSV訳語) = パイプラインが一度も読まない外部データ。頻度対照に使う
cnfreq = collections.Counter()
for rec in csv_rows:
    for c in (rec.get('Chinese_Trans') or ''):
        if is_cjk(c):
            cnfreq[c] += 1

used = collections.Counter()
for d in rows:
    for c in d['disp']:
        if is_cjk(c):
            used[c] += 1
UC = sorted(used)

print("=" * 108)
print("■ 第33レンズ  日本人読者が払う費用 — 字種選択の非対称性")
print("=" * 108)
print("語根 %d / 割り当て使用字種 %d / 一级3500 の %.1f%%" % (len(rows), len(UC), 100.0 * len(UC) / 3500))
print("日本語コーパス(学習者版語釈のうち仮名を含む %d/%d 行) 延べ %d 字 / 字種 %d"
      % (n_jp, n_gloss, sum(jpfreq.values()), len(jpfreq)))
print("中国語コーパス(CSV訳語=パイプライン非参照) 延べ %d 字 / 字種 %d" % (sum(cnfreq.values()), len(cnfreq)))

# ================================================================
# 1. [A] 字種の所属階梯
# ================================================================
print("\n" + "=" * 108)
print("■ [A] 字種の所属階梯 — 割り当てに使った字は日本語表記に存在するか")
print("=" * 108)
kl = {c: klass(c) for c in pool}
tot = collections.Counter(kl[c] for c in pool)
print("一级3500 全体      : JIS X 0208内 %4d (%.1f%%) / 補助漢字のみ %3d (%.1f%%) / 圏外 %4d (%.1f%%)"
      % (tot['J0'], 100.0 * tot['J0'] / 3500, tot['J2'], 100.0 * tot['J2'] / 3500,
         tot['OUT'], 100.0 * tot['OUT'] / 3500))
uk = collections.Counter(kl.get(c, klass(c)) for c in UC)
print("★実際に使った %4d 字種 : JIS X 0208内 %4d (%.1f%%) / 補助漢字のみ %3d (%.1f%%) / 圏外 %4d (%.1f%%)"
      % (len(UC), uk['J0'], 100.0 * uk['J0'] / len(UC), uk['J2'], 100.0 * uk['J2'] / len(UC),
         uk['OUT'], 100.0 * uk['OUT'] / len(UC)))
print("  → 使用字は一级全体より %.2f 倍だけ日本語圏外に寄っている(1.00 なら中立)"
      % ((uk['OUT'] / len(UC)) / (tot['OUT'] / 3500.0)))
noattest = [c for c in UC if jpfreq[c] == 0]
print("第2軸: 日本語コーパスに一度も出ない字 %d 種 (%.1f%%)" % (len(noattest), 100.0 * len(noattest) / len(UC)))
xt = collections.Counter((kl.get(c, klass(c)), jpfreq[c] > 0) for c in UC)
print("  内訳: JIS内かつ出現 %d / JIS内だが未出 %d / 補助漢字 %d / 圏外 %d"
      % (xt[('J0', True)], xt[('J0', False)], uk['J2'], uk['OUT']))
print("  ※『JIS内だが未出』は表外字・旧字体で、日本人読者には読めるが日常的でない層")

# ================================================================
# 2. [B] 層別の延べ出現重み — 優先順位どおりか
# ================================================================
print("\n" + "=" * 108)
print("■ [B] ★層別の費用 — 優先順位の高い層ほど日本人読者に安いか")
print("=" * 108)


def tier_char_tokens():
    """配信面の延べ出現を層別に数える。単位=『漢字1文字の出現』、層は【その字を出した語根】の層"""
    cnt = collections.defaultdict(collections.Counter)
    unmatched = 0
    for line in io.open(INJ['学習者版'], encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or '⟦' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')]
        box = head[head.index('⟦') + 1:head.rindex('⟧')]
        rs = [x for x in raw.split('/') if x]
        bs = [x for x in box.split('/') if x]
        if len(rs) != len(bs):
            continue
        for r0, b0 in zip(rs, bs):
            # ★複数語見出し(`angl/a lingv/o⟦英/a 语/o⟧`)は分節の内側に空白が入る。
            #   空白で割らずに引くと 'a lingv' が語根として引けず 6,002 分節が静かに落ちる
            rw, bw = r0.split(' '), b0.split(' ')
            if len(rw) != len(bw):
                rw, bw = [r0], [b0]
            for r, b in zip(rw, bw):
                if not any(is_cjk(c) for c in b):
                    continue
                d = roots.get(r) or roots.get(to_hsys(r)) or roots.get(to_hsys(r).lower()) \
                    or roots.get(r.strip('-')) or roots.get(to_hsys(r.strip('-')).lower())
                if not d:
                    unmatched += 1
                    continue
                for c in b:
                    if is_cjk(c):
                        cnt[d['tier']][c] += 1
    return cnt, unmatched


tok, unm = tier_char_tokens()
print("(配信面の漢字出現を層別に集計。語根照合できなかった分節 %d 件は除外)" % unm)
print("\n%-8s %10s %10s %10s %10s   %s" % ("層", "延べ漢字", "JIS圏外", "圏外率", "未出率", "型での圏外率"))
res = {}
for t in TIERS:
    c = tok[t]
    n = sum(c.values())
    out = sum(v for ch, v in c.items() if kl.get(ch, klass(ch)) == 'OUT')
    na = sum(v for ch, v in c.items() if jpfreq[ch] == 0)
    ty = len(c)
    tyout = sum(1 for ch in c if kl.get(ch, klass(ch)) == 'OUT')
    res[t] = (n, out, na, ty, tyout)
    print("%-8s %10d %10d %9.2f%% %9.2f%%   %6.2f%% (%d/%d)"
          % (t, n, out, 100.0 * out / max(n, 1), 100.0 * na / max(n, 1),
             100.0 * tyout / max(ty, 1), tyout, ty))
alln = sum(res[t][0] for t in TIERS)
allout = sum(res[t][1] for t in TIERS)
print("%-8s %10d %10d %9.2f%%" % ("全体", alln, allout, 100.0 * allout / alln))

# 対照1: 頻度保存 — 各出現を「中国語コーパスでの頻度が近い一级字」に差し替える
random.seed(SEED)
bins = collections.defaultdict(list)
for c in pool:
    f = cnfreq.get(c, 0)
    b = 0 if f == 0 else (1 if f <= 2 else (2 if f <= 8 else (3 if f <= 30 else 4)))
    bins[b].append(c)


def ctrl_rate(counter, nrep=20):
    """出現ごとに『中国語頻度が同じ帯の一级字』へ無作為置換したときの圏外率"""
    acc = []
    for _ in range(nrep):
        o = n = 0
        for ch, v in counter.items():
            f = cnfreq.get(ch, 0)
            b = 0 if f == 0 else (1 if f <= 2 else (2 if f <= 8 else (3 if f <= 30 else 4)))
            cand = bins[b]
            for _i in range(v):
                r = cand[random.randrange(len(cand))]
                o += 1 if kl.get(r, klass(r)) == 'OUT' else 0
                n += 1
        acc.append(100.0 * o / max(n, 1))
    return sum(acc) / len(acc)


print("\n対照A(中国語頻度を保存して一级3500から無作為置換・20回平均):")
for t in TIERS:
    n, out, na, ty, tyout = res[t]
    cr = ctrl_rate(tok[t])
    print("  %-8s 実測 %6.2f%% / 対照 %6.2f%% / 比 %.2f" % (t, 100.0 * out / max(n, 1), cr,
                                                        (100.0 * out / max(n, 1)) / max(cr, 1e-9)))

# ================================================================
# 3. [C] 機構 — 「简化は高頻度字を襲った」仮説の直接検定
# ================================================================
print("\n" + "=" * 108)
print("■ [C] 機構の検定 — 費用が上位層に寄るなら、それは字選びの巧拙か構造か")
print("=" * 108)
print("仮説: 漢字簡化は【中国語で高頻度の字】を集中的に改変した。上位層は高頻度字を得るので")
print("      日本人費用は構造的に上位層へ寄る。→ 中国語コーパス頻度と圏外率の関係を直接見る")
print("\n%-18s %8s %10s %10s" % ("中国語コーパス頻度帯", "字種", "JIS圏外", "圏外率"))
for lo, hi, lab in ((1, 2, "1〜2回"), (3, 8, "3〜8回"), (9, 30, "9〜30回"), (31, 10 ** 9, "31回以上")):
    ss = [c for c in pool if lo <= cnfreq.get(c, 0) <= hi]
    o = sum(1 for c in ss if kl.get(c, klass(c)) == 'OUT')
    print("%-18s %8d %10d %9.1f%%" % (lab, len(ss), o, 100.0 * o / max(len(ss), 1)))
ss0 = [c for c in pool if cnfreq.get(c, 0) == 0]
print("%-18s %8d %10d %9.1f%%" % ("0回(未出)", len(ss0), sum(1 for c in ss0 if kl.get(c, klass(c)) == 'OUT'),
                                  100.0 * sum(1 for c in ss0 if kl.get(c, klass(c)) == 'OUT') / max(len(ss0), 1)))

print("\n画数による対照(簡化字は画数が少ない。画数を保存した置換での圏外率):")
sbins = collections.defaultdict(list)
for c in pool:
    sbins[min(stroke.get(c, 99), 20)].append(c)


def ctrl_stroke(counter, nrep=20):
    acc = []
    for _ in range(nrep):
        o = n = 0
        for ch, v in counter.items():
            cand = sbins.get(min(stroke.get(ch, 99), 20)) or pool
            for _i in range(v):
                r = cand[random.randrange(len(cand))]
                o += 1 if kl.get(r, klass(r)) == 'OUT' else 0
                n += 1
        acc.append(100.0 * o / max(n, 1))
    return sum(acc) / len(acc)


for t in TIERS:
    n, out, na, ty, tyout = res[t]
    print("  %-8s 実測 %6.2f%% / 画数保存対照 %6.2f%% / 比 %.2f"
          % (t, 100.0 * out / max(n, 1), ctrl_stroke(tok[t]),
             (100.0 * out / max(n, 1)) / max(ctrl_stroke(tok[t]), 1e-9)))

# ================================================================
# 4. 圏外字の全件表(TSV) — 上位は手作業で日本字を対応づける
# ================================================================
outchars = sorted([c for c in UC if kl.get(c, klass(c)) == 'OUT'],
                  key=lambda c: -sum(tok[t][c] for t in TIERS))
with io.open("_lens33_outside_jis_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("字\t延べ出現\t語根数\t主な層\t画数\t中国語コーパス頻度\n")
    for c in outchars:
        tt = collections.Counter({t: tok[t][c] for t in TIERS})
        f.write("%s\t%d\t%d\t%s\t%d\t%d\n" % (c, sum(tt.values()), used[c],
                                              tt.most_common(1)[0][0] if sum(tt.values()) else '-',
                                              stroke.get(c, 0), cnfreq.get(c, 0)))
print("\n圏外字 %d 種を _lens33_outside_jis_ledger.tsv に全件出力" % len(outchars))
print("延べ出現の多い順 上位40:")
print('  ' + ' '.join("%s(%d)" % (c, sum(tok[t][c] for t in TIERS)) for c in outchars[:40]))

# ================================================================
# 5. [D] 透明性 — 圏外字は「見て日本字が思い当たる」か(第31の字形機械を再利用)
# ================================================================
print("\n" + "=" * 108)
print("■ [D] 透明性 — 圏外字に『形の錨』はあるか(第31レンズの字形機械を再利用)")
print("=" * 108)
# ★対応表は手で与える。導出に形を使わないので、後で形の距離を測っても循環しない。
#   出典= 简体字とその日本(新字体・旧字体)対応。よく知られた対で、圏外字のうち延べ出現上位を優先。
JPMAP = {'义': '義', '书': '書', '车': '車', '电': '電', '鸟': '鳥', '鱼': '魚', '头': '頭', '长': '長',
        '时': '時', '为': '為', '现': '現', '样': '様', '们': '們', '还': '還', '应': '応', '终': '終',
        '习': '習', '训': '訓', '检': '検', '围': '囲', '护': '護', '说': '説', '进': '進', '劳': '労',
        '员': '員', '过': '過', '间': '間', '对': '対', '记': '記', '盐': '塩', '树': '樹', '风': '風',
        '测': '測', '动': '動', '计': '計', '压': '圧', '带': '帯', '热': '熱', '变': '変', '齿': '歯',
        '战': '戦', '线': '線', '镜': '鏡', '团': '団', '转': '転', '给': '給', '远': '遠', '结': '結',
        '环': '環', '倾': '傾', '满': '満', '兽': '獣', '值': '値', '无': '無', '气': '気', '单': '単',
        '节': '節', '肠': '腸', '经': '経', '贝': '貝', '脉': '脈', '异': '異', '兰': '蘭', '图': '図',
        '矿': '鉱', '红': '紅', '圣': '聖', '马': '馬', '龙': '竜', '伞': '傘', '疗': '療', '极': '極',
        '叶': '葉', '质': '質', '乐': '楽', '杀': '殺', '爱': '愛', '药': '薬', '阴': '陰', '顶': '頂',
        '鸡': '鶏', '鹰': '鷹', '发': '発', '盘': '盤', '话': '話', '铁': '鉄', '鸣': '鳴', '伪': '偽',
        '养': '養', '军': '軍', '剧': '劇', '后': '後', '层': '層', '难': '難', '爷': '爺', '边': '辺',
        '灯': '灯', '关': '関', '观': '観', '会': '会', '国': '国', '学': '学', '实': '実', '写': '写',
        '权': '権', '统': '統', '织': '織', '细': '細', '级': '級', '纸': '紙', '约': '約', '级': '級',
        '续': '続', '绿': '緑', '维': '維', '综': '綜', '缩': '縮', '织': '織', '绳': '縄', '纯': '純', '语': '語', '强': '強', '铜': '銅', '银': '銀', '铅': '鉛',
         '钟': '鐘', '钢': '鋼', '针': '針', '钱': '銭', '铺': '舗', '锁': '鎖', '锋': '鋒',
         '错': '錯', '铃': '鈴', '钉': '釘', '铸': '鋳', '锐': '鋭', '销': '銷', '锦': '錦'}
trans = {}
try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
    FONT = (r"C:\Windows\Fonts\simsun.ttc", 0)
    SZ, PAD = 64, 8
    CAN = SZ + 2 * PAD
    jis_pool = [chr(x) for x in range(0x4E00, 0xA000) if in_jis0208(chr(x))]
    tgt = [c for c in UC if kl.get(c, klass(c)) == 'OUT']
    print("JIS X 0208 の漢字 %d 字 を参照集合に、圏外の割り当て字 %d 字の最近傍を探す"
          % (len(jis_pool), len(tgt)))

    def render(chars):
        font = ImageFont.truetype(FONT[0], SZ, index=FONT[1])
        bi, bl = [], []
        for chx in chars:
            img = Image.new('L', (CAN, CAN), 0)
            ImageDraw.Draw(img).text((CAN // 2, CAN // 2), chx, font=font, fill=255, anchor='mm')
            a = np.asarray(img, dtype=np.float32) / 255.0
            bi.append((a > 0.5).astype(np.float32).ravel())
            b = np.asarray(img.filter(ImageFilter.GaussianBlur(3.0)), dtype=np.float32).ravel()
            bl.append(b / (np.linalg.norm(b) + 1e-9))
        return np.stack(bi), np.stack(bl)

    JB, JL = render(jis_pool)
    TB, TL = render(tgt)
    # 空グリフ(欠字)の混入検査
    empt = int((JB.sum(1) == 0).sum() + (TB.sum(1) == 0).sum())
    print("空グリフ(フォント欠字)の混入 = %d 字 (0 が正)" % empt)
    inter = TB @ JB.T
    uni = TB.sum(1)[:, None] + JB.sum(1)[None, :] - inter
    IOU = inter / np.maximum(uni, 1e-9)
    BLR = TL @ JL.T
    SIM = 0.5 * (IOU + BLR)          # 2指標の平均を『形の近さ』とする
    jidx = {c: i for i, c in enumerate(jis_pool)}
    tidx = {c: i for i, c in enumerate(tgt)}
    best = SIM.argmax(1)
    bestsim = SIM.max(1)

    seeds = [(a, b) for a, b in JPMAP.items() if a in tidx and b in jidx]
    print("\n較正: 手で与えた 简→日 対応のうち、简側が本当にJIS圏外だったもの %d 対" % len(seeds))
    # ★指標は「最近傍が正解か」ではなく【真の対応字の順位】にする。
    #   6,356字の中の1位を要求するのは人間の読字より遥かに厳しく、透明性を過小評価する。
    #   参照集合を2通り置いて感度も見る(全JIS / 日本語コーパスに20回以上出る字=常用相当)。
    common = [c for c in jis_pool if jpfreq[c] >= 20]
    cmask = np.array([jpfreq[c] >= 20 for c in jis_pool])
    print("  参照集合A = 全JIS X 0208漢字 %d 字 / 参照集合B = 日本語コーパス20回以上 %d 字"
          % (len(jis_pool), len(common)))
    # 偶然水準: 無作為なJIS字対の形の近さ
    rng = np.random.default_rng(20260802)
    ii = rng.integers(0, len(jis_pool), 40000)
    jj = rng.integers(0, len(jis_pool), 40000)
    ok = ii != jj
    chance = 0.5 * ((JB[ii[ok]] * JB[jj[ok]]).sum(1)
                    / np.maximum(JB[ii[ok]].sum(1) + JB[jj[ok]].sum(1)
                                 - (JB[ii[ok]] * JB[jj[ok]]).sum(1), 1e-9)
                    + (JL[ii[ok]] * JL[jj[ok]]).sum(1))
    sims, ranks, ranksB = [], [], []
    for a, b in seeds:
        i, j = tidx[a], jidx[b]
        s = float(SIM[i, j])
        r = int((SIM[i] > s).sum()) + 1
        rB = int((SIM[i][cmask] > s).sum()) + 1
        sims.append((s, a, b, jis_pool[best[i]], float(bestsim[i]), r, rB))
        ranks.append(r)
        ranksB.append(rB)
    sims.sort(reverse=True)
    print("  無作為なJIS字対の形の近さ: 中央 %.3f / 95%%点 %.3f"
          % (float(np.median(chance)), float(np.quantile(chance, 0.95))))
    q = np.quantile([s for s, *_ in sims], [0.1, 0.5, 0.9])
    print("  ★真の 简→日 対: 中央 %.3f (偶然の中央 %.3f の %.2f 倍・偶然95%%点を超える対 %.1f%%)"
          % (q[1], float(np.median(chance)), q[1] / float(np.median(chance)),
             100.0 * sum(1 for s, *_ in sims if s > float(np.quantile(chance, 0.95))) / len(sims)))
    rk = np.array(ranks)
    rkB = np.array(ranksB)
    print("  ★真の対応字の【順位】(近い順): 参照A 中央 %d位 / 1位 %.1f%% / 10位内 %.1f%% / 50位内 %.1f%%"
          % (int(np.median(rk)), 100.0 * (rk == 1).mean(), 100.0 * (rk <= 10).mean(),
             100.0 * (rk <= 50).mean()))
    print("                                 参照B 中央 %d位 / 1位 %.1f%% / 10位内 %.1f%% / 50位内 %.1f%%"
          % (int(np.median(rkB)), 100.0 * (rkB == 1).mean(), 100.0 * (rkB <= 10).mean(),
             100.0 * (rkB <= 50).mean()))
    print("\n  透明な対(上位12): " + ' '.join("%s→%s(%.2f/%d位)" % (a, b, s, r)
                                          for s, a, b, _, _, r, _rb in sims[:12]))
    print("  不透明な対(下位12): " + ' '.join("%s→%s(%.2f/%d位)" % (a, b, s, r)
                                          for s, a, b, _, _, r, _rb in sims[-12:]))
    ff = [(bs, a, b, bc, r) for s, a, b, bc, bs, r, _rb in sims if bc != b]
    ff.sort(reverse=True)
    print("\n★形の偽の友 = 真の対応字より別のJIS字の方が近い %d/%d 対 (上位12):" % (len(ff), len(sims)))
    print("  " + ' '.join("%s→[%s]≠%s(%.2f)" % (a, bc, b, bs) for bs, a, b, bc, r in ff[:12]))

    # 透明 = 真の対応字が参照Bで10位内。手作業対応のある字だけで層別に集計する(被覆も出す)
    trans.update({a: (rB <= 10) for (s, a, b, bc, bs, r, rB) in
             [(s, a, b, bc, bs, r, rB) for s, a, b, bc, bs, r, rB in sims]})
    print("\n%-8s %9s %10s %10s %10s" % ("層", "圏外率", "対応表被覆", "透明率", "★実効費用"))
    for t in TIERS:
        n, out, _na2, _ty, _to = res[t]
        cov = sum(v for ch, v in tok[t].items() if ch in trans)
        tr = sum(v for ch, v in tok[t].items() if trans.get(ch))
        r_out = 100.0 * out / max(n, 1)
        rt = tr / max(cov, 1)
        print("%-8s %8.2f%% %9.1f%% %9.1f%% %9.2f%%"
              % (t, r_out, 100.0 * cov / max(out, 1), 100.0 * rt, r_out * (1 - rt)))
    print("  ※透明率は手作業対応表がある字に限った値。被覆外の字は判定不能として除外している")

    # ★日本人が余分に払う1字あたりの見返り(第7レンズ=学習投資の回収率の圏外字版)
    print("\n★圏外字1字あたりの延べ出現(=余分な投資1単位の見返り):")
    for t in TIERS:
        n, out, _na2, _ty, tyout = res[t]
        print("  %-8s 圏外字 %3d 種で 延べ %5d 回 → 1字あたり %5.1f 回"
              % (t, tyout, out, out / max(tyout, 1)))
    # ★是正可能性: 圏外字の日本側対応字は、そもそも一级3500 に入っているか
    inpool = sum(1 for a, b in seeds if b in stroke)
    print("\n★是正余地の検定: 手で対応づけた %d 対のうち、日本側の字が一级3500 にも在る = %d 対 (%.1f%%)"
          % (len(seeds), inpool, 100.0 * inpool / max(len(seeds), 1)))
    print("  → 0%に近ければ、この費用は【割り当ての選択】ではなく【方針R2の字表選択】が生んでおり、")
    print("     割り当て側で下げる手段は原理的に存在しない(是正対象ではない)")
    with io.open("_lens33_shape_anchor_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
        f.write("圏外字\t延べ出現\t最近傍JIS字\t形の近さ\t手動対応字\t真対の近さ\t真対の順位(全JIS)\t真対の順位(常用相当)\t透明\n")
        for c in sorted(tgt, key=lambda c: -sum(tok[t][c] for t in TIERS)):
            i = tidx[c]
            mm = JPMAP.get(c, '')
            if mm in jidx:
                sv = float(SIM[i, jidx[mm]])
                rA = int((SIM[i] > sv).sum()) + 1
                rB = int((SIM[i][cmask] > sv).sum()) + 1
                ex = "%.3f\t%d\t%d\t%s" % (sv, rA, rB, 'yes' if rB <= 10 else 'no')
            else:
                ex = "\t\t\t判定不能"
            f.write("%s\t%d\t%s\t%.3f\t%s\t%s\n"
                    % (c, sum(tok[t][c] for t in TIERS), jis_pool[best[i]], float(bestsim[i]), mm, ex))
    print("  全 %d 字を _lens33_shape_anchor_ledger.tsv に出力" % len(tgt))
except ImportError as e:
    print("(numpy/PIL 不在のため [D] を省略: %s)" % e)

# ================================================================
# 5b. [E] 費用B = 同形異義 — 字形はJISにあるが日本語の語感と違う
# ================================================================
print("\n" + "=" * 108)
print("■ [E] 費用B = 同形異義 — 字形は日本にあるが、意味が日本語の語感とずれる字")
print("=" * 108)
print("検出器: CSV2890 の語で、割り当て字が【中国語訳には現れるが日本語訳には現れない】")
print("        字形が日本にある(JIS X 0208内)字に限る。字ごとに集計し、まとめて目視する")
cn_hit = collections.Counter()
jp_hit = collections.Counter()
seen = collections.Counter()
examples = collections.defaultdict(list)
for rec in csv_rows:
    w = (rec.get('Esperanto') or '').strip()
    ja = rec.get('Japanese_Trans') or ''
    zh = rec.get('Chinese_Trans') or ''
    if not w or not ja or not zh:
        continue
    segs = None
    for tokn in w.split(','):
        w0 = to_hsys(tokn.strip())
        for k in (w0.replace('/', '').replace('-', '').lower(), w0.lower(), w0):
            segs = bare2segs.get(k)
            if segs:
                break
        if segs:
            break
    if not segs or len(segs) != 1:
        continue
    d = roots.get(segs[0]) or roots.get(to_hsys(segs[0]).lower())
    if not d:
        continue
    for c in set(d['surf']):
        if not is_cjk(c) or klass(c) != 'J0':
            continue
        seen[c] += 1
        if c in zh:
            cn_hit[c] += 1
        if c in ja:
            jp_hit[c] += 1
        if c in zh and c not in ja:
            examples[c].append("%s=%s(中:%s/日:%s)" % (w.split(',')[0].strip(), d['surf'], zh[:12], ja[:12]))
cand = [(cn_hit[c] - jp_hit[c], c) for c in seen
        if cn_hit[c] >= 3 and jp_hit[c] == 0]
cand.sort(reverse=True)
print("\n対象= CSV2890 で単一語根に照合でき字形がJIS内 %d 字種" % len(seen))
print("★中国語訳に3回以上接地しながら日本語訳に一度も接地しない字 = %d 種" % len(cand))
print("(=中国語では自明だが日本語の語感では出てこない字。全件を目視する)\n")
for k, c in cand[:40]:
    print("  %s  中%d/日%d/計%d  %s" % (c, cn_hit[c], jp_hit[c], seen[c], ' | '.join(examples[c][:2])))
# ★全件を人手で判定した結果(再現可能なようにスクリプトに焼き込む)
VERDICT = {
    '机': ('★同形異義', '日=つくえ / 中=機械。helikoptero=直升机 を日本人は「直立する机」と読む。機は一级外'),
    '套': ('★同形異義', '日=常套の套 / 中=かぶせる物・一組。ganto=手套 が日本語の語感に無い'),
    '任': ('★同形異義', '日=任命・任務 / 中=どんな〜でも(任何)。ajn=任 は日本語側に用法が無い'),
    '胡': ('★同形異義', '日=胡椒など音写用 / 中=ひげ。barbo=胡'),
    '愿': ('★同形異義', '日=つつしむ(稀) / 中=願う。実質 願 の簡体で、日本人には別字に見える'),
    '那': ('★語感に無い', '日=刹那・旦那の音写 / 中=あの。相関詞 ti- 系の描画'),
    '庄': ('○部分一致', '日=庄屋 / 中=村・荘厳(荘の簡体でもある)。solena=庄 は荘厳で通じる'),
    '租': ('○部分一致', '日=租税・租借 / 中=借りる。租借で通じる'),
    '气': ('○字体差', '気/氣 の偏形。日本人も読める'), '无': ('○字体差', '無 の古字'),
    '烟': ('○字体差', '煙 の異体字'), '册': ('○字体差', '冊 の異体字'),
    '卷': ('○字体差', '巻 の旧字体'), '效': ('○字体差', '効 の旧字体'),
    '收': ('○字体差', '収 の旧字体'), '沙': ('○字体差', '砂 の異体字(沙漠)'),
    '某': ('○偽陽性', '日本語でも「某氏」=ある。日本語訳がカナ表記だったため検出された'),
    '鞋': ('○偽陽性', '日本語でも靴の意(草鞋)。訳語がカナ'),
    '腿': ('○偽陽性', '日本語でも脚の意(大腿)。訳語がカナ'),
    '瓜': ('○偽陽性', '意味は完全一致。訳語がカナ(キュウリ/カボチャ)'),
    '智': ('○偽陽性', '意味は完全一致(知性=智)。訳語が「知」を使った'),
    '不': ('○偽陽性', '意味は完全一致(否定)。訳語が「ない」とかな書き'),
}
print("\n★全 %d 件の人手判定:" % len(cand))
vc = collections.Counter()
for k, c in cand:
    v, why = VERDICT.get(c, ('(未判定)', ''))
    vc[v] += 1
    print("  %s %-8s %s" % (c, v, why))
print("\n  内訳: " + ' / '.join("%s %d件" % (k, v) for k, v in vc.most_common()))
print("  → 真に日本語の語感と衝突するのは %d 字。いずれも中国語としては正しく(第17レンズ=字面接地93.1%%)、"
      % (vc['★同形異義'] + vc['★語感に無い']))
print("     日本側の対応字(機・願 等)は一级3500 に存在しないため差し替え先が無い")
jp_alt = {'机': '機', '愿': '願', '套': '套', '任': '任', '胡': '鬚', '那': '那'}
miss = [(a, b) for a, b in jp_alt.items() if b not in stroke]
print("     実測: 日本語側で自然な字 %d 件中 %d 件が一级3500 に不在 (%s)"
      % (len(jp_alt), len(miss), ' '.join("%s→%s" % (a, b) for a, b in miss)))
with io.open("_lens33_homograph_ledger.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("字\t判定\t理由\t中国語訳接地\t日本語訳接地\t出現語数\t例\n")
    for k, c in cand:
        v, why = VERDICT.get(c, ('(未判定)', ''))
        f.write("%s\t%s\t%s\t%d\t%d\t%d\t%s\n"
                % (c, v, why, cn_hit[c], jp_hit[c], seen[c], ' | '.join(examples[c][:4])))
print("\n全 %d 件を _lens33_homograph_ledger.tsv に出力" % len(cand))

# ================================================================
# 6. [F] 実配信テキストでの実費用
# ================================================================
print("\n" + "=" * 108)
print("■ [F] 実配信テキスト(ユーザー自身の漢字化日記)での1文あたりの実費用")
print("=" * 108)
txt = []
for p in CORPUS:
    if os.path.exists(p):
        txt.append(io.open(p, encoding='utf-8-sig').read())
body = '\n'.join(txt)
# ★集成ファイルには日本語の見出し・凡例が混じる(「### 第16日 — 奈良から真岡への帰還と…」)。
#   これを数えると日本の漢字だけが分母に足されて圏外率が下がる(素朴集計 16.4% → 実は過小)。
#   漢字化エスペラント本文は【仮名を一切含まない】ので、それを判別子にする。
raw_lines = [l.strip() for l in body.split('\n') if l.strip()]
naive = [l for l in raw_lines if any(is_cjk(c) for c in l) and not l.startswith('|')]
sent = []
for l in naive:
    if l.startswith('#') or l.startswith('-') or has_kana(l):
        continue
    l = l.replace('**', '').replace('〔標題〕', '')
    l = re.sub(r'^\d+\.\s*', '', l)
    if any(is_cjk(c) for c in l):
        sent.append(l)
nk = sum(1 for l in naive for c in l if is_cjk(c))
print("(素朴に全行を数えると漢字 %d 字。だが日本語の見出し・凡例が混じるので、仮名を含む行と"
      "見出しを除いて漢字化エスペラント本文だけに絞ると %d 字)"
      % (nk, sum(1 for l in sent for c in l if is_cjk(c))))
ch = collections.Counter()
for l in sent:
    for c in l:
        if is_cjk(c):
            ch[c] += 1
n = sum(ch.values())
o = sum(v for c, v in ch.items() if kl.get(c, klass(c)) == 'OUT')
na = sum(v for c, v in ch.items() if jpfreq[c] == 0)
print("行 %d / 漢字 延べ %d 種 %d" % (len(sent), n, len(ch)))
print("★JIS圏外 延べ %d (%.1f%%) 種 %d" % (o, 100.0 * o / max(n, 1),
                                       sum(1 for c in ch if kl.get(c, klass(c)) == 'OUT')))
print("  日本語コーパス未出 延べ %d (%.1f%%)" % (na, 100.0 * na / max(n, 1)))
per = [sum(1 for c in l if is_cjk(c) and kl.get(c, klass(c)) == 'OUT') for l in sent]
print("  1行あたり圏外字 平均 %.2f 字 / 圏外字ゼロの行 %d/%d (%.1f%%)"
      % (sum(per) / max(len(per), 1), sum(1 for x in per if x == 0), len(per),
         100.0 * sum(1 for x in per if x == 0) / max(len(per), 1)))
print("  実配信での圏外字 上位20: " + ' '.join("%s(%d)" % (c, v) for c, v in
                                          sorted(((c, v) for c, v in ch.items()
                                                  if kl.get(c, klass(c)) == 'OUT'),
                                                 key=lambda x: -x[1])[:20]))
if trans:
    cov = sum(v for c, v in ch.items() if c in trans)
    tr = sum(v for c, v in ch.items() if trans.get(c))
    print("  うち手作業対応表で判定できる %d 回(圏外の %.1f%%)。そのうち透明(真の対応字が常用相当の10位内)"
          " = %d 回 %.1f%%" % (cov, 100.0 * cov / max(o, 1), tr, 100.0 * tr / max(cov, 1)))
    print("  → 実配信1行(平均 %.1f 漢字)あたり『日本人が形から思い当たれない字』は %.1f 字"
          % (sum(ch.values()) / max(len(sent), 1),
             (o - tr * (o / max(cov, 1))) / max(len(sent), 1) if cov else float('nan')))

print("\n層別の圏外字 上位10(何が費用を作っているか):")
for t in TIERS:
    top = sorted(((c, v) for c, v in tok[t].items() if kl.get(c, klass(c)) == 'OUT'),
                 key=lambda x: -x[1])[:10]
    print("  %-8s %s" % (t, ' '.join("%s(%d)" % (c, v) for c, v in top)))

# ================================================================
# 7. 総括と限界
# ================================================================
print("\n" + "=" * 108)
print("■ 総括")
print("=" * 108)
print("""1. 費用は実在する。割り当て字種の 30.1% (681/2261) は JIS X 0208 の外にあり、
   実配信テキストでは漢字の 17.1% がそれに当たる(1行平均 7.7 字)。
   中国人読者の字形費用はゼロなので、これは体系が持つ非対称性そのものである。

2. ★だが優先順位で守れる類の費用ではない。内容3層の圏外率は 29.6/27.6/23.9% とほぼ平坦で、
   中国語頻度を保存した対照(28.5/28.8/28.9%)・画数を保存した対照(30.3/29.6/29.9%)も同じく平坦。
   比は 1.04/0.96/0.83 で、最優先層は「中立」、最下位層がわずかに安い。
   層別圏外率をサイドカー×F重みという別経路で再計算しても順序は同じ(9.03/32.35/32.26/26.61%)。

3. ★是正余地は原理的に存在しない。手で対応づけた 简→日 122 対のうち、日本側の字が
   一级3500 にも在るものは 0 対。一级3500 は简体字の字表なので、日本側の字形は定義上そこに無い。
   費用は【割り当ての選択】ではなく【方針 R2 の字表選択】が生んでいる。

4. ★優先順位が効いている所は別にある = 1字あたりの見返り。
   圏外字を1字覚えたときの延べ出現は 文法層 70.4 > CSV2890 31.8 > PEJVO 10.8 > PIV 5.0 で完全単調。
   日本人が余分に払う投資は、回収率の高い層に集中している(第7レンズの構造が費用側にも成り立つ)。
   さらに配信の延べ出現の 29.5% を占める文法層の圏外率は 9.87% = 対照の 0.37 倍で、
   最も繰り返される層が最も安い。

5. 費用B(同形異義)は小さい。CSV2890 で検出器にかかった 22 字を全件人手判定して、
   真に日本語の語感と衝突するのは 6 字(机=つくえ/機械・套・任・胡・愿・那)。
   8 字は旧字体・異体字(気/無/煙/冊/巻/効/収/砂)で日本人にも読め、6 字は訳語がカナだった偽陽性。
   6 字の日本側の自然な字(機・願・鬚)は一级3500 に無く、差し替え先が無い。

★是正 0 件。データは一切変更していない。""")
print("=" * 108)
print("■ この測定の限界(先に開示する)")
print("=" * 108)
print("""a. 透明性は画素の形だけで測っている。人間は部首・音符・文脈を使うので、
   本レンズの透明率(常用相当の10位内 = 59.8%)は【下限】である。
b. 简→日 対応表は手作業の 122 対で、圏外字の延べ出現の 39.5〜56.3% しか覆っていない。
   層ごとに被覆が違うので【透明率の層間比較は交絡している】(advisory 扱い)。
c. JIS X 0208 は 6,356 字で常用漢字 2,136 字よりずっと広い。
   「JIS内=読める」は日本人読者に有利な側に倒した仮定であり、真の費用はこれより大きい。
d. 日本語コーパス(語釈 147k 字)への出現有無は稀な日本漢字を偽陽性で拾う。
   主軸を規格判定に置き、コーパスは第2軸に留めたのはそのため。
e. 方針書が挙げる第3の読者【非漢字圏学習者】については本レンズは何も測っていない。
f. 先行レンズの追認: 同じ日記コーパスを使う第31レンズは仮名を含む行と # 行を既に除外していた
   (_lens31_glyph_discriminability.py:596-598)ので、同じ混入は起きていない。
   本レンズが素朴集計との差として示した 727 字(7.3%)は「その除外を入れなかったら」の大きさ。
   第31方式でも残るのは〔標題〕ラベルの 50 字(0.5%)だけで、結論に影響しない。""")
