# 第13次: PIV尾部の未対応 単一形態素 生物属を §4.6(最近一级字)で一括救済(2026-06-24)。
#   ユーザー裁定「生物種は専用一级字が無い場合の最近一级字の代用で解決できる限り解決」。
#   分類は44エージェント言語判断WF(classify-genera-piv-tail)で実施→ _genera_rescue.tsv(root<TAB>category字 1016件)。
#   category字パレット(全一级): 鸟鱼蛇龟龙蛙兽猴鼠虫蛛虾贝草木藻菌苔。分類不能116件はlatin据置(正)。
#   全て band=piv(PIV専・単一形態素属名)。既存base(同category字の上位root)は rank で保護され不変、新規のみ§9識別子付き。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLen([string]$s){ $h=ToHsys $s; $n=0; for($i=0;$i -lt $h.Length;$i++){ if($i+1 -lt $h.Length -and $h[$i+1] -eq '^'){$i++}; $n++ }; $n }
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
function KStroke([string]$k){ $t=0; foreach($ch in $k.ToCharArray()){ $cs=[string]$ch; if($stroke.ContainsKey($cs)){ $t+=$stroke[$cs] } }; if($t -lt 1){$t=1}; return $t }
# 救済リスト読み込み(root<TAB>char)。h-system化(念のため)。
$resc=@(); Get-Content "$dir\_genera_rescue.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2 -and $p[0].Trim() -and $p[1].Trim()){ $resc+=,@((ToHsys $p[0].Trim()),$p[1].Trim()) } }
Write-Host ("救済リスト {0} 件" -f $resc.Count)
# F = root を分節に含む見出し数(全救済rootを1パスで集計)
$rootSet=@{}; foreach($r in $resc){ $rootSet[$r[0]]=0 }
foreach($line in [System.IO.File]::ReadAllLines($dict)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci)
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ if($rootSet.ContainsKey($s) -and -not $seen.ContainsKey($s)){ $seen[$s]=$true; $rootSet[$s]=$rootSet[$s]+1 } } }
}
$mRoots=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){ [void]$mRoots.Add($p[1].Trim()) } }
$pwHas=[System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
Import-Csv "$dir\_p_work.csv" -Encoding UTF8|ForEach-Object{ [void]$pwHas.Add($_.root) }
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList; $skip=0
foreach($r in $resc){ $root=$r[0];$k=$r[1];$band='piv'
  if($mRoots.Contains($root) -or $pwHas.Contains($root)){ $skip++; continue }
  $f=[int]$rootSet[$root]; if($f -lt 1){$f=1}
  $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  $null=$mAdd.Add($band+"`t"+$root+"`t"+$k)
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=2;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P})
}
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host ("master・_p_work 追記完了 ({0}件 / skip既存 {1})" -f $mAdd.Count,$skip)