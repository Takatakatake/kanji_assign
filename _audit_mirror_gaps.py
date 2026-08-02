# -*- coding: utf-8 -*-
"""学術版whole-rootがラテンで、学習者版は完全漢字化されている見出し=鏡像充填の候補を悉皆列挙。

両版は行対応(同じ 62,313 行)。各行で
  ・学術版の分節スペルと学習者版の分節スペルを【累積綴りで対応づけ】る
    (学術 `litograf` ⇔ 学習 `lit`+`o`+`graf`)
  ・学術側が漢字ゼロ(=ラテン)で、対応する学習者側が全て漢字(連結母音を除く)なら候補
  ・鏡像 = 学習者側の漢字を識別子ごと連結(§14.2.1 続62 案A)
"""
import io, os, re, sys, collections

sys.stdout.reconfigure(encoding='utf-8')
os.chdir(r"d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\エスペラントの漢字化プロジェクト総結集20260630\エスペラント語根＿漢字割り当て＿20260630")
GAK = "漢字注入_学術版_20260620.txt"
GAU = "漢字注入_学習者版_20260620.txt"
ENDSET = {'o', 'a', 'e', 'i', 'u', 'as', 'is', 'os', 'us', 'j', 'n', 'oj', 'aj', 'ojn', 'ajn', 'n'}
LINK = {'o', 'a', 'e', 'i'}          # 連結母音(単独では漢字にならない)


def is_cjk(c):
    return '一' <= c <= '鿿'


def parse(line):
    line = line.rstrip('\n')
    if not line or line.startswith('#') or ':' not in line:
        return None
    head = line.split(':', 1)[0]
    if '⟦' in head:
        raw = head[:head.index('⟦')]
        box = head[head.index('⟦') + 1:head.rindex('⟧')]
    else:
        raw, box = head, head
    if ' ' in raw:
        return None
    rs = [x for x in raw.split('/') if x]
    bs = [x for x in box.split('/') if x]
    if len(rs) != len(bs):
        bs = rs
    return rs, bs


cand = collections.defaultdict(lambda: {'words': [], 'mirror': None, 'learner': None, 'conflict': None})
A = io.open(GAK, encoding='utf-8-sig').read().split('\n')
B = io.open(GAU, encoding='utf-8-sig').read().split('\n')
n_align = 0
for i in range(min(len(A), len(B))):
    pa, pb = parse(A[i]), parse(B[i])
    if not pa or not pb:
        continue
    ars, abs_ = pa
    brs, bbs = pb
    if ''.join(ars) != ''.join(brs):
        continue                      # 分節が版間で別語 = 対応づけ不能
    n_align += 1
    j = 0
    for k, seg in enumerate(ars):
        # 学習者側で seg と同じ綴りになるまで消費
        acc, sub, subk = '', [], []
        while j < len(brs) and len(acc) < len(seg):
            acc += brs[j]
            sub.append(brs[j])
            subk.append(bbs[j])
            j += 1
        if acc != seg:
            break
        if len(sub) <= 1:
            continue                  # 分節粒度が同じ=鏡像の出番ではない
        # ★除外1: 先頭以外が全て文法語尾 = root+語尾であって複合語ではない
        #   (kolombi=kolomb/i・mali=mal/i・roe=ro/e・mari=mar/i。これを入れると
        #    「動詞語尾を落とした語根」を新語根として登録してしまう)
        if all(x in ENDSET for x in sub[1:]):
            continue
        if any(is_cjk(c) for c in abs_[k]):
            continue                  # 学術側は既に漢字化済
        if seg in ENDSET:
            continue
        # 学習者側: 連結母音以外は全て漢字であること
        parts = []
        ok = True
        for s, kk in zip(sub, subk):
            if s in LINK and not any(is_cjk(c) for c in kk):
                continue              # 連結母音は落とす
            if not any(is_cjk(c) for c in kk):
                ok = False
                break
            parts.append(kk)
        if not ok or not parts:
            continue
        mir = ''.join(parts)
        # ★除外2: 鏡像にラテン/数字/ハイフンが混じるもの(adenozin-trifosfat・2,2,4-trimetil)
        #   = 成分の一部が未割当なので「完全な鏡像」にならない
        import unicodedata as _ud
        if any((not is_cjk(c)) and _ud.category(c) not in ('Lm', 'Mn', 'Sk') for c in mir):
            continue
        d = cand[seg]
        d['mirror'] = mir
        d['learner'] = '/'.join('%s' % x for x in subk)
        d['words'].append(A[i].split(':', 1)[0])

# 既存groupkeyとの衝突
gk = {}
for l in io.open('_identifier_sidecar.tsv', encoding='utf-8-sig'):
    p = [x.strip().strip('"') for x in l.rstrip('\n').split('\t')]
    if len(p) < 8 or p[0] == 'root':
        continue
    gk.setdefault(p[7], []).append(p[0])
inuse = set()
for l in io.open('_p_work.csv', encoding='utf-8-sig'):
    if l.startswith('"'):
        inuse.add(l.split('","')[0].lstrip('"'))

print("行対応できた見出し %d" % n_align)
print("★鏡像充填の候補語根 = %d" % len(cand))
print()
print("%-20s %-14s %-24s %5s %s" % ("語根", "鏡像(案A)", "学習者版の成分", "見出", "備考"))
rows = sorted(cand.items(), key=lambda x: -len(x[1]['words']))
for r, d in rows:
    note = []
    if r in inuse:
        note.append('★既に_p_work登録あり')
    if d['mirror'] in gk:
        note.append('群衝突=' + ','.join(gk[d['mirror']][:3]))
    print("%-20s %-14s %-24s %5d %s" % (r, d['mirror'], d['learner'], len(d['words']), ' '.join(note)))
print()
print("合計見出し数 %d" % sum(len(d['words']) for _, d in rows))
with io.open('_audit_mirror_gaps.tsv', 'w', encoding='utf-8', newline='') as f:
    f.write("語根\t鏡像案A\t学習者版成分\t見出し数\t見出し例\t備考\n")
    for r, d in rows:
        note = ('登録済' if r in inuse else '') + ('/群衝突' if d['mirror'] in gk else '')
        f.write("%s\t%s\t%s\t%d\t%s\t%s\n" % (r, d['mirror'], d['learner'], len(d['words']),
                                              ' | '.join(d['words'][:4]), note))
