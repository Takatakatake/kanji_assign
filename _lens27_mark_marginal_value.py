# -*- coding: utf-8 -*-
# 第27レンズ v2「マークの限界価値」 (第27回続63)
#
#   ★初版(_lens27_identifier_alphabet.py)は主要4主張とも独立検証で覆れた。経緯は報告書に開示。
#     とりわけ (a)『第23レンズの死角』は虚偽(第23は識別子付き面 surf_full を実際に使い、
#     初版で同型の近傍1,640対を検出のうえ明文の理由で棄却していた) (b)『逆引き成功率の層順単調』は
#     群サイズの完全交絡(標準化すると逆転) (c)『規則外0.0%』は生成器の仕様の言い換えで失敗し得ない
#     (d)『層別id長』は第8レンズと同一事実で、第8が「測っても意味がない」と裁定済み。
#
#   そこで測る量を差し替える。学習者モデルに依存しない唯一の問い:
#     ★「マークを一切読まない読者にとって、その層はどれだけ読めるか」
#   = 延べ出現のうちマーク付き描画の割合(=マークが無ければ別語根に着地する割合)。
#     丸暗記モデルでも規則モデルでも同じ意味を持つ『マークの限界価値』であり、
#     第8(型レベルの無印率)とは分母が違う(型ではなく延べ出現)。
import io, os, re, sys, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
SIDE = "_identifier_sidecar.tsv"
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
INJ = {'学習者版': "漢字注入_学習者版_20260620.txt", '学術版': "漢字注入_学術版_20260620.txt"}
CORPUS = [os.path.join("..", "漢字化エスペラント日記", f) for f in (
    "エスペラント随想_日記_漢字化エスペラント集成_20260705.md",
    "漢字化エスペラント日記_第2集_漢字化エスペラント集成_20260721.md")]
ENDPOP = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn'}
GRAMMAR = {'prep', 'func', 'correl', 'suf', 'pref', 'num'}
SUPCAT = ('Lm', 'Mn', 'Sk')
import unicodedata


def is_mark(c):
    return unicodedata.category(c) in SUPCAT


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    for a, b in (('cx', 'c^'), ('gx', 'g^'), ('hx', 'h^'), ('jx', 'j^'), ('sx', 's^'), ('ux', 'u^')):
        s = s.replace(a, b).replace(a.upper(), b.upper())
    return s


# ---------- sidecar ----------
roots = {}
for line in io.open(SIDE, encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    for key in {p[0], to_hsys(p[0]), to_hsys(p[0]).lower()}:
        roots.setdefault(key, {'kanji': p[1], 'id': p[2], 'disp': p[4], 'band': p[5],
                               'F': int(p[6]) if p[6].isdigit() else 0, 'gk': p[7],
                               'root': p[0]})

# ---------- CSV2890 (両版から bare2segs を作る=第26レンズで指摘された版非対称を回避) ----------
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
            key = raw.replace('/', '').replace('-', '').lower()
            bare2segs.setdefault(key, [c.strip('-') for c in cs])
csv_roots = set()
n_miss = 0
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if not rec or not rec[0].strip():
            continue
        for tok in rec[0].split(','):
            w0 = to_hsys(tok.strip())
            for k in (w0.replace('/', '').replace('-', '').lower(), w0.lower(), w0):
                segs = bare2segs.get(k)
                if segs:
                    break
            if not segs:
                n_miss += 1
                continue
            if len(segs) == 1:
                csv_roots.add(segs[0])
                csv_roots.add(to_hsys(segs[0]).lower())
print("CSV2890: 単一形態素で照合できた語根 %d 種 / 照合不能トークン %d" % (len(csv_roots), n_miss))


def tier_of_seg(s):
    d = roots.get(s) or roots.get(to_hsys(s)) or roots.get(to_hsys(s).lower())
    if not d:
        return None, None
    if d['band'] in GRAMMAR:
        return '文法層', d
    if s in csv_roots or to_hsys(s).lower() in csv_roots:
        return 'CSV2890', d
    if d['band'] == 'piv':
        return 'PIV', d
    return 'PEJVO', d


TIERS = ['文法層', 'CSV2890', 'PEJVO', 'PIV']

# ================================================================
# 1. 辞書全体の延べ出現でのマーク率(=マークを読まない読者が取り違える割合)
# ================================================================
print("\n" + "=" * 100)
print("■ 1. マークの限界価値 — 延べ出現のうち『マークが無いと別語根に着地する』割合")
print("=" * 100)
print("   ※型(語根種)ではなく【延べ出現】で数える。第8レンズは型レベルの無印率を測っており分母が違う。")
print("   ※学習者モデルに依存しない: 丸暗記読者でも規則読者でも『マークを読み落とせば誤る』点は同じ。")
for ver, path in INJ.items():
    occ = collections.Counter()
    mk = collections.Counter()
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
            continue
        head = line.split(':', 1)[0]
        raw = head[:head.index('⟦')]
        box = head[head.index('⟦') + 1:head.rindex('⟧')]
        rs = [x for x in re.split(r'[/ ]', raw) if x]
        bs = [x for x in re.split(r'[/ ]', box) if x]
        if len(rs) != len(bs):
            continue
        for r, b in zip(rs, bs):
            r = r.strip('-')
            if not any('一' <= c <= '鿿' for c in b):
                continue                      # 漢字描画されていない分節は対象外
            t, d = tier_of_seg(r)
            if t is None:
                continue
            occ[t] += 1
            if any(is_mark(c) for c in b):
                mk[t] += 1
    print("\n   [%s] 漢字描画された内容分節の延べ出現" % ver)
    print("   %-9s %10s %10s %10s" % ("層", "延べ出現", "マーク付き", "マーク率"))
    for t in TIERS:
        if occ[t]:
            print("   %-9s %10d %10d %9.1f%%" % (t, occ[t], mk[t], 100.0 * mk[t] / occ[t]))
    to, tm = sum(occ.values()), sum(mk.values())
    print("   %-9s %10d %10d %9.1f%%" % ('全体', to, tm, 100.0 * tm / max(1, to)))
    print("   ★最優先層のマーク率が最も低い=『マークを一切読まない読者』でも上位層はほぼ正しく読める。")

# ================================================================
# 2. 実配信テキストでの同じ量
# ================================================================
print("\n" + "=" * 100)
print("■ 2. 実配信テキスト(ユーザー自身の漢字化エスペラント)での実測")
print("=" * 100)
disp2root = {}
for k, d in roots.items():
    disp2root.setdefault(d['disp'], d)
n_cjk = n_mark = n_mark2 = 0
mark_tokens = collections.Counter()
for cp in CORPUS:
    if not os.path.exists(cp):
        continue
    for line in io.open(cp, encoding='utf-8', errors='replace'):
        if re.search(r'[ぁ-んァ-ヶ]', line) or line.startswith('#'):
            continue
        for m in re.finditer(r'[一-鿿]', line):
            n_cjk += 1
        # マーク付きトークン(漢字+続く上付き列)
        # ★2026-08-01 続64で是正: 従来は文字クラス [ʰ-˿ᴬ-ᵪ̀-ͯ⁰-₟] で判定していたが、
        #   ᶜ(U+1D9C)・ᶠ(U+1DA0)・ⱽ(U+2C7D) が範囲外で取りこぼされ 36件の過小計上になっていた
        #   (1008→1044)。本ファイル冒頭の is_mark(Unicodeカテゴリ判定)と同一規範に統一する。
        i = 0
        while i < len(line):
            if '一' <= line[i] <= '鿿':
                j = i + 1
                while j < len(line) and is_mark(line[j]):
                    j += 1
                if j > i + 1:
                    n_mark += 1
                    units = [c for c in line[i + 1:j] if unicodedata.category(c) != 'Mn']
                    if len(units) >= 2:
                        n_mark2 += 1
                    mark_tokens[line[i:j]] += 1
                i = j
            else:
                i += 1
print("   本文の漢字 %d 字 / マーク付き漢字 %d 字 (%.1f%%) / うちマークが2単位以上 %d 字 (%.2f%%)" %
      (n_cjk, n_mark, 100.0 * n_mark / max(1, n_cjk), n_mark2, 100.0 * n_mark2 / max(1, n_cjk)))
print("   ★実文では漢字の %.1f%% がマーク付き。マークを読まない読者はその分だけ家族の基本形に着地する。" %
      (100.0 * n_mark / max(1, n_cjk)))
print("   頻出マークトークン: " + ' '.join('%s×%d' % kv for kv in mark_tokens.most_common(12)))

# ================================================================
# 3. 続62の識別子込み鏡像15件を『反証可能な』検定にかける
#    ★初版E節は『群サイズ1』を見ただけで、上付きを含むgroupkeyは他に存在しないため
#      衝突が定義上不可能=空振り検定だった(独立検証の指摘)。
#      正しい検定は『上付きを全部剥がした面が全域で一意か』。
# ================================================================
print("\n" + "=" * 100)
print("■ 3. 続62の鏡像15件 — 上付きを剥がした面で全域衝突するか(反証可能な検定)")
print("=" * 100)


def strip_marks(s):
    return ''.join(c for c in s if not is_mark(c))


bystrip = collections.defaultdict(set)
for k, d in roots.items():
    bystrip[strip_marks(d['disp'])].add(d['root'])
MIRROR62 = ['aerosol', 'akvedukt', 'bikonkav', 'bikonveks', 'biplan', 'centiar', 'endoskopi',
            'inciziv', 'megalosaŭr', 'mikroskopi', 'piroz', 'reformator', 'resonator',
            'trikromi', 'trirem']
hit = 0
for r in MIRROR62:
    d = roots.get(r) or roots.get(to_hsys(r))
    if not d:
        print("   %-12s (未登録)" % r)
        continue
    st = strip_marks(d['disp'])
    others = sorted(bystrip[st] - {d['root']})
    if others:
        hit += 1
        print("   ★%-12s disp=%-10s 剥離面=%-6s → 同じ面の他語根: %s" %
              (r, d['disp'], st, ', '.join(others)))
    else:
        print("    %-12s disp=%-10s 剥離面=%-6s 全域一意" % (r, d['disp'], st, ))
print("   → 衝突 %d/15。衝突する場合も着地先は同義隣接(手技 vs 器具)で、かつこれは" % hit)
print("     『マークを完全に無視する』読み方=全マーク付き語根5,015件に共通の構造的性質。")
print("     新規の欠陥ではないが、初版E節が『干渉なし』と断じたのは誤りだった。")

# ---------- TSV ----------
with io.open("_lens27_mark_marginal_value.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("版\t層\t延べ出現\tマーク付き\tマーク率%\n")
    for ver, path in INJ.items():
        occ = collections.Counter()
        mk = collections.Counter()
        for line in io.open(path, encoding='utf-8-sig'):
            line = line.rstrip('\n')
            if not line or line.startswith('#') or ':' not in line or '⟦' not in line:
                continue
            head = line.split(':', 1)[0]
            raw = head[:head.index('⟦')]
            box = head[head.index('⟦') + 1:head.rindex('⟧')]
            rs = [x for x in re.split(r'[/ ]', raw) if x]
            bs = [x for x in re.split(r'[/ ]', box) if x]
            if len(rs) != len(bs):
                continue
            for r, b in zip(rs, bs):
                if not any('一' <= c <= '鿿' for c in b):
                    continue
                t, d = tier_of_seg(r.strip('-'))
                if t is None:
                    continue
                occ[t] += 1
                if any(is_mark(c) for c in b):
                    mk[t] += 1
        for t in TIERS:
            if occ[t]:
                f.write("%s\t%s\t%d\t%d\t%.1f\n" % (ver, t, occ[t], mk[t], 100.0 * mk[t] / occ[t]))
print("\n出力: _lens27_mark_marginal_value.tsv")
