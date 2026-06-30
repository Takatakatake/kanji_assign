# 希少漢字センサス: 注入で「使用されている基底漢字」が distinct な語根いくつに使われているかを悉皆集計。
# 1-2 語根しか担っていない字を炙り出し、各々が「専用evocative字(保持)」か「孤立orphan(統合候補)」かを人手判定する材料を出す。
# 単位 = distinct (語根セグメント → 基底漢字) ペア。上付き識別子は除去して基底字に正規化。
# 既定で学術版(PIV正式語根境界=morpheme が綺麗)を集計。引数 'gakushu' で学習者版。
param([string]$ver='gakushu')
$ErrorActionPreference='Continue'
$dir=$PSScriptRoot
if($ver -eq 'gakujutsu'){ $f=Join-Path $dir '漢字注入_学術版_20260620.txt'; $label='学術' }
else { $f=Join-Path $dir '漢字注入_学習者版_20260620.txt'; $label='学習者' }

$L1=[char]0x27E6; $R1=[char]0x27E7
# 文法語尾(latin残存が正常 → カウント対象外。なお漢字が当たらないので元々入らないが念のため)
$endings=@{}; foreach($e in @('o','a','e','i','u','j','n','oj','aj','ej','on','an','en','ojn','ajn','as','is','os','us','int','ant','ont','it','at','ot','um','ig','igx','ad','ek','er','estr')){ $endings[$e]=$true }
$capRe=[regex]('^[A-Z'+[char]0x108+[char]0x11C+[char]0x124+[char]0x134+[char]0x15C+[char]0x16C+']')

function BaseKanji([string]$s){
  $sb=New-Object System.Text.StringBuilder
  foreach($ch in $s.ToCharArray()){
    $code=[int][char]$ch
    if($code -ge 0x4E00 -and $code -le 0x9FFF){ [void]$sb.Append($ch) }
  }
  return $sb.ToString()
}

$pairs=@{}   # "root`tbase" -> $true  (distinct ペア)
$c=Get-Content -LiteralPath $f -Encoding UTF8
foreach($line in $c){
  $ci=$line.IndexOf($L1); if($ci -lt 0){ continue }
  $cj=$line.IndexOf($R1,$ci); if($cj -lt 0){ continue }
  $head=$line.Substring(0,$ci); $kanjiPart=$line.Substring($ci+1,$cj-$ci-1)
  if($capRe.IsMatch($head)){ continue }   # 固有名skip
  $hs=@($head -split '[/-]'); $ks=@($kanjiPart -split '[/-]')
  if($hs.Count -ne $ks.Count){ continue }
  for($i=0;$i -lt $hs.Count;$i++){
    $hseg=[string]$hs[$i]; $kseg=[string]$ks[$i]
    if($hseg -match '\s'){ continue }
    if($endings.ContainsKey($hseg)){ continue }
    $base=BaseKanji $kseg
    if($base -eq ''){ continue }
    $pairs[$hseg+"`t"+$base]=$true
  }
}

# 基底字 -> distinct 語根集合
$byKanji=@{}
foreach($k in $pairs.Keys){
  $parts=$k -split "`t",2; $root=$parts[0]; $base=$parts[1]
  if(-not $byKanji.ContainsKey($base)){ $byKanji[$base]=New-Object System.Collections.Generic.HashSet[string] }
  [void]$byKanji[$base].Add($root)
}

$total=$byKanji.Count
$c1=0;$c2=0
foreach($b in $byKanji.Keys){ $n=$byKanji[$b].Count; if($n -eq 1){$c1++} elseif($n -eq 2){$c2++} }
Write-Host ("=== ["+$label+"版] 基底漢字センサス: 異なり基底字="+$total+" / 1語根のみ="+$c1+" / 2語根="+$c2+" ===")

# 出力ファイル(TSV)
$out=Join-Path $dir ('_census_rare_'+$label+'.tsv')
$rows=@()
$rows += "count`tkanji`troots"
foreach($b in ($byKanji.Keys | Sort-Object { $byKanji[$_].Count }, { $_ })){
  $n=$byKanji[$b].Count
  if($n -le 2){
    $rs=(@($byKanji[$b]) | Sort-Object) -join ','
    $rows += ($n.ToString()+"`t"+$b+"`t"+$rs)
  }
}
[System.IO.File]::WriteAllLines($out, $rows, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("→ "+$out+" ("+($rows.Count-1)+"件 ≤2語根)")
