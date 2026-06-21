$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
# GAS「識別子付与・最終完全版」忠実移植。C(優先順位)=band_rank*1000+P(層を優先、層内はP)。閾値1.0で文字数優先。
$BR=@{ 'basic'=0;'suf'=0;'pref'=0;'prep'=0;'correl'=0;'num'=0;'func'=0;'pejvo'=1;'sci'=1;'elem'=1;'cal'=1;'rel'=1;'piv'=2;'proper'=2 }
$vowels=@('a','e','i','o','u')
function EoLetters([string]$s){ $r=New-Object System.Collections.ArrayList; for($i=0;$i -lt $s.Length;$i++){ $ch=[string]$s[$i]; if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){ $null=$r.Add($ch+'^'); $i++ } else { $null=$r.Add($ch) } }; ,$r }
function IsVowel([string]$c){ $vowels -contains $c }   # ĉ/c^/ŭ 等は子音
# extractAfterHead: 頭文字(=index0)以降の 子音列 と 全文字列
function AfterHead($L){ $cons=New-Object System.Collections.ArrayList; $all=New-Object System.Collections.ArrayList; for($i=1;$i -lt $L.Count;$i++){ $c=$L[$i]; $null=$all.Add($c); if(-not (IsVowel $c)){ $null=$cons.Add($c) } }; @{cons=$cons; all=$all} }
# findFirstDivergent: 位置(1始まり)ごとに、その位置で未出の文字を返す
function FirstDivergent($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $ord=$i+1; $ch=$arr[$i]; if(-not $seen.ContainsKey($ord) -or -not $seen[$ord].Contains($ch)){ return $ch } }; return $null }
function UpdateSeen($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $ord=$i+1; $ch=$arr[$i]; if(-not $seen.ContainsKey($ord)){ $seen[$ord]=New-Object System.Collections.Generic.HashSet[string] }; [void]$seen[$ord].Add($ch) } }

function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
# 識別子計算用に根をUnicodeへ正規化(h-system h^ と Unicode ĥ を同一字として扱い、上付き化後の id重複を防ぐ。2026-06-20)
function ToUni([string]$s){ $s -replace 'c\^','ĉ' -replace 'C\^','Ĉ' -replace 'g\^','ĝ' -replace 'G\^','Ĝ' -replace 'h\^','ĥ' -replace 'H\^','Ĥ' -replace 'j\^','ĵ' -replace 'J\^','Ĵ' -replace 's\^','ŝ' -replace 'S\^','Ŝ' -replace 'u\^','ŭ' -replace 'U\^','Ŭ' }
$ovBase=@{}; if(Test-Path "$dir\_base_override.tsv"){ Get-Content "$dir\_base_override.tsv" -Encoding UTF8 | ForEach-Object { if($_ -match '^\s*#' -or -not $_.Trim()){ return }; $p=$_ -split "`t"; if($p.Count -ge 2 -and $p[0].Trim()){ $ovBase[$p[0].Trim()]=$p[1].Trim() } } }
$rows=Import-Csv "$dir\_p_work.csv" -Encoding UTF8 | ForEach-Object {
  $rk=if($BR.ContainsKey($_.band)){$BR[$_.band]}else{1}
  [pscustomobject]@{ root=$_.root; k=$_.k; band=$_.band; F=[int]$_.F; P=[double]$_.P; C=($rk*1000.0 + [double]$_.P); L=(EoLetters (ToUni $_.root)); len=(($_.root -replace '\^','').Length) }
}
$out=New-Object System.Collections.ArrayList
foreach($grp in ($rows | Group-Object k)){
  $G=@($grp.Group)
  if($G.Count -eq 1){ $null=$out.Add([pscustomobject]@{root=$G[0].root;k=$G[0].k;id='';band=$G[0].band;F=$G[0].F}); continue }
  # --- 安定挿入ソート(GAS比較器: pd<=1.0なら文字数, それ以外C) ---
  $a=New-Object System.Collections.ArrayList; foreach($x in $G){ [void]$a.Add($x) }
  for($i=1;$i -lt $a.Count;$i++){ $key=$a[$i]; $j=$i-1
    while($j -ge 0){ $x=$a[$j]; $pd=[math]::Abs($x.C-$key.C); $c=0
      if($pd -le 1.0){ if($x.len -ne $key.len){ $c=$x.len-$key.len } else { $c=[math]::Sign($x.C-$key.C) } } else { $c=[math]::Sign($x.C-$key.C) }
      if($c -gt 0){ $a[$j+1]=$a[$j]; $j-- } else { break } }
    $a[$j+1]=$key }
  # --- base上書き(_base_override.tsv): 指定語根を先頭(基本形)へ ---
  if($ovBase.ContainsKey($grp.Name)){ $ovr=$ovBase[$grp.Name]; $ovrH=ToHsys $ovr; $idx=-1
    for($t=0;$t -lt $a.Count;$t++){ $rt=$a[$t].root; if($rt -eq $ovr -or (ToHsys $rt) -eq $ovrH){ $idx=$t; break } }
    if($idx -ge 0){ $item=$a[$idx]; $a.RemoveAt($idx); $a.Insert(0,$item) } else { Write-Host ("  [override未適用] 群"+$grp.Name+" に語根 "+$ovr+" 無し") } }
  # --- processedRows: head/cons/all、sortedIndex ---
  $proc=@(); for($si=0;$si -lt $a.Count;$si++){ $L=$a[$si].L; $ah=AfterHead $L; $proc += [pscustomobject]@{ row=$a[$si]; sortedIndex=$si; head=$L[0]; cons=$ah.cons; all=$ah.all; id=$null } }
  # --- 頭文字でグループ化(出現順保持) ---
  $headOrder=New-Object System.Collections.ArrayList; $headGroups=@{}
  foreach($p in $proc){ if(-not $headGroups.ContainsKey($p.head)){ $headGroups[$p.head]=New-Object System.Collections.ArrayList; [void]$headOrder.Add($p.head) }; [void]$headGroups[$p.head].Add($p) }
  $used=New-Object System.Collections.Generic.HashSet[string]
  foreach($h in $headOrder){ $shr=$headGroups[$h]
    if($shr.Count -eq 1){ $p=$shr[0]; $idf=if($p.sortedIndex -eq 0){''}else{$h}
      if($idf -and $used.Contains($idf)){ $sfx=2; $cand="$idf$sfx"; while($used.Contains($cand)){$sfx++;$cand="$idf$sfx"}; $idf=$cand }
      $p.id=$idf; if($idf){[void]$used.Add($idf)} }
    else { $seenC=@{}; $seenA=@{}
      foreach($p in $shr){ $idf=''
        if($p.sortedIndex -eq 0){ $idf='' }
        elseif($p -eq $shr[0]){ $idf=$h }
        else { $cd=FirstDivergent $p.cons $seenC
          if($cd){ $idf="$h$cd" } else { $ad=FirstDivergent $p.all $seenA
            if($ad){ $idf="$h$ad" } else { $fa=if($p.all.Count -gt 0){$p.all[0]}elseif($p.cons.Count -gt 0){$p.cons[0]}else{''}; $idf="$h$fa" } }   # 頭文字共有→必ず付す(青 ao→ao)
          if($used.Contains($idf)){   # §6a: 衝突→数字でなく別文字(子音列→全文字列で最初の未使用)
            $alt=$null; foreach($cc in (@($p.cons)+@($p.all))){ if(-not $used.Contains("$h$cc")){ $alt="$h$cc"; break } }
            if($alt){ $idf=$alt } else { $sfx=2; $cand="$idf$sfx"; while($used.Contains($cand)){$sfx++;$cand="$idf$sfx"}; $idf=$cand } } }
        $p.id=$idf; if($idf){[void]$used.Add($idf)}
        UpdateSeen $p.cons $seenC; UpdateSeen $p.all $seenA } }
  }
  foreach($p in $proc){ $null=$out.Add([pscustomobject]@{root=$p.row.root;k=$p.row.k;id=$p.id;band=$p.row.band;F=$p.row.F}) }
}
$out | Export-Csv "$dir\_gas_identifier_out.csv" -Encoding UTF8 -NoTypeInformation
$dup=0; $out|Group-Object k|ForEach-Object{ ($_.Group|Group-Object id|Where-Object{$_.Count -gt 1 -and $_.Name -ne ''})|ForEach-Object{$dup++} }
$num=@($out|Where-Object{$_.id -match '\d'}).Count
Write-Host ("GAS移植 {0}行 / id重複 {1} / 数字id {2}" -f $out.Count,$dup,$num)
