# _gas_identifier_out.csv → _identifier_sidecar.tsv(id_super/disp) + レビュー再生成
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\PEJVO・PIV語根分解資料_20260613'
$work=Import-Csv "$dir\_gas_identifier_out.csv" -Encoding UTF8
$sup=@{ 'a'=[char]0x1D2C;'b'=[char]0x1D2E;'c'=[char]0x1D9C;'d'=[char]0x1D30;'e'=[char]0x1D31;'f'=[char]0x1DA0;'g'=[char]0x1D33;'h'=[char]0x1D34;'i'=[char]0x1D35;'j'=[char]0x1D36;'k'=[char]0x1D37;'l'=[char]0x1D38;'m'=[char]0x1D39;'n'=[char]0x1D3A;'o'=[char]0x1D3C;'p'=[char]0x1D3E;'r'=[char]0x1D3F;'s'=[char]0x02E2;'t'=[char]0x1D40;'u'=[char]0x1D41;'v'=[char]0x2C7D;'z'=[char]0x1DBB }
$circ=[char]0x0302; $breve=[char]0x0306
$uni=@{ ([char]0x0109)='c';([char]0x011D)='g';([char]0x0125)='h';([char]0x0135)='j';([char]0x015D)='s';([char]0x016D)='u' }
function EoLetters([string]$s){ $r=New-Object System.Collections.ArrayList; for($i=0;$i -lt $s.Length;$i++){ $ch=[string]$s[$i]; if($i+1 -lt $s.Length -and $s[$i+1] -eq '^'){ $null=$r.Add($ch+'^'); $i++ } else { $null=$r.Add($ch) } }; ,$r }
function ToSuper([string]$id){ if(-not $id){return ''}; $o=''
  foreach($L in (EoLetters $id)){
    if($L.Length -eq 2 -and $L[1] -eq '^'){ $b=[string]$L[0]; if($sup.ContainsKey($b)){ $o+=[string]$sup[$b]+$(if($b -eq 'u'){$breve}else{$circ}) } }
    elseif($uni.ContainsKey([char]$L)){ $b=$uni[[char]$L]; $o+=[string]$sup[$b]+$(if($b -eq 'u'){$breve}else{$circ}) }
    elseif($sup.ContainsKey($L)){ $o+=[string]$sup[$L] }
    else { $o+=$L } }
  $o }
$ov=@{}; Get-Content "$dir\_gloss_override.tsv" -Encoding UTF8|ForEach-Object{ $p=$_ -split "`t"; if($p.Count -ge 2){$ov[$p[0].Trim()]=$p[1].Trim()} }
$final=$work|ForEach-Object{ [pscustomobject]@{ root=$_.root;kanji=$_.k;id=$_.id;id_super=(ToSuper $_.id);disp=($_.k+(ToSuper $_.id));band=$_.band;F=$_.F;groupkey=$_.k } }
$final|Export-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -NoTypeInformation -Delimiter "`t"
$BR=@{ 'basic'=0;'suf'=0;'pref'=0;'prep'=0;'correl'=0;'num'=0;'func'=0;'pejvo'=1;'sci'=1;'elem'=1;'cal'=1;'rel'=1;'piv'=2;'proper'=2 }
$sb=New-Object System.Text.StringBuilder; [void]$sb.AppendLine("# 識別子レビュー(GAS/§5位置・§3厳密・§6a別文字・特殊字修正・base上書き版): 全共有群・全メンバー・語義付き"); [void]$sb.AppendLine("")
foreach($g in ($final|Group-Object groupkey|Where-Object{$_.Count -ge 2}|Sort-Object @{e={$_.Count};desc=$true},Name)){ [void]$sb.AppendLine("【"+$g.Name+"】 "+$g.Count+"件"); $base=$g.Group|Where-Object{-not $_.id}; $rest=$g.Group|Where-Object{$_.id}|Sort-Object @{e={[int]$BR[$_.band]}},@{e={[int]$_.F};desc=$true},@{e={$_.id}}; foreach($r in (@($base)+@($rest))){ $gl=if($ov.ContainsKey($r.root)){$ov[$r.root]}else{''}; if($gl.Length -gt 30){$gl=$gl.Substring(0,30)}; [void]$sb.AppendLine(("  {0,-14} {1,-10} F={2,-5} {3,-7} {4}" -f $r.root,$r.disp,$r.F,$r.band,$gl)) }; [void]$sb.AppendLine("") }
[System.IO.File]::WriteAllText("$dir\識別子レビュー_全共有群_20260616.txt",$sb.ToString(),(New-Object System.Text.UTF8Encoding($true)))
$dup=0; $final|Group-Object groupkey|ForEach-Object{ ($_.Group|Group-Object id|Where-Object{$_.Count -gt 1 -and $_.Name -ne ''})|ForEach-Object{$dup++} }
$num=@($final|Where-Object{$_.id -match '\d'}).Count
$bad=@($final|Where-Object{ $_.id_super -match '[ĉĝĥĵŝŭ]' }).Count
Write-Host ("サイドカー {0}行 / id重複 {1} / 数字id {2} / 特殊字未変換 {3}" -f $final.Count,$dup,$num,$bad)
