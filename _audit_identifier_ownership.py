# -*- coding: utf-8 -*-
# ============================================================================
# §9 逆復号契約の「所有者」監査 (2026-07-25 第27回続20 新設)
# ----------------------------------------------------------------------------
# 動機:
#   _inject_final.ps1 の inline rule は sidecar を迂回して $tok を直接書き込むため、
#   _verify_all.ps1 [A] の「id重複=0」検査では原理的に捕捉できない層が存在する。
#   すなわち「分節Xが、sidecar上では別語根Yが所有する表示Dで描かれている」状態。
#   読者が §9 の逆復号(字+識別子→語根綴り)を行うと Y に着地し、X に戻れない。
#
# 判定:
#   注入出力の (分節, 表示) を全走査し、
#     - 表示が分節自身の master なら正
#     - 表示が sidecar に登録が無い合成表示(鏡像/sep生成)なら対象外
#     - 表示の所有者集合に分節が含まれないなら「所有者不一致」として報告
#   綴りは h-system に正規化して照合する(ĉĝĥĵŝŭ ⇄ c^g^h^j^s^u^ の取り違えは
#   本プロジェクトで3度 偽陽性を出している既知の罠)。
#
# 基準値(2026-07-25): 学習者版=30種 / 学術版=10種 / 和集合=31種。
#   全件が「意味的には正しいが逆復号が別語根に着地する」型であり、意味の誤りは無い。
#   内訳: (a)天干化学系=ユーザー裁定済みの設計 (b)同一語族の綴り違い=実害なし
#         (c)結合形が別語根の字を借用=識別子付与で解消可能な残件
#   ★新規 が出たら、その inline rule が意味的に正しいかを語義照合で判定すること。
# ============================================================================
import io, os, sys
from collections import defaultdict

BASE = os.path.dirname(os.path.abspath(__file__))
os.chdir(BASE)
L1, R1 = '⟦', '⟧'
ENDINGS = set(['o','a','e','i','u','j','n','oj','aj','ej','on','an','en','ojn','ajn',
               'as','is','os','us','int','ant','ont','it','at','ot'])

# 既知の所有者不一致(分節, 表示)。理由は上記(a)(b)(c)。
KNOWN = set([
    # (a) 系統化学 天干/基 = 2026-07-17 ユーザー裁定。中国化学命名に合わせた設計。
    ('et','乙'), ('met','甲'), ('prop','丙'), ('heks','己'), ('di','二'), ('il','基'),
    # (b) 同一語族の綴り違い/大文字違い = 逆復号先が実質同語根
    ('arh^eo','古ᴬᴴ̂'), ('kastan','栗'), ('citr','柑'), ('tuj','侧柏'),
    ('pask','庆ᴾ'), ('meso','中'),
    # (c) 結合形が別語根の master を借用(意味は正・逆復号のみ別着地)
    # ('nau^t','航') は 2026-07-26 続29 で解消。nau^t を正式語根(k=航・band=pejvo・P=5)として
    #   登録し、インライン規則の $tok='航' 直書きを撤去した → 自前の識別子 航ᴺᴬ を取得。
    #   無印の航は所有者 aviad(CSV2890・F=30)に戻り、§9 の逆復号が正しく着地する。
    ('uri','尿'), ('fag','吞'), ('dur','币'), ('end','内'),
    ('om','瘤'), ('himen','膜'), ('hipo','马'), ('rink','嘴'), ('cer','角'),
    ('kat','股'), ('lip','脂'), ('mes','中'), ('ne','新'), ('ort','直'),
    ('po','草'), ('sial','唾'), ('torn','旋'), ('lizin','解'),
])

def tohsys(s):
    for a, b in [('ĉ','c^'),('ĝ','g^'),('ĥ','h^'),('ĵ','j^'),('ŝ','s^'),('ŭ','u^'),
                 ('Ĉ','C^'),('Ĝ','G^'),('Ĥ','H^'),('Ĵ','J^'),('Ŝ','S^'),('Ŭ','U^')]:
        s = s.replace(a, b)
    return s

def has_cjk(s):
    return any('一' <= c <= '鿿' for c in s)

root2disp, disp2root = {}, defaultdict(set)
with io.open('_identifier_sidecar.tsv', encoding='utf-8') as f:
    next(f)
    for line in f:
        p = [x.strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) < 5:
            continue
        r = tohsys(p[0])
        root2disp[r] = p[4]
        disp2root[p[4]].add(r)

total_new = 0
for ed, inj in [('学習者版', '漢字注入_学習者版_20260620.txt'),
                ('学術版',   '漢字注入_学術版_20260620.txt')]:
    found, new = [], []
    seen = set()
    with io.open(inj, encoding='utf-8') as f:
        for n, line in enumerate(f, 1):
            line = line.rstrip('\n')
            ci = line.find(':')
            if ci < 0:
                continue
            left = line[:ci]
            if not left or left.startswith('#') or L1 not in left:
                continue
            b = left.find(L1); e = left.find(R1, b)
            if e < 0:
                continue
            head, kanji = left[:b], left[b+1:e]
            hs, ks = head.split('/'), kanji.split('/')
            if len(hs) != len(ks):
                continue
            for i, (h, k) in enumerate(zip(hs, ks)):
                if not h or (h.lower() in ENDINGS and i > 0):
                    continue
                if not has_cjk(k):
                    continue
                s = h.lower().strip('-')
                if root2disp.get(s) == k:
                    continue
                if root2disp.get(s + 'o') == k or root2disp.get(s + 'a') == k:
                    continue
                owners = disp2root.get(k)
                if not owners or s in owners:
                    continue
                key = (s, k)
                if key in seen:
                    continue
                seen.add(key)
                rec = (n, head, kanji, s, k, sorted(owners)[:3])
                found.append(rec)
                if key not in KNOWN:
                    new.append(rec)
    print("[%s] 所有者不一致=%d種 / ★新規=%d種" % (ed, len(found), len(new)))
    for n, head, kanji, s, k, ow in new:
        print("   ★ L%-6d %-28s %-24s 分節=%-10s 表示=%-8s 所有者=%s"
              % (n, head, kanji, s, k, ','.join(ow)))
    total_new += len(new)

# ---------------------------------------------------------------------------
# [2] sep 表示の一意性 (2026-07-25 第27回続21 追加 / 続22 で根因を是正済み)
#   かつて _homonym_disp.ps1 の AddSegId は、同一群に *同じ実行内で* 追加される他の sep 分節を
#   $used にも per-head 位置ベース判定にも積んでいなかった(sidecar の既存メンバーしか見ない)。
#   その結果、語根とその -i- 拡張形が同じ識別子を得て、別語が同一の漢字列になっていた。
#   4群が重複: 四ᵀ(tetr/tetra)・专ᴷ(krat/krati)・病ᴾ(pati/pat)・律ᴺ(nomi/nom)。
#   2026-07-25 続22 に runUsed/runSegs/runMemo を導入して是正 → 重複0群。
#   基準値は **0**。1群でも出たら AddSegId の払い出し記録が壊れている。
KNOWN_SEPDUP = set()
segs = {}
dup = {}
with io.open('_homonym_disp.tsv', encoding='utf-8') as f:
    next(f)
    for line in f:
        p = line.rstrip('\n').split('\t')
        if len(p) < 5 or not p[4]:
            continue
        dup.setdefault(p[4], set()).add(p[0])
sepdup = {d: s for d, s in dup.items() if len(s) >= 2}
newdup = [d for d in sepdup if d not in KNOWN_SEPDUP]
print("[sep表示の一意性] 重複表示=%d群 / ★新規=%d群" % (len(sepdup), len(newdup)))
for d in newdup:
    print("   ★ %s <- %s" % (d, ', '.join(sorted(sepdup[d]))))
total_new += len(newdup)

print("★新規合計=%d (0が正)" % total_new)
sys.exit(1 if total_new else 0)
