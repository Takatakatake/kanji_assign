# -*- coding: utf-8 -*-
# 版間ラテン維持センチネル監査 (2026-07-30 第27回続53)
#
#   kuriterapi 事件の一般化。確定裁定「kuri(Curie由来)はラテン統一」は
#   **学習者版の分節 kuri には語釈gatedで届くが、学術版の融合語根 kuriterapi には届かない**。
#   同じ穴が他にもあるかを全数で洗う。
#
#   検出条件: 同一見出し語について
#     ・学習者版が **ラテンのまま残している内容分節** を持ち
#     ・学術版が その材料を覆う位置に漢字を当てている
#   ＝学術版のほうが「漢字が多い」状態。これは
#     (a) 確定裁定でラテン維持と決めた語根に学術版だけ漢字が付いている  ← 是正対象
#     (b) 融合語根に独自の全体割当がある(固有名でない普通の合成語)      ← 正当
#   のどちらか。全件を層と語釈つきで出して目視する。
#
# 出力: _audit_latin_sentinel_crossversion.tsv
import io, os, re, sys, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
G = "漢字注入_学習者版_20260620.txt"
A = "漢字注入_学術版_20260620.txt"
SEP = re.compile(r'[/ ]')
ENDSET = {'ojn','ajn','oj','aj','on','an','en','as','is','os','us','o','a','e','i','u','j','n'}


def is_cjk(c):
    return '一' <= c <= '鿿'


def parse(path):
    out = {}
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head, gloss = line.split(':', 1)
        if '⟦' in head:
            raw = head[:head.index('⟦')]
            disp = head[head.index('⟦') + 1:head.rindex('⟧')]
        else:
            raw, disp = head, head
        bare = raw.replace('/', '').replace(' ', '')
        segs, disps = SEP.split(raw), SEP.split(disp)
        if len(segs) != len(disps):
            disps = segs
        out.setdefault(bare, (raw, disp, segs, disps, gloss))
    return out


g, a = parse(G), parse(A)
rows = []
for bare, (graw, gdisp, gsegs, gdisps, ggl) in g.items():
    if bare not in a:
        continue
    araw, adisp, asegs, adisps, agl = a[bare]
    # 学習者版でラテンのまま残っている内容分節
    latin_segs = [s for s, d in zip(gsegs, gdisps)
                  if s and s not in ENDSET and not any(is_cjk(c) for c in d)]
    if not latin_segs:
        continue
    # 学術版の側で、そのラテン材料を含む分節に漢字が当たっているか
    hit = []
    for s, d in zip(asegs, adisps):
        if not any(is_cjk(c) for c in d):
            continue
        for ls in latin_segs:
            # 学術版の分節が学習者版のラテン分節を丸ごと含む(=融合されている)か等しい
            if ls in s and len(ls) >= 3:
                hit.append((ls, s, d))
    if hit:
        for ls, s, d in hit:
            rows.append((bare, ls, graw + '⟦' + gdisp + '⟧', araw + '⟦' + adisp + '⟧',
                         d, ggl[:70].replace('\t', ' ')))

print("=" * 100)
print("版間ラテン維持センチネル監査 — 学習者版がラテンのまま残す材料に学術版が漢字を当てている箇所")
print("=" * 100)
print("  照合できた見出し = %s / 該当 = %s 件" % (format(len(set(g) & set(a)), ','), format(len(rows), ',')))
by = collections.Counter(r[1] for r in rows)
print("\n■ ラテン維持されている語根ごとの件数(多い順)")
for s, c in by.most_common(40):
    print("     %-16s %d 件" % (s, c))
print("\n■ 全件")
for r in sorted(rows, key=lambda x: (x[1], x[0])):
    print("   [%s] %-22s 学習者=%-34s 学術=%-30s" % (r[1], r[0], r[2][:34], r[3][:30]))
    print("        %s" % r[5])
with io.open("_audit_latin_sentinel_crossversion.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("見出し\tラテン維持語根\t学習者版\t学術版\t学術版の当該字\t語釈\n")
    for r in sorted(rows, key=lambda x: (x[1], x[0])):
        f.write('\t'.join(r) + '\n')
print("\n出力: _audit_latin_sentinel_crossversion.tsv")
