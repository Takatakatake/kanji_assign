# 第7次救済: 網羅スイープで露出した未対応生物種(2026-06-21)。最も近い一级字方針。
# notofag(Nothofagus=ナンキョクブナ·植)→树 / bufag(Buphagus=ウシツツキ·アフリカの鳥)→鸟 / poefag(Poephagus=gruntbovo·ヤク)→牛。
# いずれも辞書上は単一語根(分解されず)=fagセグメント非該当。skarab(甲)/pter(翅)は既済のため対象外。
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$resc=@( @('notofag','树'), @('bufag','鸟'), @('poefag','牛') )   # 3要素=フラット化しない
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
  if($mRoots.ContainsKey($root) -or $pwHas.ContainsKey($root)){ Write-Host ("skip(既存): $root"); $skip++; continue }
  $f=[int]$F[$root]; if($f -lt 1){$f=1}
  $band= if($nonpiv.ContainsKey($root)){'pejvo'}else{'piv'}; $brk=$BR[$band]
  $st=KStroke $k; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  $null=$mAdd.Add(($band+"`t"+$root+"`t"+$k))
  $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=$brk;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P})
  Write-Host ("追加: {0}→{1} band={2} F={3} P={4}" -f $root,$k,$band,$f,$P)
}
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host ("master・_p_work 追記完了 ({0}件 / skip {1})" -f $mAdd.Count,$skip)
