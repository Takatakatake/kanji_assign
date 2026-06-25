# 台帳の各homonymについて、第2義漢字の群に語根を加えた時の disp(漢字+識別子)を計算 → _homonym_disp.tsv
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$sc=Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t"
$vowels='a','e','i','o','u'
$sup=@{ 'a'=[char]0x1D2C;'b'=[char]0x1D2E;'c'=[char]0x1D9C;'d'=[char]0x1D30;'e'=[char]0x1D31;'f'=[char]0x1DA0;'g'=[char]0x1D33;'h'=[char]0x1D34;'i'=[char]0x1D35;'j'=[char]0x1D36;'k'=[char]0x1D37;'l'=[char]0x1D38;'m'=[char]0x1D39;'n'=[char]0x1D3A;'o'=[char]0x1D3C;'p'=[char]0x1D3E;'r'=[char]0x1D3F;'s'=[char]0x02E2;'t'=[char]0x1D40;'u'=[char]0x1D41;'v'=[char]0x2C7D;'z'=[char]0x1DBB }
$circ=[char]0x0302;$breve=[char]0x0306;$uni=@{ ([char]0x0109)='c';([char]0x011D)='g';([char]0x0125)='h';([char]0x0135)='j';([char]0x015D)='s';([char]0x016D)='u' }
function ToHsys([string]$s){ $s -replace 'ĉ','c^' -replace 'ĝ','g^' -replace 'ĥ','h^' -replace 'ĵ','j^' -replace 'ŝ','s^' -replace 'ŭ','u^' }
function EoLetters([string]$s){ $r=New-Object System.Collections.ArrayList; for($i=0;$i -lt $s.Length;$i++){ $ch=[string]$s[$i]; if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){ $null=$r.Add($ch+'^'); $i++ } else { $null=$r.Add($ch) } }; ,$r }
function IsVowel([string]$c){ $vowels -contains $c }
function AfterHead($L){ $cons=New-Object System.Collections.ArrayList;$all=New-Object System.Collections.ArrayList; for($i=1;$i -lt $L.Count;$i++){ $c=$L[$i]; $null=$all.Add($c); if(-not(IsVowel $c)){$null=$cons.Add($c)} }; @{cons=$cons;all=$all} }
function FirstDiv($arr,$seen){ for($i=0;$i -lt $arr.Count;$i++){ $o=$i+1; if(-not $seen.ContainsKey($o) -or -not $seen[$o].Contains($arr[$i])){ return $arr[$i] } }; return $null }
function ToSuper([string]$id){ if(-not $id){return ''}; $o=''; foreach($L in (EoLetters $id)){ if($L.Length -eq 2 -and $L[1] -eq '^'){ $b=[string]$L[0]; $o+=[string]$sup[$b]+$(if($b -eq 'u'){$breve}else{$circ}) } elseif($uni.ContainsKey([char]$L)){ $b=$uni[[char]$L]; $o+=[string]$sup[$b]+$(if($b -eq 'u'){$breve}else{$circ}) } elseif($sup.ContainsKey($L)){ $o+=[string]$sup[$L] } else { $o+=$L } }; $o }
# 既存群Kにセグメントseg(homonym第2義)を加えた時のid(GAS/§5 per-head 位置ベース+§6a別文字)
function AddSegId([string]$K,[string]$seg){
  $mem=@($sc|Where-Object{$_.groupkey -eq $K})
  if($mem.Count -eq 0){ return '' }                                  # その漢字が未使用→単独でbase(無印)
  foreach($m in $mem){ if((-not $m.id) -and ((ToHsys $m.root) -eq (ToHsys $seg))){ return '' } }   # seg が群Kの基本形そのもの(metr=米等)→無印。sep override が自己衝突でidを付けるのを防ぐ(2026-06-21)
  $used=New-Object System.Collections.Generic.HashSet[string]
  foreach($m in $mem){ if($m.id){[void]$used.Add($m.id)}; $ml=EoLetters $m.root; if(-not $m.id){ [void]$used.Add([string]$ml[0]) } }
  $L=EoLetters $seg; $h=$L[0]; $ah=AfterHead $L
  if(-not $used.Contains($h)){ return $h }
  $seenC=@{};$seenA=@{}
  foreach($m in $mem){ $ml=EoLetters $m.root; if($ml[0] -eq $h){ $mah=AfterHead $ml; for($i=0;$i -lt $mah.cons.Count;$i++){ $o=$i+1; if(-not $seenC.ContainsKey($o)){$seenC[$o]=New-Object System.Collections.Generic.HashSet[string]}; [void]$seenC[$o].Add($mah.cons[$i]) }; for($i=0;$i -lt $mah.all.Count;$i++){ $o=$i+1; if(-not $seenA.ContainsKey($o)){$seenA[$o]=New-Object System.Collections.Generic.HashSet[string]}; [void]$seenA[$o].Add($mah.all[$i]) } } }
  $cd=FirstDiv $ah.cons $seenC; $idf=if($cd){"$h$cd"}else{ $ad=FirstDiv $ah.all $seenA; if($ad){"$h$ad"}else{ $fa=if($ah.all.Count){$ah.all[0]}elseif($ah.cons.Count){$ah.cons[0]}else{''}; "$h$fa" } }
  if($used.Contains($idf)){ $alt=$null; foreach($cc in (@($ah.cons)+@($ah.all))){ if(-not $used.Contains("$h$cc")){$alt="$h$cc";break} }
    if($alt){$idf=$alt}
    else{ $cand=$h; for($z=0;$z -lt $ah.all.Count;$z++){ $cand=$cand+[string]$ah.all[$z]; if(-not $used.Contains($cand)){ break } }   # 2文字id枯渇(草メガ群等)→頭+語根後続文字の漸進プレフィックスで一意化(数字回避。_gas_identifierと同型・2026-06-26)
      if($used.Contains($cand)){ $sfx=2; $c2="$cand$sfx"; while($used.Contains($c2)){$sfx++;$c2="$cand$sfx"}; $cand=$c2 }
      $idf=$cand } }
  return $idf
}
$out=New-Object System.Collections.ArrayList; [void]$out.Add("segment`ttype`tdisc`toverrideKanji`toverrideDisp`tnote")
Get-Content "$dir\_homonym.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
  $p=$_ -split "`t"; if($p.Count -lt 5){return}
  $seg=$p[0];$ov=$p[1];$type=$p[2];$disc=$p[3];$note=$p[4]
  $id=AddSegId $ov $seg; $d=$ov+(ToSuper $id)
  [void]$out.Add(($seg+"`t"+$type+"`t"+$disc+"`t"+$ov+"`t"+$d+"`t"+$note))
}
[System.IO.File]::WriteAllLines("$dir\_homonym_disp.tsv",$out,(New-Object System.Text.UTF8Encoding($false)))
Write-Host ("homonym disp計算: {0}件" -f ($out.Count-1))
$out|Select-Object -Skip 1|Select-Object -First 18|ForEach-Object{ $p=$_ -split "`t"; "  {0,-8} {1,-4} {2,-6} (第2義disp)" -f $p[0],$p[1],$p[4] }