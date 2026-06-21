# 第2次救済(n>=2 の未対応 content 語根、主にPIV生物属)を master + _p_work に追記。最近一级字。
# 123件(間投詞/字名/化学/一级字なしトカゲ類/固有名 22件は未対応のまま)。multi-char漢字は画数合算。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$resc=@(
 # 藻(藻類)
 @('fic','藻'),@('bangi','藻'),@('fuk','藻'),@('ulv','藻'),
 # 苔/禾
 @('bri','苔'),@('gramin','禾'),
 # 草(草本)
 @('psilot','草'),@('apocin','草'),@('aizo','草'),@('psilofit','草'),@('umbelifer','草'),@('asklepiad','草'),
 @('solan','草'),@('arum','草'),@('lentibulari','草'),@('borag','草'),@('niktag','草'),
 # 木(木本)
 @('akvifoli','木'),@('magnoli','木'),@('evonim','木'),@('berberis','木'),@('fenik','木'),@('dipterokarp','木'),
 @('kupres','木'),@('hipokastan','木'),@('anakardi','木'),@('simarub','木'),@('burser','木'),@('grosulari','木'),
 @('gnet','木'),@('kluzi','木'),
 # 花/菊
 @('amarilid','花'),@('balzamin','花'),@('enoter','花'),@('aster','菊'),@('lekant','菊'),
 # 椒/辣/豆
 @('piper','椒'),@('kajen','辣'),@('legumen','豆'),
 # 鱼
 @('c^ot','鱼'),@('trigl','鱼'),@('mola','鱼'),@('labr','鱼'),@('spar','鱼'),@('seran','鱼'),
 # 鸟
 @('cinkl','鸟'),@('alced','鸟'),@('galbul','鸟'),@('tetraon','鸟'),@('au^k','鸟'),@('oriol','鸟'),@('ploce','鸟'),
 @('upup','鸟'),@('katart','鸟'),@('sturn','鸟'),@('paru','鸟'),@('ptilonorink','鸟'),
 # 虫(昆虫・節足・原生)
 @('harpal','虫'),@('geotrup','虫'),@('karab','虫'),@('frigan','虫'),@('cerambik','虫'),@('anobi','虫'),
 @('elater','虫'),@('afid','虫'),@('aleu^rod','虫'),@('krizomel','虫'),@('tortrik','虫'),@('drozofil','虫'),
 @('taban','虫'),@('tine','虫'),@('ojstr','虫'),@('tipul','虫'),@('alveolin','虫'),@('fuzulin','虫'),
 # 蝶/蛛/蜂
 @('papilion','蝶'),@('pierid','蝶'),@('terafoz','蛛'),@('cinip','蜂'),
 # 蛙(両生)/龟
 @('hil','蛙'),@('salamandr','蛙'),@('emid','龟'),@('keloni','龟'),
 # 鼠(齧歯・小型)
 @('didelf','鼠'),@('sorik','鼠'),@('kavi','鼠'),
 # 猴(サル)
 @('ceb','猴'),@('hapal','猴'),@('kalitriks','猴'),@('kolob','猴'),@('cerkopitek','猴'),
 # 猫/犬/马/猪/鹿/犀/蝠
 @('felis','猫'),@('kanis','犬'),@('onagr','马'),@('su','猪'),@('tragol','鹿'),@('rinocer','犀'),
 @('filostom','蝠'),@('vespertilion','蝠'),
 # 兽(その他哺乳)
 @('dazipod','兽'),@('mirmekofag','兽'),@('falanger','兽'),@('lutr','兽'),@('viver','兽'),@('otari','兽'),
 # 蛇/蟹/虾/贝
 @('kolubr','蛇'),@('elap','蛇'),@('viper','蛇'),@('pagur','蟹'),@('limul','蟹'),
 @('salikok','虾'),@('pandal','虾'),@('pene','虾'),@('folad','贝'),
 # 菌
 @('botul','菌'),@('leptospir','菌'),
 # 非生物の内容語
 @('ile','肠'),@('fuel','燃'),@('okult','秘'),@('diskurs','辩'),@('laz','套'),@('hebet','钝'),@('erizipel','丹毒'),
 # 大型トカゲ(イグアナ/オオトカゲ)=龙(竜・evocative)。小型(scink/agam)は龙が過大→未対応(_untargeted.tsv)。2026-06-20ユーザー確定
 @('varan','龙'),@('igvan','龙') )
# 画数(一级)
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
# 辞書から各語根の見出し数F + PIV専用判定
$rset=@{}; foreach($r in $resc){ $rset[$r[0]]=$true }
$F=@{}; $nonpiv=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci); $isPiv=$line -match '【PIV】'
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ if($rset.ContainsKey($s) -and -not $seen.ContainsKey($s)){ $seen[$s]=$true; $F[$s]=1+($F[$s]); if(-not $isPiv){ $nonpiv[$s]=$true } } } }
}
# 既存root(二重追記ガード)
$mRoots=@{}; Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){ $mRoots[$p[1].Trim()]=$true } }
$pwHas=@{}; Import-Csv "$dir\_p_work.csv" -Encoding UTF8|ForEach-Object{ $pwHas[$_.root]=$true }
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1]
  if($mRoots.ContainsKey($root) -or $pwHas.ContainsKey($root)){ $skip++; continue }
  $f=[int]$F[$root]; if($f -lt 1){$f=1}
  $band= if($nonpiv.ContainsKey($root)){'pejvo'}else{'piv'}; $brk=$BR[$band]
  $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  $null=$mAdd.Add(($band+"`t"+$root+"`t"+$k))
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=$brk;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P})
}
Write-Host ("救済追加 {0}件 / スキップ(既存) {1}件" -f $mAdd.Count,$skip)
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host "master・_p_work 追記完了"