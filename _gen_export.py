# -*- coding: utf-8 -*-
# 配信用エクスポート一式の生成器(2026-07-26 第14レンズで恒久化)。
#
# 【なぜスクリプト化したか】
# 2026-07-26 に「注入版マスターとエクスポートの食い違い17件」がアプリ側から報告された。
# 原因は単純で、エクスポートTSVが18:17生成・注入が22:12生成=**エクスポートが4時間古かった**だけ。
# 手作業で生成していると必ずこれが起きるので、生成器を正典化し [L]監査(_audit_export_sync.py)で
# 同期を機械検出できるようにした。注入を再生成したら必ず本スクリプトも走らせること。
#
# 生成物:
#   ① _漢字割当エクスポート_学習者版_20260723.tsv / _学術版_ … 4列(見出し/最終描画/表層/描画flat)
#   ② _漢字割当エクスポート_同一見出し衝突_20260725.tsv … 見出しキーで衝突する語(版+行番号+語釈つき)
#   ③ _漢字割当エクスポート_素朴置換の危険リスト_20260726.tsv … アプリが「語根→漢字」の素朴置換を
#      するとき、注入と食い違う箇所。特に「注入はラテンなのに素朴置換は漢字を当ててしまう」型は
#      アプリ側が偽の友を作るので最優先。
import io, os, re, sys
from collections import defaultdict

os.chdir(os.path.dirname(os.path.abspath(__file__)))
NOTE = sys.argv[1] if len(sys.argv) > 1 else "§14+DICT同期済"
PAIRS = [("学習者版", "漢字注入_学習者版_20260620.txt", "_漢字割当エクスポート_学習者版_20260723.tsv"),
         ("学術版", "漢字注入_学術版_20260620.txt", "_漢字割当エクスポート_学術版_20260723.tsv")]
COLL = "_漢字割当エクスポート_同一見出し衝突_20260725.tsv"
RISK = "_漢字割当エクスポート_素朴置換の危険リスト_20260726.tsv"
BR = re.compile(r'⟦(.*?)⟧')
CJK = re.compile('[一-鿿]')
ENDSET = set(['ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us', 'o', 'a', 'e', 'i', 'u', 'j', 'n'])


def to_hsys(s):
    for u, x in (('ĉ', 'c^'), ('Ĉ', 'C^'), ('ĝ', 'g^'), ('Ĝ', 'G^'), ('ĥ', 'h^'), ('Ĥ', 'H^'),
                 ('ĵ', 'j^'), ('Ĵ', 'J^'), ('ŝ', 's^'), ('Ŝ', 'S^'), ('ŭ', 'u^'), ('Ŭ', 'U^')):
        s = s.replace(u, x)
    return s


disp = {}
with io.open("_identifier_sidecar.tsv", encoding='utf-8') as f:
    f.readline()
    for line in f:
        p = [x.strip().strip('"') for x in line.rstrip('\n').split('\t')]
        if len(p) >= 5:
            disp[to_hsys(p[0])] = p[4]


def naive(head):
    """アプリが実装しうる最小の描画: 分節ごとに 語根→disp を引くだけ(§7の語頭大文字ガードのみ実装)。"""
    outw = []
    for w in head.split(' '):
        if re.match(r'^[A-ZĈĜĤĴŜŬ]', w) and not re.match(r'^[A-ZĈĜĤĴŜŬ]-', w):
            outw.append(w)
            continue
        outw.append('/'.join((s if (s == '' or s in ENDSET) else disp.get(to_hsys(s), s)) for s in w.split('/')))
    return ' '.join(outw)


allrows, coll_rows, risk_rows = {}, [], []
for ed, src, dst in PAIRS:
    rows, seen = [], []
    with io.open(src, encoding='utf-8-sig') as f:
        for n, line in enumerate(f, 1):
            line = line.rstrip('\n')
            if not line or ':' not in line:
                continue
            head_part, gloss = line.split(':', 1)
            head_part = head_part.strip()
            if not head_part or head_part.startswith('#'):
                continue
            m = BR.search(head_part)
            head = head_part[:m.start()] if m else head_part
            d = m.group(1) if m else head_part
            rows.append('\t'.join((head, d, head.replace('/', ''), d.replace('/', ''))))
            seen.append((n, head, d, gloss.strip()))
    out = ["# エスペラント漢字割当 最終描画エクスポート(inline rule適用済・authoritative)",
           "# 生成元: %s / %s / 読み取り専用" % (src, NOTE),
           "# 列: 見出し(スラッシュ付)\t最終描画(スラッシュ付)\t表層(スラッシュ除去)\t描画flat(スラッシュ除去)"]
    out += rows
    with open(dst, 'wb') as w:
        w.write(('\r\n'.join(out) + '\r\n').encode('utf-8'))
    print("%-6s -> %s rows=%d" % (ed, dst, len(rows)))
    allrows[ed] = seen

    # ② 同一見出しで描画が違う語
    byhead = defaultdict(list)
    for n, head, d, g in seen:
        byhead[head].append((n, d, g))
    for head in sorted(byhead):
        v = byhead[head]
        if len(set(d for _, d, _ in v)) > 1:
            for n, d, g in v:
                coll_rows.append('\t'.join((ed, str(n), head, d, g[:60])))

    # ③ 素朴置換の危険リスト
    for n, head, d, g in seen:
        sim = naive(head)
        if sim == d:
            continue
        if not CJK.search(d) and not CJK.search(sim):
            continue
        if not CJK.search(d) and CJK.search(sim):
            kind = "★偽の友(注入はラテンだが素朴置換は漢字を当てる)"
        elif CJK.search(d) and not CJK.search(sim):
            kind = "取りこぼし(注入は漢字だが素朴置換は引けない)"
        else:
            kind = "別の字になる"
        risk_rows.append('\t'.join((ed, str(n), kind, head, d, sim, g[:60])))

hdr = ["# エスペラント漢字割当 同一見出し・複数描画(語釈ゲートで解決)一覧  再生成: %s" % NOTE,
       "# 用途: エクスポートを『見出しキーの辞書』にすると、ここに載る見出しは衝突します。",
       "#       app側は「版＋原本行番号」または「語釈」で sense を弁別してください。",
       "# 列: 版\t原本行番号\t見出し(スラッシュ付)\t最終描画\t語釈(先頭60字)"]
with open(COLL, 'wb') as w:
    w.write(('\r\n'.join(hdr + coll_rows) + '\r\n').encode('utf-8'))
print("衝突一覧 -> %s rows=%d" % (COLL, len(coll_rows)))

hdr2 = ["# アプリが『語根→漢字』の素朴置換をした場合に、注入(authoritative)と食い違う箇所  再生成: %s" % NOTE,
        "# ★結論: エクスポートTSVの2列目(最終描画)をそのまま使えば0件になります。",
        "#   注入層は homonym台帳・化学塩判定・医学-itis・天干・privative・語釈scoped規則など",
        "#   多数の文脈依存処理を持つため、語根置換では原理的に再現できません。",
        "# 種別: ★偽の友(注入はラテンだが素朴置換は漢字を当てる) / 別の字になる / 取りこぼし",
        "# 列: 版\t原本行番号\t種別\t見出し\t注入(正)\t素朴置換(誤)\t語釈(先頭60字)"]
with open(RISK, 'wb') as w:
    w.write(('\r\n'.join(hdr2 + risk_rows) + '\r\n').encode('utf-8'))
kinds = defaultdict(int)
for r in risk_rows:
    kinds[r.split('\t')[2]] += 1
print("危険リスト -> %s rows=%d  %s" % (RISK, len(risk_rows), dict(kinds)))
