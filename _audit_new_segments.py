# -*- coding: utf-8 -*-
# [K] 新規露出分節の監査 (2026-07-26 第11レンズで新設)
#
# 【なぜ必要か】
# 2026-07-26 の1日だけで、正本(DICT)の分解変更により **偽の友が2回** 露出した:
#   ① nau^tik/o → nau^t/ik/o    … nau^t が未割当で 航/学 が壊れ、暫定対応が無印の航を横取り
#   ② ribosom/o → rib/o/som/o   … 成分 rib が【植】スグリ属 Ribes の 醋栗 を流用し
#                                  `rib/o/som/o⟦醋栗/o/体ˢᴹ/o⟧`(スグリの実の体)になった
# いずれも「これまで結合形だった語が分割され、成分が **別語根の既存割当をそのまま拾う**」型。
# 既存の監査では捕捉できない:
#   [A]id重複 も [F]偽分解整合性 も [J]描画の一意性 も「今の状態が壊れているか」しか見ず、
#   「新しく現れた分節が、たまたま同綴の別語根の字を拾っていないか」は見ていない。
#
# 【やること】
# 両版の見出しに現れる全分節を集め、ベースライン `_known_segments.txt` と比較して
# **新規に現れた分節** を報告する。新規分節が漢字で描画されていれば、それは
# 「その分節のために意図して割り当てた」のか「同綴の別語根から流用された」のかを
# 人が必ず判断すべき箇所なので ★ を付けて fail させる。
# 判断後は `--accept` でベースラインを更新する。
import io, os, re, sys
os.chdir(os.path.dirname(os.path.abspath(__file__)))
INJ = [('学習者版', '漢字注入_学習者版_20260620.txt'), ('学術版', '漢字注入_学術版_20260620.txt')]
BASE = '_known_segments.txt'
ENDSET = set(['ojn','ajn','oj','aj','on','an','en','as','is','os','us','o','a','e','i','u','j','n'])
CJK = lambda c: '一' <= c <= '鿿'
MARKRE = re.compile('[ʰ-˿ᴀ-ᶿ̀-ͯⱽ⁰-₟]')

cur = {}          # 分節 -> (漢字描画か, 代表行, 代表見出し, 語釈)
for ed, path in INJ:
    for n, line in enumerate(io.open(path, encoding='utf-8'), 1):
        line = line.rstrip('\n')
        if ':' not in line: continue
        if line.startswith('#'): continue          # 末尾の ##重複語 セクションは見出しではない
        head_disp, gloss = line.split(':', 1)
        m = re.match(r'^([^⟦]*)⟦([^⟧]*)⟧$', head_disp)
        head = m.group(1) if m else head_disp.strip()
        disp = m.group(2) if m else head
        hw, dw = head.split(' '), disp.split(' ')
        if len(hw) != len(dw): dw = hw
        for wh, wd in zip(hw, dw):
            hs, ds = wh.split('/'), wd.split('/')
            if len(hs) != len(ds): ds = hs
            for seg, dsp in zip(hs, ds):
                if not seg or seg in ENDSET: continue
                bare = ''.join(c for c in MARKRE.sub('', dsp) if CJK(c))
                if seg not in cur or (bare and not cur[seg][0]):
                    cur[seg] = (bare, n, wh, gloss.strip()[:64])

# 見出しも記録する。ribosom/o → rib/o/som/o の様に **成分がすべて既知の分節** の場合、
# 新規分節が1つも出ないため分節だけでは捕捉できない。見出しの変化がその唯一の signal になる。
heads = set()
for ed, path in INJ:
    for line in io.open(path, encoding='utf-8'):
        line = line.rstrip('\n')
        if ':' not in line or line.startswith('#'): continue
        hd = line.split(':', 1)[0]
        m = re.match(r'^([^⟦]*)⟦([^⟧]*)⟧$', hd)
        if not m: continue                       # 漢字描画のある見出しだけ追う
        heads.add(ed[:2] + '\t' + m.group(1))   # 2026-07-26 是正: 従来 ed[:1] は学習者版/学術版がどちらも '学' に潰れ版の区別が消えていた

known = set(); known_heads = set()
if os.path.exists(BASE):
    for line in io.open(BASE, encoding='utf-8'):
        line = line.rstrip('\n')
        if not line or line.startswith('#'): continue
        if line.startswith('H\t'): known_heads.add(line[2:])
        else: known.add(line)

if '--accept' in sys.argv or not (known or known_heads):
    with io.open(BASE, 'w', encoding='utf-8', newline='\r\n') as w:
        w.write('# [K] 新規露出分節の監査 ベースライン。\n')
        w.write('#   無印行 = 両版の見出しに現れる分節(文法語尾を除く)\n')
        w.write('#   H<TAB> = 漢字描画のある見出し(版頭文字つき)。正本が語を分割/統合すると変化する。\n')
        w.write('# 正本の分解変更でここに無いものが現れたら [K] が報告する。内容を点検してから\n')
        w.write('#   python _audit_new_segments.py --accept\n')
        w.write('# で更新すること。無条件に更新しないこと(偽の友の見落としに直結する)。\n')
        for s in sorted(cur): w.write(s + '\n')
        for h in sorted(heads): w.write('H\t' + h + '\n')
    print('[K] ベースラインを更新: %d分節 / %d見出し' % (len(cur), len(heads)))
    sys.exit(0)

new = sorted(set(cur) - known)
kanji_new = [s for s in new if cur[s][0]]
latin_new = [s for s in new if not cur[s][0]]
new_heads = sorted(heads - known_heads)
out = []
out.append('[K] 新規露出: 分節%d(★漢字描画=%d / latin=%d) / 漢字描画の新規見出し=%d'
           % (len(new), len(kanji_new), len(latin_new), len(new_heads)))
for s in kanji_new:
    bare, n, wh, gl = cur[s]
    out.append('    ★漢字描画された新規分節: %-14s → %-8s L%-6d %-28s %s' % (s, bare, n, wh[:28], gl))
for h in new_heads[:25]:
    out.append('     新規見出し(要点検): %s' % h.replace('\t', ' '))
if len(new_heads) > 25:
    out.append('     ... 新規見出しは他 %d件' % (len(new_heads) - 25))
if new_heads:
    out.append('     ※正本が語を分割/統合した箇所。成分が既存の同綴別語の字を拾っていないか目視すること')
    out.append('       (2026-07-26 実例: ribosom/o→rib/o/som/o で rib が【植】スグリ属の 醋栗 を拾った)')
txt = '\n'.join(out)
try: sys.stdout.write(txt + '\n')
except Exception: sys.stdout.write(txt.encode('ascii', 'replace').decode('ascii') + '\n')
sys.exit(1 if kanji_new else 0)
