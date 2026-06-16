$ErrorActionPreference='Stop'
$vowels=@('a','e','i','o','u')
function EoLetters([string]$s){ $r=New-Object System.Collections.ArrayList; for($i=0;$i -lt $s.Length;$i++){ $ch=[string]$s[$i]; if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){ $null=$r.Add($ch+'^'); $i++ } else { $null=$r.Add($ch) } }; ,$r }
function IsVowel([string]$c){ $vowels -contains $c }
function AfterHead($L){ $cons=New-Object System.Collections.ArrayList; $all=New-Object System.Collections.ArrayList; for($i=1;$i -lt $L.Count;$i++){ $c=$L[$i]; $null=$all.Add($c); if(-not (IsVowel $c)){ $null=$cons.Add($c) } }; @{cons=$cons; all=$all} }
function FirstDivergent($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $ord=$i+1; $ch=$arr[$i]; if(-not $seen.ContainsKey($ord) -or -not $seen[$ord].Contains($ch)){ return $ch } }; return $null }
function UpdateSeen($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $ord=$i+1; $ch=$arr[$i]; if(-not $seen.ContainsKey($ord)){ $seen[$ord]=New-Object System.Collections.Generic.HashSet[string] }; [void]$seen[$ord].Add($ch) } }
function ProcessGroupA($items){
  $proc=@(); for($si=0;$si -lt $items.Count;$si++){ $L=EoLetters $items[$si].root; $ah=AfterHead $L; $proc+=[pscustomobject]@{root=$items[$si].root;sortedIndex=$si;head=$L[0];cons=$ah.cons;all=$ah.all;id=$null} }
  $headOrder=New-Object System.Collections.ArrayList; $hg=@{}
  foreach($p in $proc){ if(-not $hg.ContainsKey($p.head)){ $hg[$p.head]=New-Object System.Collections.ArrayList; [void]$headOrder.Add($p.head) }; [void]$hg[$p.head].Add($p) }
  $used=New-Object System.Collections.Generic.HashSet[string]
  foreach($h in $headOrder){ $shr=$hg[$h]
    if($shr.Count -eq 1){ $p=$shr[0]; $idf=if($p.sortedIndex -eq 0){''}else{$h}; if($idf -and $used.Contains($idf)){$sfx=2;$c="$idf$sfx";while($used.Contains($c)){$sfx++;$c="$idf$sfx"};$idf=$c}; $p.id=$idf; if($idf){[void]$used.Add($idf)} }
    else { $seenC=@{}; $seenA=@{}
      foreach($p in $shr){ $idf=''
        if($p.sortedIndex -eq 0){ $idf='' }
        elseif($p -eq $shr[0]){ $idf=$h }
        else { $cd=FirstDivergent $p.cons $seenC
          if($cd){ $idf="$h$cd" } else { $ad=FirstDivergent $p.all $seenA; if($ad){ $idf="$h$ad" } else { $fa=if($p.all.Count -gt 0){$p.all[0]}elseif($p.cons.Count -gt 0){$p.cons[0]}else{''}; $idf="$h$fa" } }
          if($used.Contains($idf)){$sfx=2;$c="$idf$sfx";while($used.Contains($c)){$sfx++;$c="$idf$sfx"};$idf=$c} }
        $p.id=$idf; if($idf){[void]$used.Add($idf)}; UpdateSeen $p.cons $seenC; UpdateSeen $p.all $seenA } }
  }
  return $proc
}
function RunTest($name,$roots,$expect){
  $items=@(); foreach($r in $roots){ $items+=[pscustomobject]@{root=$r} }
  $res=ProcessGroupA $items
  Write-Host "[$name]"
  $ok=$true
  for($i=0;$i -lt $res.Count;$i++){ $got=$res[$i].id; $exp=$expect[$i]; $mark=if($got -eq $exp){'OK'}else{$ok=$false;'NG'}; "  {0,-10} got='{1,-4}' expect='{2,-4}' {3}" -f $res[$i].root,$got,$exp,$mark }
  Write-Host ("  => " + $(if($ok){'ALL MATCH'}else{'MISMATCH'})); Write-Host ""
}
RunTest 'kaku-grp' @('kaku','kaki','kakimono','kakite','sho','kakeru') @('','ki','km','kt','s','kr')
RunTest 'michi-grp' @('strato','strando','strio','strupo','strebo')    @('','sn','si','sp','sb')
RunTest 'ao-grp'   @('aoi','ai','ao')                                   @('','ai','ao')
RunTest 'mix-grp'  @('floro','uz','ali','flamo')                        @('','u','a','fm')
