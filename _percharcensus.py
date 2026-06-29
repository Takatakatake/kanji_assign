# -*- coding: utf-8 -*-
# 真の「1文字単位」センサス: ⟦⟧割当内の個別CJK字ごとに、それを使う distinct 語根を集計。
# 既存 _census_rare_kanji.ps1 はセグメントの漢字文字列(庄严)をキーにするため、熟語内の単字(庄)を取りこぼす。
# ここでは各セグメントの各CJK字を個別に数え、熟語内に埋もれた稀少字を炙り出す。
import re, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

DIR = r"d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621"
INJ = DIR + r"\漢字注入_学習者版_20260620.txt"

L1, R1 = '⟦', '⟧'
endings = set('o a e i u j n'.split()) | set(['oj','aj','ej','on','an','en','ojn','ajn','as','is','os','us','int','ant','ont','it','at','ot','um','ig','igx','ad','ek','er','estr'])
cap = re.compile(r'^[A-ZĈĜĤĴŜŬ]')

def cjk(s):
    return [ch for ch in s if '一' <= ch <= '鿿']

char_roots = {}         # single char -> set(roots)
char_in_compound = {}   # char -> set of compound-tokens it appears in (len>=2)
char_solo = {}          # char -> set of roots where it's the WHOLE single-char token

with open(INJ, encoding='utf-8') as f:
    for line in f:
        ci = line.find(L1)
        if ci < 0: continue
        cj = line.find(R1, ci)
        if cj < 0: continue
        head = line[:ci]; kanji = line[ci+1:cj]
        if cap.match(head): continue
        hs = re.split(r'[/-]', head); ks = re.split(r'[/-]', kanji)
        if len(hs) != len(ks): continue
        for h, k in zip(hs, ks):
            if not h or ' ' in h: continue
            if h in endings: continue
            chars = cjk(k)
            if not chars: continue
            kanji_only = ''.join(chars)
            for ch in chars:
                char_roots.setdefault(ch, set()).add(h)
                if len(kanji_only) >= 2:
                    char_in_compound.setdefault(ch, set()).add(kanji_only)
                else:
                    char_solo.setdefault(ch, set()).add(h)

# rare chars: used by 1-2 distinct roots
rare = [(ch, sorted(rs)) for ch, rs in char_roots.items() if len(rs) <= 2]
rare.sort(key=lambda x: (len(x[1]), x[0]))

# 特に注目: 熟語内にしか出ない(soloが無い)稀少字 = これまでの盲点
buried = [(ch, rs) for ch, rs in rare if ch not in char_solo]

print("総 distinct 個別CJK字 =", len(char_roots))
print("count<=2 の個別字 =", len(rare))
print("うち『熟語内のみ(単字割当が無い)』= 盲点字 =", len(buried))
print()
print("=== ★盲点字(熟語内のみ・count<=2)= 今回の新規調査対象 全件 ===")
for ch, rs in buried:
    comps = sorted(char_in_compound.get(ch, []))
    print(f"  {ch}  (語根{len(rs)}: {','.join(rs)})  熟語: {' '.join(comps)}")
