# -*- coding: utf-8 -*-
# [N] 描画トークンの出典被覆監査 (2026-07-27 第16レンズで新設)
#
# 【なぜ必要か】
# 第16レンズ(逆引き round-trip)で、注入出力に現れる漢字トークンのうち
# **sidecar にも homonym台帳にも載っていない字**が9種あることが分かった(炎ᵀ・盐ᴬ・盐ᴵ・丁戊庚壬癸辛)。
# これらは _inject_final.ps1 が文脈判定(化学塩・医学-itis・アルキル語幹)で**直接埋め込んでいる定数**で、
# どの配布表にも載らないため、アプリが「漢字→語根」の逆引き辞書を作ると復元できない。
# 本監査は出力の全漢字トークンを sidecar / 台帳 / _inline_tokens.tsv の3表と突き合わせ、
# **どれにも無いトークン**を報告する。新しい inline rule が未文書のトークンを持ち込んだら気付ける。
#
# 直し方: 新規トークンを _inline_tokens.tsv に登録する(語根が一意に決まる場合)。
#         一意に決まらないなら、それは §9 の一意復号が壊れているので割当自体を見直す。
import io, os, re, sys
from collections import defaultdict
os.chdir(os.path.dirname(os.path.abspath(__file__)))
BASELINE = int(sys.argv[1]) if len(sys.argv) > 1 else 0
CJK = re.compile('[一-鿿]')
BR = re.compile(r'^([^⟦]*)⟦([^⟧]*)⟧$')

known = set()
with io.open('_identifier_sidecar.tsv', encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 5 and p[4]:
            known.add(p[4])
for line in io.open('_homonym_disp.tsv', encoding='utf-8'):
    p = line.rstrip('\n').split('\t')
    if len(p) >= 5 and p[1] != 'type':
        known.add(p[4])
inline = {}
if os.path.exists('_inline_tokens.tsv'):
    for line in io.open('_inline_tokens.tsv', encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or line.startswith('#'):
            continue
        p = line.split('\t')
        if len(p) >= 2 and p[0] != 'token':
            inline[p[0]] = p[1]
            known.add(p[0])

unknown = defaultdict(list)
for path in ('漢字注入_学習者版_20260620.txt', '漢字注入_学術版_20260620.txt'):
    if not os.path.exists(path):
        continue
    for n, line in enumerate(io.open(path, encoding='utf-8-sig'), 1):
        line = line.rstrip('\n')
        if ':' not in line or line.startswith('#'):
            continue
        m = BR.match(line.split(':', 1)[0])
        if not m:
            continue
        head, real = m.group(1), m.group(2)
        hw, rw = head.split(' '), real.split(' ')
        if len(hw) != len(rw):
            continue
        for a, b in zip(hw, rw):
            sa = a.strip('-').replace('-', '/').split('/')
            sb = b.strip('-').replace('-', '/').split('/')
            if len(sa) != len(sb):
                continue
            for s, tk in zip(sa, sb):
                if CJK.search(tk) and tk not in known:
                    if len(unknown[tk]) < 3:
                        unknown[tk].append((s, head))
out = ["[N] 描画トークンの出典: 未登録トークン=%d種 (sidecar+台帳+_inline_tokens.tsv の3表と照合)" % len(unknown)]
for tk in sorted(unknown, key=lambda z: -len(unknown[z])):
    out.append("      ★%-6s ← 分節 %-10s 例=%s" % (tk, unknown[tk][0][0], unknown[tk][0][1][:40]))
if len(unknown) > BASELINE:
    out.append("    !! 未登録の描画トークンあり → 語根が一意なら _inline_tokens.tsv に登録、"
               "一意でないなら §9 の一意復号が壊れているので割当を見直す")
txt = '\n'.join(out)
try:
    sys.stdout.write(txt + '\n')
except Exception:
    sys.stdout.write(txt.encode('ascii', 'replace').decode('ascii') + '\n')
sys.exit(1 if len(unknown) > BASELINE else 0)
