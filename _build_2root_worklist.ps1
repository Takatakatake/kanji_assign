# 2語根字(count=2)の drakon型統合候補 work-list 生成(2026-06-27)。
#   対象 = 注入で「単一基底字を distinct 2語根が共有」する字。単一字・両rootがbasicでない(=核心語彙の確定ペアは除外)。
#   判定材料 = 2語根それぞれの語釈+band。エージェントが「健全な小系列(keep)」か「より大きな確立系列へ寄せられる(fold)」かを判定。
$ErrorActionPreference='Continue'
$dir='d:\GoogleDrive202510\マイドライブ\20_エスペラント・語学\漢字化・語彙資料\エスペラント語根＿漢字割り当て＿20260621'
$inj=Join-Path $dir '漢字注入_学術版_20260620.txt'
$srcDict=Join-Path $dir '20_PEJVO語彙リスト_原本・生成版_2024-2026\世界语全部单词_大约44100个(原pejvo.txt)_学術版_utf8_20260416.txt'
$L1=[char]0x27E6; $R1=[char]0x27E7

$bandm=@{}
foreach($row in (Import-Csv (Join-Path $dir '_p_work.csv') -Encoding UTF8)){ $bandm[$row.root]=$row.band }

$gloss=@{}
foreach($line in (Get-Content -LiteralPath $srcDict -Encoding UTF8)){
  $ci=$line.IndexOf(':'); if($ci -lt 1){ continue }
  $head=$line.Substring(0,$ci); $g=$line.Substring($ci+1)
  $tok=($head -split ' ')[0]; $seg=@($tok -split '/')
  if($seg.Count -eq 2 -and ($seg[1] -in @('o','i','a','e','oj','as','is'))){ if(-not $gloss.ContainsKey($seg[0])){ $gloss[$seg[0]]=$g } }
}

$endings=@{}; foreach($e in @('o','a','e','i','u','j','n','oj','aj','ej','on','an','en','ojn','ajn','as','is','os','us','int','ant','ont','it','at','ot','um','ig','igx','ad','ek','er','estr')){ $endings[$e]=$true }
$capRe=[regex]('^[A-Z'+[char]0x108+[char]0x11C+[char]0x124+[char]0x134+[char]0x15C+[char]0x16C+']')
function BaseKanji([string]$s){ $sb=New-Object System.Text.StringBuilder; foreach($ch in $s.ToCharArray()){ $code=[int][char]$ch; if($code -ge 0x4E00 -and $code -le 0x9FFF){ [void]$sb.Append($ch) } }; return $sb.ToString() }

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

$rows=@("char`troot1`tband1`tgloss1`troot2`tband2`tgloss2"); $n=0; $skipBasic=0
foreach($b in ($byKanji.Keys | Sort-Object)){
  if($b.Length -ne 1){ continue }
  $roots=@($byKanji[$b]); if($roots.Count -ne 2){ continue }
  $r1=$roots[0]; $r2=$roots[1]; $b1=$bandm[$r1]; $b2=$bandm[$r2]
  if($b1 -eq 'basic' -and $b2 -eq 'basic'){ $skipBasic++; continue }   # 両basic=核心確定ペア除外
  $g1=$gloss[$r1]; if(-not $g1){$g1='(語釈なし)'}; if($g1.Length -gt 90){$g1=$g1.Substring(0,90)}
  $g2=$gloss[$r2]; if(-not $g2){$g2='(語釈なし)'}; if($g2.Length -gt 90){$g2=$g2.Substring(0,90)}
  $rows += ($b+"`t"+$r1+"`t"+$b1+"`t"+$g1+"`t"+$r2+"`t"+$b2+"`t"+$g2); $n++
}
[System.IO.File]::WriteAllLines((Join-Path $dir '_2root_list.tsv'), $rows, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ("2語根字(単一字・非両basic) = "+$n+" 件 → _2root_list.tsv  (両basic除外 "+$skipBasic+"件)")
