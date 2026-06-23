# 第12次: PIV尾部の §4.6 救済漏れ生物属 4件(2026-06-24 最終収束WF後の尾部精査)。
#   procion(第11次)と同型=「科形 X/ed/oj⟦X/科ᴱ⟧ は科だけ漢字化・属幹 X はラテン残存」の非対称を解消。
#   いずれも n≥2(属/科/目 形あり)・PIV専・既救済の同類(トカゲ→龙/鳥→鸟/魚→鱼)と整合。
#     agam  → 龙  (Agama=アガマ。reptilioj el subordo lacertuloj=トカゲ亜目。scink と同じ。agam/ed/oj=Agamidae)
#     koraci→ 鸟  (Coracias=ブッポウソウ。birdoj=鳥。koraci/ed/oj=Coraciidae・koraci/form/aj=Coraciiformes)
#     scink → 龙  (Scincus=スキンク。reptilioj lacertuloj=トカゲ。scink/ed/oj=Scincidae)
#     zeu^s → 鱼  (Zeus=マトウダイ。teleosteoj/fis^oj=硬骨魚。zeu^s/ed/oj=Zeidae・zeu^s/o/form/aj=Zeiformes。神Zeusでなく魚属)
#   ※psil は除外: psil/o=蛇使い(別義の同綴)で master救済すると蛇使いが虫化するため(insect科 psil/ed のみは sep が要るが obscure につき据置)。
#   大文字始(Agam/Scink 等の固有名)は §7 大文字ガードでラテン保持のまま不変。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
$resc=@( @('agam','龙','piv'), @('koraci','鸟','piv'), @('scink','龙','piv'), @('zeu^s','鱼','piv') )
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
