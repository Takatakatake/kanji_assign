# 同綴異義台帳(_homonym.tsv)を網羅版に再構築。型(sep=見出し分離可 / amb=同一文字列→語義判別)を辞書行数で自動判定。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$lines=Get-Content $dict -Encoding UTF8
# 既存10(全sep)
$existing=@(
 @('graf','伯','graf/o,graf/in/o,graf/land/o,graf/a','','伯爵。-graf-=记と別'),
 @('epi','后','epi/log/o,epi/taf/o,epi/gon/o','','epi-=後。epi=表と別'),
 @('krom','铬','krom/o,krom/at/o','','クロム。前置詞krom=外と別'),
 @('bor','硼','bor/o','','ホウ素。bor/i=钻と別'),
 @('titan','钛','titan/o','','チタン。巨人titanは別'),
 @('tetr','四','tetr/','','tetra-接頭辞。鳥tetr/o=琴鸡が既定'),
 @('kaj','码','kaj/o,kaj/oj','','埠頭。接続詞kaj=和と別'),
 @('log','诱','log/i,log/aj^/o','','誘惑。-log-=学家と別'),
 @('c^iel','天','c^iel/o,c^iel/a','','空。相関詞c^iel=全样と別'),
 @('c^ar','车','c^ar/o,c^ar/ist/o','','荷車。接続詞c^ar=因と別') )
# 新54(root,override,headwordForm,2nd義キーワード(amb判別用),note)
$new=@(
 @('al','翼','al/o','翼','翼。前置詞al=向と別'),@('por','孔','por/o,por/a','孔','気孔。前置詞por=为と別'),@('sur','腿','sur/o','ふくらはぎ','ふくらはぎ。前置詞sur=上と別'),
 @('el','酒','el/o','エール','エール。前置詞el=出と別'),@('plum','笔','plum/o','ペン','ペン。plum=羽と同綴'),@('mat','将','mat/o,mat/i','詰','チェス詰み。mat=席と別行'),
 @('pat','困','pat/o','手詰','ステールメイト。pat=锅と別行'),@('vat','瓦','vat/o,vat/hor/o','ワット','ワット。vat=棉と別行'),@('kanon','典','kanon/o,kanon/a','典','正典/カノン。kanon=炮と別行'),
 @('karp','腕','karp/o','手首','手根。karp=鲤と別行'),@('sakr','荐','sakr/o,sakr/a','仙骨','仙骨。sakr=骂と別'),@('deviz','汇','deviz/o','外貨','外貨。deviz=铭と同綴'),
 @('mark','币','mark/o','マルク','マルク。mark=标と別行'),@('lir','币','lir/o','リラ','リラ通貨。lir=琴と別行'),@('kron','币','kron/o','クローネ','クローネ。kron=冠と別行'),
 @('dur','币','dur/o','ドゥーロ','ドゥーロ銀貨。dur=硬と別'),@('tak','币','tak/o','タカ','タカ通貨。tak=倾と別'),@('bac','币','bac/o','硬貨','古独貨。bac=响と別'),
 @('ar','亩','ar/o','アール','アール面積。ar=群と別行'),@('luks','照','luks/o','ルクス','ルクス照度。luks=奢と別行'),@('stok','粘','stok/o','ストークス','ストークス粘度。stok=储と別行'),
 @('kuri','居','kuri/o','キュリー','キュリー。kuri=廷と別行'),@('fon','响','fon/o','ホン','ホン音量。fon=底と別'),
 @('ot','耳','ot/o,ot/a','耳','耳(oto-)。ot=待と別'),@('mi','肌','mi/o','筋','筋(mio-)。mi=我と別'),@('trik','毛','trik/o','毛','毛(tricho-)。trik=织と別'),
 @('spin','旋','spin/o','スピン','物理スピン。spin=脊と別行'),@('var','内','var/a','内反','内反varus。var=货と別'),@('orkid','丸','orkid/o','睾丸','睾丸。orkid=兰と別'),
 @('spat','苞','spat/o','仏炎','仏炎苞。spat=石と別行'),@('sol','溶','sol/o','ゾル','ゾル。sol=唯と別行'),@('siren','牛','siren/o','海牛','海牛類。siren=警笛と別行'),
 @('ergot','距','ergot/o','蹴爪','蹴爪。ergot=麦角と別'),@('sor','胞','sor/o','胞子','胞子嚢群。sor=腾と別'),@('panikl','脂','panikl/o','皮下','皮下脂肪。panikl=圆锥と別'),
 @('rod','泊','rod/o','停泊','停泊地。rod=啃と別行'),@('bit','桩','bit/o','繋柱','繋柱。bit=位と別行'),@('jard','杆','jard/o','帆桁','帆桁。jard=码と別'),
 @('prot','匠','prot/o','組版','組版長。prot=质子と別'),@('prim','祷','prim/o','一時課','一時課。prim=质数と同行'),@('pic^','调','pic^/o','音高','音高。pic^=阴户と別行'),
 @('lab','验','lab/o','実験室','実験室。lab=皱胃と別'),@('arke','菌','arke/o,arke/oj','古細菌','古細菌。arke=方舟と別'),@('abak','顶','abak/o','柱頭','柱頭。abak=算盘と別'),
 @('file','线','file/o','罫線','罫線。file=里脊と別'),@('peon','佃','peon/o','隷農','隷農。peon=卒と別'),@('tang','舞','tang/o','タンゴ','タンゴ。tang=颠と別行'),
 @('klik','派','klik/o','徒党','徒党。klik=爪と別'),@('topik','敷','topik/o','外用','外用薬。topik=题と別'),@('er','纪','er/o','紀元','紀元。er=粒と別行'),
 @('po','草','po/o','Poa','Poa属。po=每と別行'),@('line','草','line/o','リンネ','リンネ草。line=线と別行'),@('tof','瘤','tof/o','痛風','痛風結節。tof=凝灰と別'),
 @('male','疫','male/o','鼻疽','馬鼻疽。male=捶と別行'),@('sinus','弦','sinus/o','正弦','正弦sine。sinus=洞と別行') )
$rows=New-Object System.Collections.ArrayList
[void]$rows.Add("segment`toverride`ttype`tdisc`tnote")
foreach($e in $existing){ [void]$rows.Add(($e[0]+"`t"+$e[1]+"`tsep`t"+$e[2]+"`t"+$e[4])) }
$sepN=0;$ambN=0
foreach($e in $new){ $root=$e[0];$ov=$e[1];$hw=$e[2];$kw=$e[3];$note=$e[4]
  $hw1=($hw -split ',')[0]; $hwe=[regex]::Escape($hw1)
  $n=@($lines|Where-Object{ $_ -match ("^"+$hwe+":") }).Count
  if($n -ge 2){ $type='amb'; $disc=$kw; $ambN++ } else { $type='sep'; $disc=$hw; $sepN++ }
  [void]$rows.Add(($root+"`t"+$ov+"`t"+$type+"`t"+$disc+"`t"+$note)) }
[System.IO.File]::WriteAllLines("$dir\_homonym.tsv", $rows, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("台帳再構築: 既存10(sep) + 新54 = 計{0}行 / sep {1} / amb {2}" -f ($rows.Count-1),(10+$sepN),$ambN)
Write-Host "--- amb(同一文字列・注入時に語義で判別) ---"
$rows|Where-Object{$_ -match "`tamb`t"}|ForEach-Object{ $p=$_ -split "`t"; "  {0,-7} →{1}  語義キー『{2}』" -f $p[0],$p[1],$p[3] }