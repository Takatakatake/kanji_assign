# -*- coding: utf-8 -*-
# [L] 配信エクスポートの同期監査 (2026-07-26 第14レンズで新設)
#
# 【なぜ必要か】
# 2026-07-26、アプリ側から「注入版マスターとエクスポートの食い違い17件」の報告があった。
# 原因は単純で、エクスポートTSVが18:17生成・注入が22:12生成=**エクスポートが4時間古かった**だけ。
# 正本(DICT)のドリフトは [D] が検出するのに、**配信面のドリフトには検出器が無かった**。
# 注入を再生成したらエクスポートも必ず再生成する、というのは人間の記憶に頼る運用で、実際に破れた。
#
# 本監査は 注入(authoritative) と エクスポートTSV を突き合わせ、1行でも食い違えば fail する。
# 直し方: python _gen_export.py "コメント"  を実行するだけ。
import io, os, re, sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))
PAIRS = [("学習者版", "漢字注入_学習者版_20260620.txt", "_漢字割当エクスポート_学習者版_20260723.tsv"),
         ("学術版", "漢字注入_学術版_20260620.txt", "_漢字割当エクスポート_学術版_20260723.tsv")]
BR = re.compile(r'⟦(.*?)⟧')
bad = 0
out = []
for ed, src, dst in PAIRS:
    cur = []
    with io.open(src, encoding='utf-8-sig') as f:
        for line in f:
            line = line.rstrip('\n')
            if not line or ':' not in line:
                continue
            hp = line.split(':', 1)[0].strip()
            if not hp or hp.startswith('#'):
                continue
            m = BR.search(hp)
            head = hp[:m.start()] if m else hp
            d = m.group(1) if m else hp
            cur.append((head, d))
    if not os.path.exists(dst):
        out.append("[L] %s: エクスポートが存在しない → python _gen_export.py で生成" % ed)
        bad += 1
        continue
    old = []
    for line in io.open(dst, encoding='utf-8'):
        line = line.rstrip('\r\n')
        if not line or line.startswith('#'):
            continue
        p = line.split('\t')
        if len(p) >= 2:
            old.append((p[0], p[1]))
    if len(cur) != len(old):
        out.append("[L] %s: 行数不一致 注入=%d != エクスポート=%d → 再生成が必要" % (ed, len(cur), len(old)))
        bad += 1
        continue
    diff = [(i, a, b) for i, (a, b) in enumerate(zip(cur, old), 1) if a != b]
    if diff:
        out.append("[L] %s: ★描画が食い違う行=%d → python _gen_export.py で再生成" % (ed, len(diff)))
        for i, a, b in diff[:8]:
            out.append("      #%-6d 注入=%s⟦%s⟧  エクスポート=%s⟦%s⟧" % (i, a[0], a[1], b[0], b[1]))
        if len(diff) > 8:
            out.append("      ... 他 %d行" % (len(diff) - 8))
        bad += 1
    else:
        out.append("[L] %s: エクスポート同期OK (%d行一致)" % (ed, len(cur)))
txt = '\n'.join(out)
try:
    sys.stdout.write(txt + '\n')
except Exception:
    sys.stdout.write(txt.encode('ascii', 'replace').decode('ascii') + '\n')
sys.exit(1 if bad else 0)
