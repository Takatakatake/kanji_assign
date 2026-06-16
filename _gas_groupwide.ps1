$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613'
# 仕様§5テキスト版: seen を「グループ全体」で蓄積(GAS最終完全版は頭文字グループ内)。head-only/§6aは同じ。
$BR=@{ 'basic'=0;'suf'=0;'pref'=0;'prep'=0;'correl'=0;'num'=0;'func'=0;'pejvo'=1;'sci'=1;'elem'=1;'cal'=1;'rel'=1;'piv'=2;'proper'=2 }
$vowels=@('a','e','i','o','u')
function EoLetters([string]$s){ $r=New-Object System.Collections.ArrayList; for($i=0;$i -lt $s.Length;$i++){ $ch=[string]$s[$i]; if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){ $null=$r.Add($ch+'^'); $i++ } else { $null=$r.Add($ch) } }; ,$r }
function IsVowel([string]$c){ $vowels -contains $c }
function AfterHead($L){ $cons=New-Object System.Collections.ArrayList; $all=New-Object System.Collections.ArrayList; for($i=1;$i -lt $L.Count;$i++){ $c=$L[$i]; $null=$all.Add($c); if(-not (IsVowel $c)){ $null=$cons.Add($c) } }; @{cons=$cons; all=$all} }
function FirstDivergent($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $ord=$i+1; $ch=$arr[$i]; if(-not $seen.ContainsKey($ord) -or -not $seen[$ord].Contains($ch)){ return $ch } }; return $null }
function UpdateSeen($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $ord=$i+1; $ch=$arr[$i]; if(-not $seen.ContainsKey($ord)){ $seen[$ord]=New-Object System.Collections.Generic.HashSet[string] }; [void]$seen[$ord].Add($ch) } }
$rows=Import-Csv "$dir\_p_work.csv" -Encoding UTF8 | ForEach-Object {
  $rk=if($BR.ContainsKey($_.band)){$BR[$_.band]}else{1}
  [pscustomobject]@{ root=$_.root; k=$_.k; band=$_.band; F=[int]$_.F; P=[double]$_.P; C=($rk*1000.0 + [double]$_.P); L=(EoLetters $_.root); len=(($_.root -replace '\^','').Length) }
}
$out=New-Object System.Collections.ArrayList
foreach($grp in ($rows | Group-Object k)){
  $G=@($grp.Group)
  if($G.Count -eq 1){ $null=$out.Add([pscustomobject]@{root=$G[0].root;k=$G[0].k;id='';band=$G[0].band;F=$G[0].F}); continue }
  $a=New-Object System.Collections.ArrayList; foreach($x in $G){ [void]$a.Add($x) }
  for($i=1;$i -lt $a.Count;$i++){ $key=$a[$i]; $j=$i-1
    while($j -ge 0){ $x=$a[$j]; $pd=[math]::Abs($x.C-$key.C); $c=0
      if($pd -le 1.0){ if($x.len -ne $key.len){ $c=$x.len-$key.len } else { $c=[math]::Sign($x.C-$key.C) } } else { $c=[math]::Sign($x.C-$key.C) }
      if($c -gt 0){ $a[$j+1]=$a[$j]; $j-- } else { break } }
    $a[$j+1]=$key }
  $seenC=@{}; $seenA=@{}; $used=New-Object System.Collections.Generic.HashSet[string]; $assignedHeads=New-Object System.Collections.Generic.HashSet[string]
  for($si=0;$si -lt $a.Count;$si++){ $L=$a[$si].L; $ah=AfterHead $L; $h=$L[0]; $idf=''
    if($si -eq 0){ $idf=''; [void]$assignedHeads.Add($h) }
    elseif(-not $assignedHeads.Contains($h)){ $idf=$h; [void]$assignedHeads.Add($h) }
    else { $cd=FirstDivergent $ah.cons $seenC
      if($cd){ $idf="$h$cd" } else { $ad=FirstDivergent $ah.all $seenA
        if($ad){ $idf="$h$ad" } else { $fa=if($ah.all.Count -gt 0){$ah.all[0]}elseif($ah.cons.Count -gt 0){$ah.cons[0]}else{''}; $idf="$h$fa" } }
      if($used.Contains($idf)){ $alt=$null; foreach($cc in (@($ah.cons)+@($ah.all))){ if(-not $used.Contains("$h$cc")){ $alt="$h$cc"; break } }; if($alt){$idf=$alt}else{ $sfx=2;$cand="$idf$sfx";while($used.Contains($cand)){$sfx++;$cand="$idf$sfx"};$idf=$cand } } }
    if($idf){[void]$used.Add($idf)}; UpdateSeen $ah.cons $seenC; UpdateSeen $ah.all $seenA
    $null=$out.Add([pscustomobject]@{root=$a[$si].root;k=$a[$si].k;id=$idf;band=$a[$si].band;F=$a[$si].F}) }
}
$out | Export-Csv "$dir\_gas_groupwide_out.csv" -Encoding UTF8 -NoTypeInformation
$dup=0; $out|Group-Object k|ForEach-Object{ ($_.Group|Group-Object id|Where-Object{$_.Count -gt 1 -and $_.Name -ne ''})|ForEach-Object{$dup++} }
Write-Host ("group-wide版 {0}行 / id重複 {1} / 数字id {2}" -f $out.Count,$dup,@($out|Where-Object{$_.id -match '\d'}).Count)
