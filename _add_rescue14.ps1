# 第14次: 生物属§4.6一括救済(第13次)の latin据置121件を精査し、取りこぼした真の属7件を救済(2026-06-24)。
#   121件の大半は生物個体でなく解剖/形態/概念用語(allantois/phloem/xylem/cambium/gametofito/植物ホルモン/植生型)で据置が正。
#   真の属18件中、分類器(WF)が取りこぼした7件を救済(残り=原生動物/刺胞/ナメクジウオ等clean一级字なし=latin据置が正):
#     galag        → 猴  (Galago=ガラゴ。Prasimio=原猿。simioでなくPrasimio表記で取りこぼし)
#     kalam        → 木  (Calamus=トウ(籐)。de grimpaj... arboj=つる性樹木。1[Genro]2[別義]構造で取りこぼし)
#     ksanti       → 草  (Xanthium el asteracoj=オナモミ。キク科の草本)
#     patienc      → 草  (Rumex patientia=ニワヤナギ系ギシギシ。Sp. de rumekso=タデ科多年草)
#     talitr       → 虾  (Talitrus=ハマトビムシ。marbordaj krustacoj=海岸の甲殻)
#     volvok       → 藻  (Volvox=ボルボックス。duflagelaj protozooj klorofilohavaj=葉緑体を持つ緑藻)
#     klamidomonad → 藻  (Chlamydomonas=クラミドモナス。緑藻。protozoo/植物の両義で取りこぼし)
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
$resc=@( @('galag','猴','piv'), @('kalam','木','piv'), @('ksanti','草','piv'), @('patienc','草','piv'), @('talitr','虾','piv'), @('volvok','藻','piv'), @('klamidomonad','藻','piv') )
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
$hmap=@{}; foreach($r in $resc){ $hmap[$r[0]]=(ToHsys $r[0]) }
$F=@{}; foreach($r in $resc){ $F[$r[0]]=0 }
$dlines=[System.IO.File]::ReadAllLines($dict)
foreach($line in $dlines){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci)
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ foreach($r in $resc){ $rt=$r[0]; if(($s -ceq $hmap[$rt]) -and (-not $seen.ContainsKey($rt))){ $seen[$rt]=$true; $F[$rt]=$F[$rt]+1 } } } }
}
$mRoots=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){ [void]$mRoots.Add($p[1].Trim()) } }
$pwHas=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Import-Csv "$dir\_p_work.csv" -Encoding UTF8|ForEach-Object{ [void]$pwHas.Add($_.root) }
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1];$band=$r[2]
  if($mRoots.Contains($root) -or $pwHas.Contains($root)){ Write-Host ("skip(既存): $root"); $skip++; continue }
  $f=[int]$F[$root]; if($f -lt 1){$f=1}
  $brk=$BR[$band]; $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  $null=$mAdd.Add($band+"`t"+$root+"`t"+$k)
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=$brk;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P})
  Write-Host ("追加: {0}→{1} band={2} F={3} P={4}" -f $root,$k,$band,$f,$P)
}
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host ("master・_p_work 追記完了 ({0}件 / skip {1})" -f $mAdd.Count,$skip)
