# drakon型統合候補の work-list 生成(2026-06-27 第N巡)。
#   orphan = 注入で count=1(単一語根のみ)・単一基底字・root の band が basic/correl 以外・非固有名・語釈付き。
#   hub    = count>=3 の確立系列(char -> member roots)。orphan が意味的にどれかの hub の同義語かをエージェントが判定する材料。
# 学術版(morpheme境界が綺麗)を基準に集計。
$ErrorActionPreference='Continue'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$inj=Join-Path $dir '漢字注入_学術版_20260620.txt'
$srcDict=Join-Path $dir '20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt'
$L1=[char]0x27E6; $R1=[char]0x27E7

# --- band map (root -> band) ---
$band=@{}
foreach($row in (Import-Csv (Join-Path $dir '_p_work.csv') -Encoding UTF8)){ $band[$row.root]=$row.band }

# --- gloss map (root -> 代表語釈) : 単独lexeme R/o R/i R/a R/e を優先、無ければ任意の行 ---
$gloss=@{}
$srcLines=Get-Content -LiteralPath $srcDict -Encoding UTF8
foreach($line in $srcLines){
  $ci=$line.IndexOf(':'); if($ci -lt 1){ continue }
  $head=$line.Substring(0,$ci); $g=$line.Substring($ci+1)
  $tok=($head -split ' ')[0]; $seg=@($tok -split '/')
  if($seg.Count -eq 2 -and ($seg[1] -in @('o','i','a','e','oj','as','is'))){
    if(-not $gloss.ContainsKey($seg[0])){ $gloss[$seg[0]]=$g }
  }
}

$endings=@{}; foreach($e in @('o','a','e','i','u','j','n','oj','aj','ej','on','an','en','ojn','ajn','as','is','os','us','int','ant','ont','it','at','ot','um','ig','igx','ad','ek','er','estr')){ $endings[$e]=$true }
$capRe=[regex]('^[A-Z'+[char]0x108+[char]0x11C+[char]0x124+[char]0x134+[char]0x15C+[char]0x16C+']')
function BaseKanji([string]$s){ $sb=New-Object System.Text.StringBuilder; foreach($ch in $s.ToCharArray()){ $code=[int][char]$ch; if($code -ge 0x4E00 -and $code -le 0x9FFF){ [void]$sb.Append($ch) } }; return $sb.ToString() }

# --- pair census ---
$pairs=@{}
foreach($line in (Get-Content -LiteralPath $inj -Encoding UTF8)){
  $ci=$line.IndexOf($L1); if($ci -lt 0){ continue }
  $cj=$line.IndexOf($R1,$ci); if($cj -lt 0){ continue }
  $head=$line.Substring(0,$ci); $kanjiPart=$line.Substring($ci+1,$cj-$ci-1)
  if($capRe.IsMatch($head)){ continue }
  $hs=@($head -split '[/-]'); $ks=@($kanjiPart -split '[/-]')
  if($hs.Count -ne $ks.Count){ continue }
  for($i=0;$i -lt $hs.Count;$i++){
    $hseg=[string]$hs[$i]; $kseg=[string]$ks[$i]
    if($hseg -match '\s'){ continue }
    if($endings.ContainsKey($hseg)){ continue }
    $base=BaseKanji $kseg; if($base -eq ''){ continue }
    $pairs[$hseg+"`t"+$base]=$true
  }
}
$byKanji=@{}
foreach($k in $pairs.Keys){ $p=$k -split "`t",2; if(-not $byKanji.ContainsKey($p[1])){ $byKanji[$p[1]]=New-Object System.Collections.Generic.HashSet[string] }; [void]$byKanji[$p[1]].Add($p[0]) }

# --- orphans: count=1, 単一字, 非basic/correl ---
$orph=@(); $hub=@()
foreach($b in $byKanji.Keys){
  $roots=@($byKanji[$b]); $n=$roots.Count
  if($n -eq 1 -and $b.Length -eq 1){
    $r=$roots[0]; $bd=$band[$r]
    if($bd -eq 'basic' -or $bd -eq 'correl'){ continue }
    $g=$gloss[$r]; if(-not $g){ $g='(語釈なし)' }
    if($g.Length -gt 120){ $g=$g.Substring(0,120) }
    $orph += ($b+"`t"+$r+"`t"+$bd+"`t"+$g)
  } elseif($n -ge 3){
    $hub += ($b+"`t"+$n+"`t"+((@($roots)|Sort-Object) -join ','))
  }
}
$oOut=Join-Path $dir '_orphan_list.tsv'
$hOut=Join-Path $dir '_hub_list.tsv'
[System.IO.File]::WriteAllLines($oOut, (@("char`troot`tband`tgloss")+($orph|Sort-Object)), (New-Object System.Text.UTF8Encoding($false)))
[System.IO.File]::WriteAllLines($hOut, (@("char`tcount`troots")+($hub|Sort-Object { -[int](($_ -split "`t")[1]) })), (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("orphan(count=1・単一字・非basic) = "+$orph.Count+" 件 → _orphan_list.tsv")
Write-Host ("hub(count>=3 確立系列) = "+$hub.Count+" 件 → _hub_list.tsv")
