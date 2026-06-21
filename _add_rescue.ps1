# 未対応救済22件を master + _p_work に追記(最も近い一级字)。F=辞書見出し数, band=pejvo/piv(PIV専用判定), P=-(ln(F+1)+0.3E-0.1D)
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$dict="$dir\20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学習者版_utf8_20260416.txt"
$BR=@{ 'basic'=0;'pejvo'=1;'sci'=1;'piv'=2 }
function EoLen([string]$s){ $n=0; for($i=0;$i -lt $s.Length;$i++){ if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){$i++}; $n++ }; $n }
$resc=@(
 @('citron','果'),@('turd','鸟'),@('kres','草'),@('merin','羊'),@('gujav','果'),@('graviol','果'),@('c^erimoli','果'),
 @('kola','木'),@('terebint','木'),@('c^ampan','酒'),@('kopaiv','木'),@('mate','茶'),@('piran','鱼'),@('loganber','果'),
 @('viburn','木'),@('anagal','草'),@('tinam','鸟'),@('ranunkol','草'),@('tragant','草'),@('arame','藻'),@('karakul','羊'),@('oksiur','虫') )
# 画数(一级)
$stroke=@{}; Get-Content "$dir\通用规范汉字表_一级3500字_画数.tsv" -Encoding UTF8|Select-Object -Skip 1|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 4){ $stroke[$p[1].Trim()]=[int]$p[3].Trim() } }
# 辞書から各語根の見出し数F + PIV専用判定
$endingRe='^(o|a|e|i|u|oj|aj|on|an|ojn|ajn|en|as|is|os|us|u|j|n)$'
$rset=@{}; foreach($r in $resc){ $rset[$r[0]]=$true }
$F=@{}; $nonpiv=@{}
foreach($line in (Get-Content $dict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){continue}; $head=$line.Substring(0,$ci); $isPiv=$line -match '【PIV】'
  $seen=@{}
  foreach($w in ($head -split ' ')){ foreach($s in ($w -split '/')){ if($rset.ContainsKey($s) -and -not $seen.ContainsKey($s)){ $seen[$s]=$true; $F[$s]=1+($F[$s]); if(-not $isPiv){ $nonpiv[$s]=$true } } } }
}
# master/_p_work の既存root(二重追記ガード)
$mRoots=@{}; Get-Content "$dir\_kanji_map_master.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){ $mRoots[$p[1].Trim()]=$true } }
$pwHas=@{}; Import-Csv "$dir\_p_work.csv" -Encoding UTF8|ForEach-Object{ $pwHas[$_.root]=$true }
$mAdd=New-Object System.Collections.ArrayList; $pAdd=New-Object System.Collections.ArrayList; $shown=New-Object System.Collections.ArrayList
foreach($r in $resc){ $root=$r[0];$k=$r[1]
  $f=[int]$F[$root]; if($f -lt 1){$f=1}
  $band= if($nonpiv.ContainsKey($root)){'pejvo'}else{'piv'}; $brk=$BR[$band]
  $st=$stroke[$k]; $lat=EoLen $root; $E=[math]::Round($lat/$st,4); $D=$st
  $P=[math]::Round(-([math]::Log($f+1)+0.3*$E-0.1*$D),3)
  if(-not $mRoots.ContainsKey($root)){ $null=$mAdd.Add(($band+"`t"+$root+"`t"+$k)) }
  if(-not $pwHas.ContainsKey($root)){ $null=$pAdd.Add([pscustomobject]@{root=$root;k=$k;band=$band;br=$brk;F=$f;st=$st;lat=$lat;E=$E;D=$D;P=$P}) }
  $null=$shown.Add(("  {0,-11} →{1}  F={2,-3} band={3,-5} st={4,-2} E={5,-6} P={6}" -f $root,$k,$f,$band,$st,$E,$P))
}
$shown|ForEach-Object{ Write-Host $_ }
Write-Host ("master追加 {0}件 / _p_work追加 {1}件(既存はスキップ)" -f $mAdd.Count,$pAdd.Count)
if($mAdd.Count -gt 0){ Add-Content "$dir\_kanji_map_master.tsv" -Value $mAdd -Encoding UTF8 }
if($pAdd.Count -gt 0){ $existing=Import-Csv "$dir\_p_work.csv" -Encoding UTF8; $all=@($existing)+@($pAdd); $all|Export-Csv "$dir\_p_work.csv" -Encoding UTF8 -NoTypeInformation }
Write-Host "master・_p_work 追記完了"