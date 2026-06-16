# -*- coding: utf-8 -*-
import sys, io
sys.stdout.reconfigure(encoding="utf-8")
path=r"D:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613\通用规范汉字表_一级3500字.txt"
chars=set()
with io.open(path,encoding="utf-8-sig") as f:
    for line in f:
        c=line.strip()
        if c:
            chars.add(c)
print("count:", len(chars))

tests="睾丸蛋球卵男根疮下疾病溃烂酸核苷糖磷天使神炽圣赭红褐土泥色黄榛树木果鼬鼠貂林俚俗语话戗逆风行帆曲折船镧睡硬鬼阴囊肾茎毒栗梨细菌嫩枝皮种子坚老鼠野"
for v in tests:
    print(v, "Y" if v in chars else "N")
