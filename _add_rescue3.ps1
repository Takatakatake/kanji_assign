# 第3次救済(元素): 一级専用字が無い元素を上位カテゴリ字で救済。金属→金 / 希ガス・気体→气。
# 半金属(bor/selen/telur)・液体ハロゲン(brom)は境界=本スクリプトでは扱わない(別途ユーザー確認)。
# homonym元素 krom/o・titan/o は _build_homonym.ps1 側で金に(同綴の prep/giant と分離)。
# 既に一级字を持つ元素(铜铅锡锌硫磷氯碘锰钠硅)は維持。hidrogen/oksigen は分解合成(水/生)で除外。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$resc=@(
 # 金属・希土類・放射性金属 → 金
 @('berili','金'),@('bismut','金'),@('ceri','金'),@('cezi','金'),@('erbi','金'),@('eu^ropi','金'),@('gadolini','金'),
 @('gali','金'),@('germanium','金'),@('indi','金'),@('iridi','金'),@('iterbi','金'),@('itri','金'),@('kadmi','金'),
 @('kaliforni','金'),@('kobalt','金'),@('kromi','金'),@('lantan','金'),@('liti','金'),@('luteci','金'),@('magnezi','金'),
 @('molibden','金'),@('nikel','金'),@('osmi','金'),@('plutoni','金'),@('poloni','金'),@('radium','金'),@('skandi','金'),
 @('stronci','金'),@('tantal','金'),@('tori','金'),@('urani','金'),@('vanad','金'),@('volfram','金'),@('zirkoni','金'),
 # 希ガス・気体(フッ素含む) → 气
 @('heli','气'),@('helium','气'),@('argon','气'),@('ksenon','气'),@('neon','气'),@('kripton','气'),@('radon','气'),@('fluor','气'),
 # 半金属 → 矿(鉱物) / 液体ハロゲン brom → 卤(ハロゲン) 【2026-06-20 ユーザー確定】※bor は homonym のため _build_homonym 側
 @('selen','矿'),@('telur','矿'),@('antimon','矿'),@('arsen','矿'),@('brom','卤') )
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
$rset=@{}; foreach($r in $resc){ $rset[$r[0]]=$true }
$F=@{}; $nonpiv=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci); $isPiv=$line -match '【PIV】'
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ if($rset.ContainsKey($s) -and -not $seen.ContainsKey($s)){ $seen[$s]=$true; $F[$s]=1+($F[$s]); if(-not $isPiv){ $nonpiv[$s]=$true } } } }
}
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
Write-Host ("元素救済追加 {0}件 / スキップ(既存) {1}件" -f $mAdd.Count,$skip)
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host "master・_p_work 追記完了"