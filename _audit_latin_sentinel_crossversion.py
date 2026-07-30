# -*- coding: utf-8 -*-
# [O] 版間ラテン維持センチネル監査 (2026-07-30 第27回続53で新設 / 続54で恒久化)
#
# 【なぜ要るか】
# 確定裁定「kuri(Curie由来)はラテン統一」は _inject_final.ps1 の語釈gated inline rule で
# 実装されている。これは **学習者版の分節 kuri には届くが、学術版の融合語根 kuriterapi には
# 原理的に届かない**。結果 学習者版 kuri/terapi/o⟦kuri/疗/o⟧(正) に対し
# 学術版 kuriterapi/o⟦廷疗/o⟧(誤=廷はCuria専用) が6日間残っていた。
#
# 同じ事故類型は2度起きている:
#   続49 orkid/panikl 4件 … §14.2.1 の確定裁定が学術版whole-root master に未反映
#   続53 kuriterapi 1件  … 語釈gated規則が融合語根に届かない
# どちらも [A][F][J][K] では捕捉できない。[A]は原本との一致、[F]は偽分解の整合、
# [J]は描画の衝突、[K]は新規露出しか見ないため、**版間で片方だけ漢字が付いている状態**は
# どの検査の視野にも入らなかった。ここで機械化する。
#
# 【何を検出するか】
# 同一見出し語について、学術版の1分節が学習者版の複数分節を融合しているとき、
#   ・その学術版分節に漢字が当たっており
#   ・融合されている学習者版分節のうち少なくとも1つが **ラテンのまま**
# である箇所を全数抽出する。これは
#   (a) 確定裁定でラテン維持と決めた語根に学術版だけ漢字が付いている  ← 是正対象
#   (b) 融合語根に独自の全体割当がある(正当。§4.6が版間の粒度差を明示的に許容)
# のどちらか。(b) を受理台帳に登録し、**台帳に無いものだけを ★新規 として報告する**。
#
# 【照合は厳密なアライメント】初版は部分文字列一致(ls in s)で判定していたが、
#   短い分節が無関係な語に誤ヒットしうる(pro が improvizi に当たる等)。
#   両版の分節列は同じ裸形に連結されるので、学術版の各分節が学習者版の
#   **連続する分節列** をちょうど覆うように突き合わせる。
#
# 使い方:
#   python _audit_latin_sentinel_crossversion.py          … 検査(★新規があれば !! を出す)
#   python _audit_latin_sentinel_crossversion.py --accept  … 受理台帳を更新(内容を点検してから)
import io, os, re, sys, collections

try:
    sys.stdout.reconfigure(encoding='utf-8')
except Exception:
    pass
os.chdir(os.path.dirname(os.path.abspath(__file__)))
G = "漢字注入_学習者版_20260620.txt"
A = "漢字注入_学術版_20260620.txt"
BASE = "_known_latin_sentinel.txt"
SEP = re.compile(r'[/ ]')
ENDSET = {'ojn', 'ajn', 'oj', 'aj', 'on', 'an', 'en', 'as', 'is', 'os', 'us',
          'o', 'a', 'e', 'i', 'u', 'j', 'n'}


def is_cjk(c):
    return '一' <= c <= '鿿'


def has_cjk(s):
    return any(is_cjk(c) for c in s)


def strip_id(s):
    """識別子(上付き記号)を落とす。識別子は群の再編で動くので台帳キーには使わない"""
    return ''.join(c for c in s if is_cjk(c))


def parse(path):
    out = {}
    for line in io.open(path, encoding='utf-8-sig'):
        line = line.rstrip('\n')
        if not line or line.startswith('#') or ':' not in line:
            continue
        head, gloss = line.split(':', 1)
        if '⟦' in head and head.rindex('⟧') > head.index('⟦'):
            raw = head[:head.index('⟦')]
            disp = head[head.index('⟦') + 1:head.rindex('⟧')]
        else:
            raw, disp = head, head
        segs, disps = SEP.split(raw), SEP.split(disp)
        if len(segs) != len(disps):
            disps = list(segs)
        bare = raw.replace('/', '').replace(' ', '')
        if bare:
            out.setdefault(bare, (segs, disps, gloss))
    return out


def align(asegs, gsegs):
    """学術版の各分節が覆う学習者版分節の範囲を返す。合わなければ None
    ★空分節(末尾スラッシュ由来 de/oksi/ 等)は先に落とす。落とさないと j の走査が
      余った空要素で止まり、突き合わせ可能な語まで不能に落ちる。"""
    asegs = [s for s in asegs if s]
    gsegs = [s for s in gsegs if s]
    out, j = [], 0
    for s in asegs:
        need, take = s, []
        while need and j < len(gsegs):
            g = gsegs[j]
            if not need.startswith(g):
                return None
            need = need[len(g):]
            take.append(j)
            j += 1
        if need:
            return None
        out.append(take)
    return out if j == len(gsegs) else None


g, a = parse(G), parse(A)
shared = set(g) & set(a)
cur = {}          # キー -> (見出し, ラテン分節, 学習者版, 学術版, 漢字, 語釈)
unaligned = []
for bare in shared:
    gsegs, gdisps, ggl = g[bare]
    asegs, adisps, agl = a[bare]
    if asegs == gsegs:
        continue                      # 粒度が同じ=融合が無いので対象外
    cov = align(asegs, gsegs)
    if cov is None:
        # ★2026-07-30: 突き合わせ不能な見出しを **件数だけで済ませてはいけない**。
        #   ここに落ちるのは主に同綴異義(esperant/o=言語名 vs esper/ant/o=希望する者、
        #   roman/o=小説 vs rom/an/o=ローマ人)で、bare形をキーにすると版ごとに
        #   別の語を拾ってしまう。実際にこの素通りが roman/a cifer/o⟦小说/a 数ᶜ/o⟧
        #   (ローマ数字を「小説の数字」と描画)の発見を1回遅らせた。
        #   件数に埋めず全件を列挙して目視に回す。
        unaligned.append((bare, '/'.join(gsegs) + '⟦' + '/'.join(gdisps) + '⟧',
                          '/'.join(asegs) + '⟦' + '/'.join(adisps) + '⟧'))
        continue
    for s, d, take in zip(asegs, adisps, cov):
        if len(take) < 2 or not has_cjk(d):
            continue
        for j in take:
            gs, gd = gsegs[j], gdisps[j]
            if not gs or gs in ENDSET or has_cjk(gd):
                continue
            # ★2026-07-30: 融合側の描画が **そのラテン綴りを字面どおり保っている** なら
            #   ラテン維持は履行されているので違反ではない。続53の是正後の
            #   kuriterapi⟦kuri疗⟧ がこれに当たる(疗があるので「漢字が付いている」判定に
            #   引っかかるが、kuri 自体はラテンのまま=裁定どおり)。
            #   この除外を入れないと、正しく直した箇所が永久に★新規として鳴り続ける。
            if gs in d:
                continue
            key = '\t'.join((bare, gs, strip_id(d)))
            cur[key] = (bare, gs, '/'.join(gsegs) + '⟦' + '/'.join(gdisps) + '⟧',
                        '/'.join(asegs) + '⟦' + '/'.join(adisps) + '⟧', d,
                        ggl.strip()[:70].replace('\t', ' '))

known = set()
if os.path.exists(BASE):
    for line in io.open(BASE, encoding='utf-8'):
        line = line.rstrip('\n')
        if line and not line.startswith('#'):
            known.add(line)

if '--accept' in sys.argv or not known:
    with io.open(BASE, 'w', encoding='utf-8', newline='\r\n') as w:
        w.write('# [O] 版間ラテン維持センチネル監査 受理台帳。\n')
        w.write('# 列: 見出し語<TAB>学習者版でラテンのまま残る分節<TAB>学術版が当てている漢字(識別子除去)\n')
        w.write('#\n')
        w.write('# ここにある行は「融合語根に独自の全体割当がある正当な粒度差」として受理済み。\n')
        w.write('# §4.6 が版間の粒度差を明示的に許容しており、klement(続16 ユーザー裁定A案)の\n')
        w.write('# 前例どおり **揃えない** のが方針。infrarug^=红外 / papilom=乳头瘤 / procent=率 の類。\n')
        w.write('#\n')
        w.write('# 台帳に無い行が現れたら [O] が ★新規 として報告する。**確定裁定(方針書§14.2.1)で\n')
        w.write('# ラテン維持と決めた語根に学術版だけ漢字が付いていないか** を必ず確認すること。\n')
        w.write('# 実例(続53): kuriterapi が 廷疗 と描かれていた(廷はCuria専用でCurie義に使えない)。\n')
        w.write('# 点検後に python _audit_latin_sentinel_crossversion.py --accept で更新する。\n')
        w.write('# 無条件に更新しないこと(確定裁定違反の見落としに直結する)。\n')
        for k in sorted(cur):
            w.write(k + '\n')
    print('[O] 受理台帳を更新: %d件' % len(cur))
    sys.exit(0)

new = sorted(set(cur) - known)
gone = sorted(known - set(cur))
out = ['[O] 版間ラテン維持: 照合%d見出し / 該当%d件(受理済%d) / ★新規=%d'
       % (len(shared), len(cur), len(cur) - len(new), len(new))]
for k in new:
    bare, gs, gline, aline, d, gl = cur[k]
    out.append('    ★新規: [%s] %-20s 学習者=%-30s 学術=%-24s' % (gs, bare, gline[:30], aline[:24]))
    out.append('           %s' % gl)
if new:
    out.append('    !! 学習者版がラテンを残す材料に学術版だけ漢字が付いた箇所がある。')
    out.append('       方針書§14.2.1の確定裁定でラテン維持と決めた語根でないかを必ず確認すること')
    out.append('       (続53実例: kuriterapi=廷疗。廷はCuria専用でCurie義に使うと裁定違反)。')
    out.append('       正当な粒度差と確認できたら python _audit_latin_sentinel_crossversion.py --accept')
if gone:
    out.append('    (参考)台帳にあって現在は該当しない=%d件。解消または正本の分解変更による' % len(gone))
if unaligned:
    out.append('    (参考)両版の分節列が突き合わせ不能=%d見出し。同綴異義で版ごとに別の語を'
               % len(unaligned))
    out.append('          拾っている箇所なので、bare形での機械照合はできない。全件を列挙するので目視すること:')
    for b, gl, al in sorted(unaligned):
        out.append('          %-18s 学習者=%-30s 学術=%s' % (b, gl[:30], al[:34]))
txt = '\n'.join(out)
print(txt)
with io.open("_audit_latin_sentinel_crossversion.tsv", 'w', encoding='utf-8', newline='') as f:
    f.write("判定\t見出し\tラテン維持分節\t学習者版\t学術版\t学術版の当該字\t語釈\n")
    for k in sorted(cur):
        bare, gs, gline, aline, d, gl = cur[k]
        f.write('\t'.join(('★新規' if k in set(new) else '受理済',
                           bare, gs, gline, aline, d, gl)) + '\n')
