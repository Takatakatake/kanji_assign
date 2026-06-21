import re,sys,io
sys.stdout=io.TextIOWrapper(sys.stdout.buffer,encoding='utf-8')

yiji=set()
with open('通用规范汉字表_一级3500字_画数.tsv',encoding='utf-8') as f:
    next(f)
    for line in f:
        c=line.split('\t')
        if len(c)>=2 and c[1]:
            yiji.add(c[1])
erji=set()
with open('通用规范汉字表_二级3000字_画数.tsv',encoding='utf-8') as f:
    next(f)
    for line in f:
        c=line.split('\t')
        if len(c)>=2 and c[1]:
            erji.add(c[1])
print("yiji size",len(yiji),"erji size",len(erji))

def is_cjk(ch):
    o=ord(ch)
    return (0x4E00<=o<=0x9FFF) or (0x3400<=o<=0x4DBF) or (0xF900<=o<=0xFAFF)

brk=re.compile(r'⟦([^⟧]*)⟧')
for fn in ['漢字注入_学習者版_20260620.txt','漢字注入_学術版_20260620.txt']:
    outside={}
    total_cjk=set()
    nlines=0
    with open(fn,encoding='utf-8') as f:
        for ln,line in enumerate(f,1):
            nlines=ln
            for m in brk.finditer(line):
                for ch in m.group(1):
                    if is_cjk(ch):
                        total_cjk.add(ch)
                        if ch not in yiji:
                            if ch not in outside:
                                outside[ch]=(ln,line.rstrip(),ch in erji)
    print("====",fn,"lines",nlines)
    print("distinct CJK in brackets:",len(total_cjk))
    print("CJK NOT in yiji (count):",len(outside))
    for ch in sorted(outside):
        ln,l,ine=outside[ch]
        print("  OUT:",ch,"U+%04X"%ord(ch),"erji=%s"%ine,"@line",ln,"::",l[:90])
