# -*- coding: utf-8 -*-
# 第26レンズ「配信ストリームの分節一意性」 v3 (第27回続60)
#
#   読字の連鎖は 文字列→トークン→語根→意味。トークン→語根(第16=逆引き99.7%一意)・
#   語根→意味(第17/18=接地)・語面どうしの混同(第23=近傍衝突)は測定済みだが、
#   最初の一段【境界の無い配信文字列から、意図されたトークン分節を一意に読み戻せるか】は
#   未測定だった(第25の批判[C5]=学⊂化学の包含対6,886が積み残した問い)。
#
#   ★設計1(比較測定): 同じ語を2表記系で同じパーサにかけ解析数を比較。
#     B = 素のエスペラント(raw綴り連結)を rawトークン表で解析した分節数
#     K = 漢字化配信形(⟦⟧連結)を 描画トークン表で解析した分節数
#     ラテン固有の再分節曖昧性(amas→am·as/a·mas)は両側で相殺され、K>B だけが
#     【漢字化が新たに持ち込んだ曖昧性】として残る。
#   ★設計2(CJK署名): 読者が実際に直面する選択は【CJK含みトークンの切り方】だけ。
#     解析の同値類 = CJK含みトークンの列+その間のラテン文字列(署名)。
#     混成トークン(何u/那o/kuri疗 等=相関詞含む521種)はCJK含みトークンとして丸ごと扱う。
#     ラテンのみの区間は「ギャップ」(ラテントークンで分節可能なことだけ検査)。
#   ★設計3(復号重大度): Kcjk>1 の語は、各解析を token→raw 対応で復号して比較する。
#     S0 = 全解析が同一のエスペラント語に復号(完全に無害。同时→同·时=samtempの類)
#     S1 = 復号が異なるが代替は語彙に無い綴り(読者の語彙が自己修正する)
#     S2 = 代替が実在の別語に復号(真の誤読リスク)★これだけが本当の危険
#
#   ハイフンは配信面で可視の境界(此-年e)なので '-' で小語に分割して独立に解析する。
import io, os, re, sys, csv as _csv, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = {'学習者版': "漢字注入_学習者版_20260620.txt", '学術版': "漢字注入_学術版_20260620.txt"}
CSVF = "30_重要語彙CSV_日中対照_2890語/2890 Gravaj Esperantaj Vortoj kun Signifoj en la Japana, Ĉina.csv"
CORPUS = [os.path.join("..", "漢字化エスペラント日記", f) for f in (
    "エスペラント随想_日記_漢字化エスペラント集成_20260705.md",
    "漢字化エスペラント日記_第2集_漢字化エスペラント集成_20260721.md")]
CAP = 1000


def is_latin(c):
    return ('a' <= c <= 'z') or ('A' <= c <= 'Z') or c == '^'


def has_cjk_or_sym(t):
    return any(not is_latin(c) for c in t)


def subsplit(seg):
    """分節をハイフンでさらに割る(配信面で可視の境界)"""
    return [x for x in seg.split('-') if x]


# ---------- 見出し ----------
def load_entries(path):
    entries, skipped = [], 0
    gloss = {}
    ln = 0
    for line in io.open(path, encoding='utf-8-sig'):
        ln += 1
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head, g = line.split(':', 1)
        if '⟦' in head:
            raw = head[:head.index('⟦')]
            box = head[head.index('⟦') + 1:head.rindex('⟧')]
        else:
            raw, box = head, head
        rws, bws = raw.split(' '), box.split(' ')
        if len(rws) != len(bws):
            skipped += 1
            continue
        pairs, ok = [], True
        for rw, bw in zip(rws, bws):
            rs = [s for s in rw.split('/') if s]
            bs = [s for s in bw.split('/') if s]
            if len(rs) != len(bs):
                ok = False
                break
            pairs.append((rs, bs))
        if ok:
            entries.append((ln, pairs))
            if ' ' not in raw:
                b = raw.replace('/', '').replace('-', '').lower()
                if b not in gloss:
                    gloss[b] = g
        else:
            skipped += 1
    return entries, skipped, gloss


TAG = re.compile(r'【[^】]*】|\{[^}]*\}|［[^］]*］|《[^》]*》|＝|=|>>')


def syn_pair(a, b, gloss):
    """同義対か: 語釈の相互参照(=X/>>X)または語釈の実質重複(第23レンズの同義判定と同型)。
       屈折形は基本形に正規化してから語釈を引く"""
    ga = next((gloss[v] for v in infl_variants(a) if v in gloss), '')
    gb = next((gloss[v] for v in infl_variants(b) if v in gloss), '')
    if not ga or not gb:
        return False
    la, lb = ga.lower(), gb.lower()
    for u, x in (('ĉ', 'c^'), ('ĝ', 'g^'), ('ĥ', 'h^'), ('ĵ', 'j^'), ('ŝ', 's^'), ('ŭ', 'u^')):
        la, lb = la.replace(u, x), lb.replace(u, x)
    if len(b) >= 4 and b[:max(4, len(b) - 1)] in la:
        return True
    if len(a) >= 4 and a[:max(4, len(a) - 1)] in lb:
        return True
    ca = set(TAG.sub('', ga))
    cb = set(TAG.sub('', gb))
    ca = {c for c in ca if '一' <= c <= '鿿' or 'ぁ' <= c <= 'ヿ'}
    cb = {c for c in cb if '一' <= c <= '鿿' or 'ぁ' <= c <= 'ヿ'}
    if ca and cb:
        j = len(ca & cb) / max(1, len(ca | cb))
        if j >= 0.4:
            return True
    return False


# ---------- 全解析数DP(比較測定用) ----------
class Parser:
    def __init__(self, tokens):
        self.by_first = collections.defaultdict(list)
        for t in tokens:
            if t:
                self.by_first[t[0]].append(t)
        self.cache = {}

    def count(self, s):
        if s in self.cache:
            return self.cache[s]
        n = len(s)
        dp = [0] * (n + 1)
        dp[n] = 1
        for i in range(n - 1, -1, -1):
            tot = 0
            for t in self.by_first.get(s[i], ()):
                if s.startswith(t, i):
                    tot += dp[i + len(t)]
                    if tot >= CAP:
                        tot = CAP
                        break
            dp[i] = tot
        self.cache[s] = dp[0]
        return dp[0]


# ---------- CJK署名DP: CJK含みトークン+有効なラテンギャップ ----------
class SigParser:
    """解析の同値類(CJK含みトークンの位置列)を数える/列挙する。
       遷移: 位置iから (a)CJK含みトークン1個 (b)ラテンギャップ(ラテン表で分節可能な
       ラテン文字列)を1回=直後はCJK含みトークンか語末。ギャップ連続は禁止=二重計数なし。"""
    def __init__(self, cjk_tokens, latin_tokens):
        self.by_first = collections.defaultdict(list)
        for t in cjk_tokens:
            if t:
                self.by_first[t[0]].append(t)
        self.lat = Parser(latin_tokens)
        self.cache = {}

    def _latin_ok(self, s):
        return bool(s) and all(is_latin(c) for c in s) and self.lat.count(s) > 0

    def count(self, s):
        if s in self.cache:
            return self.cache[s]
        n = len(s)
        # dpT[i] = iからCJKトークンで始まる解析数 / dp[i] = iから(ギャップ許可で)始まる解析数
        dpT = [0] * (n + 1)
        dp = [0] * (n + 1)
        dpT[n] = dp[n] = 1
        for i in range(n - 1, -1, -1):
            tot = 0
            for t in self.by_first.get(s[i], ()):
                if s.startswith(t, i):
                    tot = min(CAP, tot + dp[i + len(t)])
            dpT[i] = tot
            g = tot
            if is_latin(s[i]):
                j = i
                while j < n and is_latin(s[j]):
                    j += 1
                # ギャップ終端はCJKトークン開始点(=dpT)か語末のみ
                for e in range(i + 1, j + 1):
                    if self._latin_ok(s[i:e]) and (e == n or dpT[e] > 0):
                        g = min(CAP, g + (1 if e == n else dpT[e]))
                # 注: ラテン先頭からCJKトークン(混成)が始まる場合は上のtotに含まれる
            dp[i] = g
        self.cache[s] = dp[0]
        return dp[0]

    def parses(self, s, limit=8):
        out = []

        def rec(i, acc, gap_ok):
            if len(out) >= limit:
                return
            if i == len(s):
                out.append(list(acc))
                return
            for t in self.by_first.get(s[i], ()):
                if s.startswith(t, i):
                    acc.append(('T', t))
                    rec(i + len(t), acc, True)
                    acc.pop()
            if gap_ok and is_latin(s[i]):
                j = i
                while j < len(s) and is_latin(s[j]):
                    j += 1
                for e in range(i + 1, j + 1):
                    if self._latin_ok(s[i:e]):
                        nxt_ok = (e == len(s)) or any(
                            s.startswith(t, e) for t in self.by_first.get(s[e], ()))
                        if nxt_ok:
                            acc.append(('G', s[i:e]))
                            rec(e, acc, False)
                            acc.pop()
        rec(0, [], True)
        return out


# ---------- CSV2890 ----------
csv_bare = set()
with io.open(CSVF, encoding='utf-8-sig') as f:
    rd = _csv.reader(f)
    next(rd, None)
    for rec in rd:
        if rec and rec[0].strip():
            for tok in rec[0].split(','):
                w = tok.strip()
                for u, x in (('ĉ', 'c^'), ('ĝ', 'g^'), ('ĥ', 'h^'), ('ĵ', 'j^'), ('ŝ', 's^'), ('ŭ', 'u^')):
                    w = w.replace(u, x)
                # ハイフンも除去(接辞見出し -a/-ant- 等82件が見出しbareと照合できるように。
                # v4の照合漏れで98語がPEJVO/PIVへ誤帰属していた=独立検証の指摘)
                csv_bare.add(w.replace('/', '').replace('-', '').lower())


def infl_variants(w):
    """屈折形→基本形の正規化候補(S2照合用。v4はattestedに屈折形が無くS2を+11件見逃した)"""
    out = {w}
    x = w
    if x.endswith('n') and len(x) > 2:
        x = x[:-1]
        out.add(x)
    if x.endswith('j') and len(x) > 2:
        x = x[:-1]
        out.add(x)
    for suf in ('as', 'is', 'os', 'us'):
        if x.endswith(suf) and len(x) > 3:
            out.add(x[:-2] + 'i')
    if x.endswith('u') and len(x) > 2:
        out.add(x[:-1] + 'i')
    return out


def tier_of(ln, raw_bare):
    if raw_bare in csv_bare:
        return 'CSV2890'
    if ln <= 44104:
        return 'PEJVO'
    if ln <= 44440:
        return '追補'
    return 'PIV'


TIERS = ['CSV2890', 'PEJVO', '追補', 'PIV']

# ================================================================
grand = {}
for ver, path in INJ.items():
    entries, skipped, gloss = load_entries(path)
    raw_tokens, box_tokens = set(), set()
    tok2raws = collections.defaultdict(collections.Counter)
    attested = set()
    for ln, pairs in entries:
        for rs, bs in pairs:
            attested.add(''.join(rs).replace('-', '').lower())
            for r, b in zip(rs, bs):
                for rr in subsplit(r):
                    raw_tokens.add(rr)
                for bb in subsplit(b):
                    box_tokens.add(bb)
                if len(subsplit(r)) == 1 and len(subsplit(b)) == 1:
                    tok2raws[subsplit(b)[0]][subsplit(r)[0]] += 1
    cjk_toks = {t for t in box_tokens if has_cjk_or_sym(t)}
    lat_toks = box_tokens - cjk_toks
    P_raw = Parser(raw_tokens)
    P_box = Parser(box_tokens)
    SP = SigParser(cjk_toks, lat_toks)
    print("=" * 100)
    print("■ %s: 見出し %d (分節数不一致スキップ %d) / rawトークン %d / 描画トークン %d (CJK含み %d・ラテン %d)" %
          (ver, len(entries), skipped, len(raw_tokens), len(box_tokens), len(cjk_toks), len(lat_toks)))
    print("=" * 100)

    stat = collections.defaultdict(lambda: [0] * 8)   # [語数,B=1,K=1,K>B,K<B,Sig=1,Sig>1,K0]
    sig_amb = []
    s1_bypass = {}
    for ln, pairs in entries:
        for rs, bs in pairs:
            raw_s = ''.join(sum((subsplit(r) for r in rs), []))
            if not raw_s:
                continue
            box_sub = sum((subsplit(b) for b in bs), [])
            box_s = ''.join(box_sub)
            B = P_raw.count(raw_s)
            K = P_box.count(box_s)
            # ハイフンは配信面で可視の境界なので、署名はハイフン区分ごとに独立に数えて積を取る
            # (v4は連結して数え dek-du/a を1語だけ過大計上していた=独立検証の指摘)
            S = 1
            for part in ''.join(bs).split('-'):
                if part:
                    S = min(CAP, S * SP.count(part))
            t = tier_of(ln, ''.join(rs).replace('-', '').lower())
            st = stat[t]
            st[0] += 1
            st[1] += (B == 1)
            st[2] += (K == 1)
            st[3] += (K > B)
            st[4] += (K < B)
            st[5] += (S == 1)
            st[6] += (S > 1)
            st[7] += (K == 0)
            if S > 1:
                sig_amb.append((t, ln, '/'.join(rs), '/'.join(bs), S, raw_s))
            elif S == 1:
                # ★S=1迂回層(独立検証の指摘): 署名一意でも意図トークン自体が多義
                # (tok2rawsに複数のraw)なら別の実在語に復号しうる(二/a→dua/dia 型)。
                # 根本原因は第16レンズの既知「文脈共有トークン」= 検出して別掲する
                toks = sum((subsplit(b) for b in bs), [])
                if any(len(tok2raws.get(b2, {})) > 1 for b2 in toks):
                    outs = ['']
                    for b2 in toks:
                        raws = list(tok2raws.get(b2, {b2: 1}))[:4]
                        outs = [o + r for o in outs for r in raws][:16]
                    intended_l = raw_s.lower()
                    for o in set(x.lower() for x in outs) - {intended_l}:
                        v = next((vv for vv in infl_variants(o) if vv in attested), None)
                        if v is not None:
                            key = (intended_l, o)
                            if key not in s1_bypass:
                                s1_bypass[key] = (t, ln, '/'.join(rs), '/'.join(bs), o)

    print("   層          語数    素エス一意(B=1)  漢字化一意(K=1)  悪化(K>B) 改善(K<B)  ★CJK署名一意(S=1)   署名曖昧(S>1)  K=0")
    for t in TIERS + ['全体']:
        row = [sum(stat[x][i] for x in TIERS) for i in range(8)] if t == '全体' else stat[t]
        n = row[0]
        if n == 0:
            continue
        print("   %-9s %6d  %6d (%5.1f%%)  %6d (%5.1f%%)  %5d  %6d (%4.1f%%)  %7d (%6.2f%%)  %5d (%5.3f%%) %4d" %
              (t, n, row[1], 100.0 * row[1] / n, row[2], 100.0 * row[2] / n, row[3],
               row[4], 100.0 * row[4] / n, row[5], 100.0 * row[5] / n, row[6], 100.0 * row[6] / n, row[7]))

    # ---------- 復号重大度 ----------
    def decode_sets(parse):
        outs = ['']
        for kind, t in parse:
            if kind == 'G':
                outs = [o + t for o in outs]
            else:
                raws = list(tok2raws.get(t, {t: 1}))[:4]
                outs = [o + r for o in outs for r in raws][:16]
        return set(o.lower() for o in outs)

    sev = collections.Counter()
    s2_syn, s2_adj = [], []
    seen_pairs = set()
    for t, ln, rw, bw, S, raw_s in sig_amb:
        box_s = ''.join(sum((subsplit(b) for b in bw.split('/')), []))
        parses = SP.parses(box_s, limit=8)
        intended = raw_s.lower()
        alt_decs = set()
        for p in parses:
            alt_decs |= decode_sets(p)
        others = alt_decs - {intended}
        if not others:
            cls = 'S0'
        else:
            # 屈折形正規化つきで実在語照合(v4は屈折形を見逃しS2を過小計上=独立検証の指摘)
            hit = [o for o in others if any(v in attested for v in infl_variants(o))]
            if not hit:
                cls = 'S1'
            else:
                syn = [o for o in hit if syn_pair(intended, o, gloss)]
                if len(syn) == len(hit):
                    cls = 'S2syn'
                    if (intended, tuple(hit)) not in seen_pairs:
                        seen_pairs.add((intended, tuple(hit)))
                        s2_syn.append((t, ln, rw, bw, hit[:3]))
                else:
                    cls = 'S2adj'
                    if (intended, tuple(hit)) not in seen_pairs:
                        seen_pairs.add((intended, tuple(hit)))
                        s2_adj.append((t, ln, rw, bw, [o for o in hit if o not in syn][:3]))
        sev[(t, cls)] += 1
    print("\n   ★署名曖昧 %d 件(延べ)の復号重大度:" % len(sig_amb))
    print("     S0=全解析が同一語に復号(無害) / S1=代替は非語(語彙が自己修正) /")
    print("     S2syn=代替は同義語(語釈相互参照・重複で機械判定=どちらに読んでも同概念) / S2adj=それ以外(要精査)")
    for t in TIERS:
        n_t = sum(sev[(t, c)] for c in ['S0', 'S1', 'S2syn', 'S2adj'])
        if n_t:
            print("      %-9s S0=%-3d S1=%-5d S2syn=%-4d ★S2adj=%d" %
                  (t, sev[(t, 'S0')], sev[(t, 'S1')], sev[(t, 'S2syn')], sev[(t, 'S2adj')]))
    print("   ★S2adj %d 対(語型で重複除去) — 上位30対を表示・全対は _lens26_s2_full.tsv:" % len(s2_adj))
    for t, ln, rw, bw, hits in s2_adj[:30]:
        print("      [%s L%d] %s ⟦%s⟧ → %s" % (t, ln, rw, bw, ', '.join(hits)))
    if not s2_adj:
        print("      (0件)")
    print("   (参考)S2syn %d 対 — 例10対:" % len(s2_syn))
    for t, ln, rw, bw, hits in s2_syn[:10]:
        print("      [%s L%d] %s ⟦%s⟧ ≒ %s" % (t, ln, rw, bw, ', '.join(hits)))

    # ---------- S=1迂回層の報告 ----------
    print("\n   ★S=1迂回層(署名一意でも意図トークンの多義=文脈共有トークンで別実在語に復号): %d 語型対" %
          len(s1_bypass))
    print("     これは第16レンズの既知『意図的な文脈共有』(甲=kiras/met・基=baz/il・二=du/di等・是正ゼロ裁定)が")
    print("     語面に現れたもの。重大度ファネル(S>1のみ検査)の管轄外なので件数を別掲する(新たな欠陥ではない):")
    for key, (t, ln, rw, bw, o) in sorted(s1_bypass.items(), key=lambda x: x[1][1])[:12]:
        print("      [%s L%d] %s ⟦%s⟧ ⇄ %s" % (t, ln, rw, bw, o))
    grand[ver] = {'SP': SP, 'stat': stat, 'sig_amb': sig_amb, 's2adj': s2_adj, 's2syn': s2_syn,
                  'tok2raws': tok2raws, 'attested': attested, 'gloss': gloss,
                  's1bypass': s1_bypass, 'entries': entries}

# ================================================================
# 実配信テキスト
# ================================================================
print("\n" + "=" * 100)
print("■ 実配信テキスト(漢字化日記・随想集成): 読者が実際に見る語でのCJK署名一意性")
print("=" * 100)
SP = grand['学習者版']['SP']
tok2raws = grand['学習者版']['tok2raws']
attested = grand['学習者版']['attested']
WORD_SPLIT = re.compile(r'[\s,.;:!?"“”()\[\]«»…—×#*|〔〕【】『』「」（）。、・；：]+')
KANA = re.compile(r'[ぁ-んァ-ヶ]')
n_tok = amb_tok = oov = 0
n_meta = 0
amb_examples = collections.Counter()
oov_examples = collections.Counter()
for cp in CORPUS:
    if not os.path.exists(cp):
        continue
    for line in io.open(cp, encoding='utf-8', errors='replace'):
        # メタデータ行(和文の見出し・凡例)を除外(v4はOOV154件の79%が夾雑物=独立検証の指摘)
        if KANA.search(line) or line.startswith('#') or '標題' in line:
            n_meta += 1
            continue
        for w0 in WORD_SPLIT.split(line):
            w0 = w0.strip("'’`-")
            if not w0 or not any('一' <= c <= '鿿' for c in w0):
                continue
            n_tok += 1
            S = 1
            for w in subsplit(w0):
                c = SP.count(w) or SP.count(w[0].lower() + w[1:])
                if c == 0:
                    S = 0
                    break
                S = min(CAP, S * c)
            if S == 0:
                oov += 1
                oov_examples[w0] += 1
            elif S > 1:
                amb_tok += 1
                amb_examples[w0] += 1
print("   漢字を含む語トークン %d (メタデータ行 %d 行を除外) /" % (n_tok, n_meta))
print("   CJK署名一意 %d (%.2f%%) / 署名曖昧 %d (%.3f%%) / 解析不能 %d (%.2f%%)" %
      (n_tok - amb_tok - oov, 100.0 * (n_tok - amb_tok - oov) / max(1, n_tok),
       amb_tok, 100.0 * amb_tok / max(1, n_tok), oov, 100.0 * oov / max(1, n_tok)))
print("   ※このコーパスは辞書作成者自身が自分の辞書で書いた文章=生成器と検証器が同一なので")
print("     上限側バイアスを持つ(独立標本ではない)。独立検証の指摘により明記。")
print("   署名曖昧の語(全種・復号重大度付き):")
for w, c in amb_examples.most_common():
    parses = SP.parses(w, limit=8)
    alt = set()
    for p in parses:
        outs = ['']
        for kind, t in p:
            if kind == 'G':
                outs = [o + t for o in outs]
            else:
                raws = list(tok2raws.get(t, {t: 1}))[:4]
                outs = [o + r for o in outs for r in raws][:16]
        alt |= set(o.lower() for o in outs)
    hits = [o for o in alt if any(v in attested for v in infl_variants(o))]
    tag = 'S0' if len(alt) <= 1 else ('S2:' + '/'.join(hits[:2]) if len(hits) > 1 else 'S1')
    disp = ' | '.join('·'.join(t for _, t in p) for p in parses[:3])
    print("      %-14s ×%-3d %s  [%s]" % (w, c, disp, tag))
if oov_examples:
    print("   解析不能(全種の上位12。頭字語複合・辞書⇔アプリ面の描画乖離を含む):")
    for w, c in oov_examples.most_common(12):
        print("      %-20s ×%d" % (w, c))

# ================================================================
# 表面同形の全数census(スラッシュを落とした配信面で同一文字列になる別語の組)
#   [J]監査はスラッシュ込みキーなので粒度差(全a vs 全/a)を見ない。ここで全数を出し、
#   第23レンズ類型1(完全衝突166対)と突き合わせるための台帳TSVを書く。
# ================================================================
print("\n" + "=" * 100)
print("■ 表面同形census(配信面の完全同形・両版) → _lens26_surface_homographs.tsv")
print("=" * 100)
ENDSET = {'o', 'a', 'e', 'i', 'as', 'is', 'os', 'us', 'u', 'j', 'n', 'oj', 'aj', 'on', 'an', 'en',
          'ojn', 'ajn'}
with io.open("_lens26_surface_homographs.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("版\t表面\t見出し(raw)\t行\t語釈冒頭\n")
    tot_groups = {}
    for ver in grand:
        surf = collections.defaultdict(dict)
        for ln, pairs in grand[ver]['entries']:
            if len(pairs) != 1:
                continue
            rs, bs = pairs[0]
            s = ''.join(bs)
            if not any('一' <= c <= '鿿' for c in s):
                continue
            def mkey(segs):
                p = [x for x in segs if x]
                while p and p[-1] in ENDSET:
                    p = p[:-1]
                return ''.join(p)
            surf[s].setdefault(mkey(rs), ('/'.join(rs), ln))
        groups = {s: v for s, v in surf.items() if len(v) >= 2}
        tot_groups[ver] = len(groups)
        for s, v in sorted(groups.items()):
            for mk, (rw, ln) in sorted(v.items(), key=lambda x: x[1][1]):
                g = grand[ver]['gloss'].get(''.join(
                    [x for x in rw.replace('/', '').replace('-', '').lower()]), '')[:50]
                f.write("%s\t%s\t%s\tL%d\t%s\n" % (ver, s, rw, ln, g))
    print("   表面同形グループ: " + ' / '.join('%s %d群' % (v, n) for v, n in tot_groups.items()))
    print("   (第23レンズ類型1が学習者版の大半を列挙済み。真の増分=相関詞の語尾母音融合型")
    print("    全a/全o/无o と学術版census。詳細は報告書)")

# S2全対のTSV(stdoutは上位30対のみ表示のため。「全件」詐称を避ける=独立検証の指摘)
with io.open("_lens26_s2_full.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("版\t区分\t層\t行\t見出し\t描画\t別解析の復号\n")
    for ver in grand:
        for tag, lst in (('S2adj', grand[ver]['s2adj']), ('S2syn', grand[ver]['s2syn'])):
            for t, ln, rw, bw, hits in lst:
                f.write("%s\t%s\t%s\tL%d\t%s\t%s\t%s\n" % (ver, tag, t, ln, rw, bw, ','.join(hits)))
        for (intended, o), (t, ln, rw, bw, _) in sorted(grand[ver]['s1bypass'].items(),
                                                        key=lambda x: x[1][1]):
            f.write("%s\tS1迂回\t%s\tL%d\t%s\t%s\t%s\n" % (ver, t, ln, rw, bw, o))
print("\n出力: _lens26_s2_full.tsv / _lens26_surface_homographs.tsv")

# ================================================================
# 構造検査
# ================================================================
print("\n" + "=" * 100)
print("■ 構造検査: 上付きマーク(識別子)が語頭に立つトークン(0が正=付着は構造的に一意)")
print("=" * 100)
import unicodedata
for ver in grand:
    heads = set()
    for t, lst in grand[ver]['SP'].by_first.items():
        heads.add(t)
    marky = [h for h in heads if unicodedata.category(h) in ('Lm', 'Mn', 'Sk')]
    print("   %s: マーク(Lm/Mn/Sk)語頭トークン = %d 種" % (ver, len(marky)))
