# 現在の漢字使用頻度を集計(base字ごとに、その字を主割当に使う「異なり語根」数)。
# サイドカー disp の base字(識別子上付き・ラテン除く CJK)で集計。homonym sep/comb の第2義字も加算。
# 出力 _rare_kanji_now.tsv: char<TAB>nRoots<TAB>roots(代表) / _rare_kanji_now_summary.txt
$ErrorActionPreference='Stop'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
function BaseChars([string]$s){ $o=''; foreach($ch in $s.ToCharArray()){ $c=[int][char]$ch; if(($c -ge 0x4E00 -and $c -le 0x9FFF) -or ($c -ge 0x3400 -and $c -le 0x4DBF)){ $o+=[string]$ch } }; $o }
# gloss(語義)を注入から採取(代表): root→短gloss
$gloss=@{}
foreach($ln in [System.IO.File]::ReadAllLines("$dir\漢字注入_学習者版_20260620.txt")){
  $ci=$ln.IndexOf(':'); if($ci -lt 1){continue}; $head=$ln.Substring(0,$ci)
  $m=[regex]::Match($head,'^([a-z][a-z0-9^]*)/(o|i|a|e|as|is|on)⟦'); if(-not $m.Success){continue}
  $r=$m.Groups[1].Value; if($gloss.ContainsKey($r)){continue}
  $g=$ln.Substring($ci+1) -replace '##.*$',''; $g=$g.Substring(0,[Math]::Min(34,$g.Length)); $gloss[$r]=$g }
# char → roots(集合)。サイドカー base字
$charRoots=@{}
Import-Csv "$dir\_identifier_sidecar.tsv" -Encoding UTF8 -Delimiter "`t" | ForEach-Object {
  $root=$_.root; $bc=BaseChars $_.disp
  foreach($ch in $bc.ToCharArray()){ $ch=[string]$ch; if(-not $charRoots.ContainsKey($ch)){$charRoots[$ch]=New-Object System.Collections.Generic.HashSet[string]}; [void]$charRoots[$ch].Add($root) } }
# homonym sep/comb の第2義字も(語単位だが、その字を使う語根として root を加える)
if(Test-Path "$dir\_homonym_disp.tsv"){
  Get-Content "$dir\_homonym_disp.tsv" -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object {
    $p=$_ -split "`t"; if($p.Count -lt 5){return}; $seg=$p[0]; $d=$p[4]; $bc=BaseChars $d
    foreach($ch in $bc.ToCharArray()){ $ch=[string]$ch; if(-not $charRoots.ContainsKey($ch)){$charRoots[$ch]=New-Object System.Collections.Generic.HashSet[string]}; [void]$charRoots[$ch].Add('sep:'+$seg) } } }
# 集計
$rows=New-Object System.Collections.ArrayList; [void]$rows.Add("char`tnRoots`troots_with_gloss")
$dist=@{1=0;2=0}; $tot=0; $rare=New-Object System.Collections.ArrayList
foreach($ch in ($charRoots.Keys | Sort-Object { $charRoots[$_].Count })){
  $n=$charRoots[$ch].Count; $tot++
  if($n -le 2){
    if($dist.ContainsKey($n)){$dist[$n]++}
    $rs=@($charRoots[$ch]) | Sort-Object
    $rg=($rs | ForEach-Object { $g=if($gloss.ContainsKey($_)){$gloss[$_]}else{''}; "$_($g)" }) -join ' | '
    [void]$rows.Add("$ch`t$n`t$rg")
    [void]$rare.Add("$ch`t$n`t$rg")
  }
}
[System.IO.File]::WriteAllLines("$dir\_rare_kanji_now.tsv",$rows,(New-Object System.Text.UTF8Encoding($false)))
Write-Host ("異なり漢字 計{0} / 1語根={1} / 2語根={2} / 計稀少(<=2)={3}" -f $tot,$dist[1],$dist[2],($dist[1]+$dist[2]))
Write-Host "→ _rare_kanji_now.tsv"
