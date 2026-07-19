# -*- coding: utf-8 -*-
"""
残渣センサス(再現可能) - 2026-07-20 第23回で新設(別AI監査「再現不能」是正)。
学術版/学習者版の注入出力から、漢字化されず純ラテンのまま残る語根形態素を集計し、
「分解鏡像で隙間充填できる真の被覆穴」を抽出する。

使い方:  python _residue_census.py            # 3ファイル出力(下記OUT_*)
出力:
  _residue_census_pure.tsv    : 純ラテン語根残渣の全数(頻度つき・両版)
  _residue_census_strict.tsv  : 厳格フィルタ=「学術版に純ラテン残渣 かつ 同一行の学習者版が完全漢字化」
                                = 真の被覆穴(固有名§7は両版ラテンゆえ自動除外される)
  _residue_census_stats.txt   : 件数サマリ(異なり語根・行数)

判定規則(このスクリプトが唯一の正典):
  - ⟦…⟧ 内が漢字化欄。/ と空白で分節。
  - 純ラテン語根残渣 = 分節が ^[A-Za-z^]+$ (ローマ字+エス字^) かつ 文法語尾GRAM でない。
  - GRAM(残ってよい文法語尾) = o a e i oj aj ojn ajn on an en in u us is as os j n um。
  - 厳格フィルタ = 学術版にPURE残渣あり and 学習者版にPURE残渣ゼロ(=完全漢字化)。
除外(手作業triageで HELD、_residue_census_gapfill_20260720.tsv に記録):
  - 固有名/民族/人名/地名/機関/宗教(§7 latin。両版ラテンゆえ厳格フィルタで自動除外)。
  - 化学ノメンクラチャ(塩-at/酵素-az/-id/-in/-oz/アルカン-an等。ユーザー「評価のみ」裁定 第13回)。
  - 誤友除外(綴り衝突で他語巻き込みリスク=riboz/kromiat/litograf/vulkaniz)。
  - 同綴トラップ固有名(学習者が同綴別語経由で偶然漢字化=ioni离子/kolombi鸽/liberi自由/mali反/rom小说)。
"""
import io, re, collections
OPEN='⟦'; CLOSE='⟧'
GRAM=set("o a e i oj aj ojn ajn on an en in u us is as os j n um".split())
PURE=re.compile(r'^[A-Za-z^]+$')
LEARNER='漢字注入_学習者版_20260620.txt'
ACADEMIC='漢字注入_学術版_20260620.txt'

def field(line):
    m=re.search(re.escape(OPEN)+'(.*?)'+re.escape(CLOSE), line)
    return m.group(1) if m else None

def pure_latin_segs(fld):
    return [t for t in re.split(r'[/\s]+', fld)
            if t and PURE.match(t) and t not in GRAM]

def main():
    aca=io.open(ACADEMIC,encoding='utf-8').read().splitlines()
    lrn=io.open(LEARNER,encoding='utf-8').read().splitlines()
    n=min(len(aca),len(lrn))
    # 1) pure residue census (both versions)
    with io.open('_residue_census_pure.tsv','w',encoding='utf-8') as o:
        for label,src in (('academic',aca),('learner',lrn)):
            c=collections.Counter(); ex={}
            for line in src:
                f=field(line)
                if not f: continue
                for s in pure_latin_segs(f):
                    c[s]+=1
                    ex.setdefault(s,line.split(OPEN)[0].strip())
            o.write('# %s: distinct=%d total=%d\n'%(label,len(c),sum(c.values())))
            for seg,cnt in c.most_common():
                o.write('%s\t%d\t%s\t%s\n'%(label,cnt,seg,ex[seg]))
    # 2) strict mirror-gap (academic latin residue AND learner fully kanjified)
    strict_lines=0; strict_roots=set()
    with io.open('_residue_census_strict.tsv','w',encoding='utf-8') as o:
        o.write('# line\thead\tACA_field\tLRN_field\tlatin_roots\n')
        for i in range(n):
            fa=field(aca[i]); fl=field(lrn[i])
            if not fa or not fl: continue
            la=pure_latin_segs(fa); ll=pure_latin_segs(fl)
            if la and not ll:
                strict_lines+=1
                for r in la: strict_roots.add(r)
                o.write('%d\t%s\t%s\t%s\t%s\n'%(i+1,aca[i].split(OPEN)[0].strip(),fa,fl,','.join(la)))
    with io.open('_residue_census_stats.txt','w',encoding='utf-8') as o:
        o.write('strict mirror-gap: lines=%d distinct_roots=%d\n'%(strict_lines,len(strict_roots)))
        o.write('strict distinct roots: %s\n'%(' '.join(sorted(strict_roots))))
    print('census done: strict lines=%d roots=%d'%(strict_lines,len(strict_roots)))

if __name__=='__main__':
    main()
