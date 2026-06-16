$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613'
$BR=@{ 'basic'=0;'suf'=0;'pref'=0;'prep'=0;'correl'=0;'num'=0;'func'=0;'pejvo'=1;'sci'=1;'elem'=1;'cal'=1;'rel'=1;'piv'=2;'proper'=2 }
$vowels=@('a','e','i','o','u')
$sup=@{ 'a'=[char]0x1D2C;'b'=[char]0x1D2E;'c'=[char]0x1D9C;'d'=[char]0x1D30;'e'=[char]0x1D31;'f'=[char]0x1DA0;'g'=[char]0x1D33;'h'=[char]0x1D34;'i'=[char]0x1D35;'j'=[char]0x1D36;'k'=[char]0x1D37;'l'=[char]0x1D38;'m'=[char]0x1D39;'n'=[char]0x1D3A;'o'=[char]0x1D3C;'p'=[char]0x1D3E;'r'=[char]0x1D3F;'s'=[char]0x02E2;'t'=[char]0x1D40;'u'=[char]0x1D41;'v'=[char]0x2C7D;'z'=[char]0x1DBB }
$circ=[char]0x0302;$breve=[char]0x0306
function EoLetters([string]$s){ $r=New-Object System.Collections.ArrayList; for($i=0;$i -lt $s.Length;$i++){ $ch=[string]$s[$i]; if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){ $null=$r.Add($ch+'^'); $i++ } else { $null=$r.Add($ch) } }; ,$r }
function IsVowel([string]$c){ $vowels -contains $c }
function AfterHead($L){ $cons=New-Object System.Collections.ArrayList;$all=New-Object System.Collections.ArrayList; for($i=1;$i -lt $L.Count;$i++){ $c=$L[$i]; $null=$all.Add($c); if(-not(IsVowel $c)){$null=$cons.Add($c)} }; @{cons=$cons;all=$all} }
function FirstDivPos($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $o=$i+1; if(-not $seen.ContainsKey($o) -or -not $seen[$o].Contains($arr[$i])){ return @{char=$arr[$i];pos=$o} } }; return $null }
function UpdateSeen($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $o=$i+1; if(-not $seen.ContainsKey($o)){$seen[$o]=New-Object System.Collections.Generic.HashSet[string]}; [void]$seen[$o].Add($arr[$i]) } }
function ToSuper([string]$id){ if(-not $id){return ''}; $o=''; foreach($L in (EoLetters $id)){ if($L.Length -eq 2 -and $L[1] -eq '^'){ $b=[string]$L[0]; $o+=[string]$sup[$b]+$(if($b -eq 'u'){$breve}else{$circ}) } elseif($sup.ContainsKey($L)){ $o+=[string]$sup[$L] } else { $o+=$L } }; $o }
$rows=Import-Csv "$dir\_p_work.csv" -Encoding UTF8 | ForEach-Object {
  $rk=if($BR.ContainsKey($_.band)){$BR[$_.band]}else{1}
  [pscustomobject]@{ root=$_.root; k=$_.k; band=$_.band; F=[int]$_.F; P=[double]$_.P; C=($rk*1000.0+[double]$_.P); L=(EoLetters $_.root); len=(($_.root -replace '\^','').Length) } }
$targets = $args
foreach($K in $targets){
  $G=@($rows|Where-Object{$_.k -eq $K})
  if($G.Count -lt 2){ Write-Host "[$K] 共有なし"; continue }
  $a=New-Object System.Collections.ArrayList; foreach($x in $G){[void]$a.Add($x)}
  for($i=1;$i -lt $a.Count;$i++){ $key=$a[$i];$j=$i-1; while($j -ge 0){ $x=$a[$j];$pd=[math]::Abs($x.C-$key.C);$c=0; if($pd -le 1.0){ if($x.len -ne $key.len){$c=$x.len-$key.len}else{$c=[math]::Sign($x.C-$key.C)} }else{$c=[math]::Sign($x.C-$key.C)}; if($c -gt 0){$a[$j+1]=$a[$j];$j--}else{break} }; $a[$j+1]=$key }
  $headCnt=@{}; foreach($p in $a){ $h=(EoLetters $p.root)[0]; $headCnt[$h]=1+($headCnt[$h]) }
  $proc=@(); for($si=0;$si -lt $a.Count;$si++){ $L=$a[$si].L;$ah=AfterHead $L; $proc+=[pscustomobject]@{row=$a[$si];sortedIndex=$si;head=$L[0];cons=$ah.cons;all=$ah.all;id=$null;reason=$null} }
  $headOrder=New-Object System.Collections.ArrayList;$hg=@{}
  foreach($p in $proc){ if(-not $hg.ContainsKey($p.head)){$hg[$p.head]=New-Object System.Collections.ArrayList;[void]$headOrder.Add($p.head)};[void]$hg[$p.head].Add($p) }
  $used=New-Object System.Collections.Generic.HashSet[string]
  foreach($h in $headOrder){ $shr=$hg[$h]
    if($shr.Count -eq 1){ $p=$shr[0]; if($p.sortedIndex -eq 0){$p.id='';$p.reason="基本形(§3: C最小・差1.0内で最短)"}else{ $idf=$h; if($used.Contains($idf)){$sfx=2;$cd="$idf$sfx";while($used.Contains($cd)){$sfx++;$cd="$idf$sfx"};$idf=$cd;$p.reason="頭文字$h が群内唯一→頭文字のみ(衝突で数字)"}else{$p.reason="頭文字 $h が群内で唯一→頭文字のみ(§4)"}; $p.id=$idf; if($idf){[void]$used.Add($idf)} } }
    else { $seenC=@{};$seenA=@{}
      foreach($p in $shr){
        if($p.sortedIndex -eq 0){ $p.id='';$p.reason="基本形(§3: C最小・差1.0内で最短)" }
        elseif($p -eq $shr[0]){ $p.id=$h;$p.reason="頭文字 $h の初出メンバ→頭文字のみ(後続$($shr.Count-1)個は差別化)" }
        else { $cdp=FirstDivPos $p.cons $seenC
          if($cdp){ $idf="$h$($cdp.char)";$p.reason="同頭 ${h} 内: 子音列の位置$($cdp.pos)で『$($cdp.char)』が初出 → ${h}+$($cdp.char) (§5子音)" }
          else { $adp=FirstDivPos $p.all $seenA
            if($adp){ $idf="$h$($adp.char)";$p.reason="同頭 ${h} 内: 子音は全既出→全文字列の位置$($adp.pos)で『$($adp.char)』が初出 → ${h}+$($adp.char) (§5母音補完)" }
            else { $fa=if($p.all.Count){$p.all[0]}elseif($p.cons.Count){$p.cons[0]}else{''};$idf="$h$fa";$p.reason="同頭 ${h} 内: 新規文字なし→先頭文字 $fa を付与(青ao型)" } }
          if($used.Contains($idf)){ $alt=$null;foreach($cc in (@($p.cons)+@($p.all))){ if(-not $used.Contains("$h$cc")){$alt="$h$cc";break} }; if($alt){ $p.reason="$($p.reason) ※$idf 衝突→§6a別文字 $alt";$idf=$alt }else{ $p.reason="$($p.reason) ※衝突→数字";$idf="${idf}2" } }
          $p.id=$idf }
        if($p.id){[void]$used.Add($p.id)}; UpdateSeen $p.cons $seenC; UpdateSeen $p.all $seenA } }
  }
  Write-Host ("===== 群【$K】 全$($a.Count)件 (処理順) =====")
  foreach($p in $proc){ $disp=$p.row.k+(ToSuper $p.id); $cl=($p.cons -join ',') ; "  {0,2}. {1,-12} {2,-7} F={3,-4} {4,-6} 子音列[{5}]  | {6}" -f ($p.sortedIndex+1),$p.row.root,$disp,$p.row.F,$p.row.band,$cl,$p.reason }
  Write-Host ""
}
