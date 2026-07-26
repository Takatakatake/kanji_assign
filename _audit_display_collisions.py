# -*- coding: utf-8 -*-
# [J] 描画の一意性 監査 (2026-07-26 第9レンズで新設)
#
# §9契約が保証するのは【字+識別子 → 語根】=分節1個の一意復号。しかし読者が読むのは『語』
# なので、**異なる語が完全に同じ漢字列に描画されていないか**を語単位で検査する必要がある。
# これは [A] の id重複=0 でも [E] でも [F] でも捕捉できない層。
#
# 判定:
#   両版それぞれで、⟦⟧内の描画文字列が完全一致する見出し語の組を集める。
#   ★同一形態素の二重見出し(辞書が接辞定義行 `-ism-` と語根行 `ism/o` を別に持つ等)は
#     見出しからハイフン/スラッシュ/末尾語尾を落とすと一致するので自動除外(衝突ではない)。
#   残りが「真の同形異義」= 既知(KNOWN)にない新規が出たら fail。
#
# 既知の内訳(2026-07-26 実測。いずれも意味的に隣接し誤読を招かないと判断):
#   (a) 同義語の綴り変種   … 同じ物を指す別綴りが同じ描画になるのは正しい
#   (b) 意図的な同源統一   … meso-(希mesos) と mez(中央) は同源ゆえ 中 に統一(方針の設計)
#   (c) 語義scoped の借用  … 同綴別語の第2義が別語根のmasterを借用(ledgerのamb категория)
import io, os, re, sys
from collections import defaultdict
os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = [('学習者版', '漢字注入_学習者版_20260620.txt'), ('学術版', '漢字注入_学術版_20260620.txt')]
ENDSET = set(['ojn','ajn','oj','aj','on','an','en','as','is','os','us','o','a','e','i','u','j','n'])
CJK = lambda c: '一' <= c <= '鿿'

# 既知の真の同形異義(描画文字列)。値は理由。
KNOWN = {
    '中/o':       '(b) mez/o まん中 ↔ meso/o 腹膜ひだ。meso-(希mesos)は mez と同源ゆえ 中 に統一する設計(_inject_final.ps1 L140)',
    '中/肠ᴱ/o':   '(a) mes/enter/o ・ meso/enter/o ・ mez/enter/o = すべて腸間膜(mesentero)の綴り変種',
    '内/渗/o':    '(a) end/osmoz/o ・ en/osmoz/o = ともに内方浸透(endosmosis)',
    '马/栗/o':    '(a) c^eval/kas^tan/o ・ hipo/kas^tan/o ・ hipo/kastan/o = すべてマロニエ',
    '币/o':       '(c) valut/o 通貨 ↔ dur/o ドゥーロ銀貨(【史】)。ともに貨幣領域で隣接',
    '草/o':       '(c) herb/o 草 ↔ po/o イチゴツナギ属(Poa=イネ科)。Poaは草そのものなので隣接',
    '侧柏/o':     '(c) tuj/o クロベ属 ↔ tujan/o ツヤン C10H18。テルペンは Thuja 由来で隣接(学術版のみ)',
}

def morphkey(head):
    h = head.strip().strip('-')
    parts = [x for x in h.split('/') if x]
    while parts and parts[-1] in ENDSET: parts = parts[:-1]
    return ''.join(parts)

total_new = 0
lines_out = []
for ed, path in INJ:
    d = defaultdict(list)
    n_target = 0
    for n, line in enumerate(io.open(path, encoding='utf-8'), 1):
        line = line.rstrip('\n')
        m = re.match(r'^([^⟦]*)⟦([^⟧]*)⟧:(.*)$', line)
        if not m: continue
        head, disp, gloss = m.group(1), m.group(2), m.group(3)
        if not any(CJK(c) for c in disp): continue     # 全ラテン語は対象外
        n_target += 1
        d[disp].append((head, n, gloss[:60]))
    real, dbl = [], 0
    for k, v in d.items():
        seen = {}
        for x in v:
            if x[0] not in seen: seen[x[0]] = x
        if len(seen) < 2: continue
        if len(set(morphkey(h) for h in seen)) == 1:
            dbl += 1                                    # 同一形態素の二重見出し=衝突でない
        else:
            real.append((k, sorted(seen.values(), key=lambda z: z[1])))
    new = [x for x in real if x[0] not in KNOWN]
    total_new += len(new)
    lines_out.append("[J] %s: 対象語=%d / 完全一致の衝突=%d種 (同一形態素の二重見出し%d種を除く真の同形異義=%d種 / うち★新規=%d種)"
                     % (ed, n_target, len(real) + dbl, dbl, len(real), len(new)))
    for k, v in sorted(new):
        lines_out.append("    ★新規の同形異義: 描画「%s」" % k)
        for head, n, gl in v:
            lines_out.append("        L%-6d %-30s %s" % (n, head, gl))

out = '\n'.join(lines_out)
out += "\n[J] ★新規合計=%d (0が正)" % total_new
try:
    sys.stdout.write(out + "\n")
except Exception:
    sys.stdout.write(out.encode('ascii', 'replace').decode('ascii') + "\n")
sys.exit(1 if total_new else 0)
